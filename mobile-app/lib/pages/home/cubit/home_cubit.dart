import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/model/cooking_style.dart';
import 'package:mitabl_user/model/near_by_restaurants_response.dart';
import 'package:mitabl_user/model/recommended_rest_response.dart';
import 'package:mitabl_user/model/top_rated_rest_response.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/cook_repository.dart';
import 'package:mitabl_user/repos/home_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required UserRepository repo,
    HomeRepository? homeRepository,
    CookRepository? cookRepository,
  })  : userRepository = repo,
        _homeRepository = homeRepository ??
            HomeRepository(httpClient: repo.httpClient),
        _cookRepository = cookRepository ??
            CookRepository(
              repo,
              httpClient: repo.httpClient,
            ),
        _ownsHomeRepository = homeRepository == null,
        _ownsCookRepository = cookRepository == null,
        super(const HomeState()) {
    _fetchHomeFeeds();
  }

  static const _cacheRecommendedPrefix = 'home_feed_recommended_v1';
  static const _cacheTopRatedPrefix = 'home_feed_top_rated_v1';
  static const _cacheNearByPrefix = 'home_feed_nearby_v1';
  static const _cacheTimestampSuffix = '_ts';
  static const _cacheTtl = Duration(minutes: 10);

  final UserRepository userRepository;
  final HomeRepository _homeRepository;
  final CookRepository _cookRepository;
  final bool _ownsHomeRepository;
  final bool _ownsCookRepository;
  Timer? _filterDebounce;
  int _requestToken = 0;
  int _locationLabelRequestToken = 0;
  UserModel? _cachedUserModel;

  Future<void> _fetchHomeFeeds() async {
    _cachedUserModel = await _resolveUserModel();
    final userId = _cachedUserModel?.data?.user?.id;
    await _hydrateCachedFeeds(userId: userId);

    final coordinates = await _resolveCoordinates();
    final latitude = coordinates?.latitude;
    final longitude = coordinates?.longitude;
    final locationQuery = _formatLocationQuery(latitude, longitude);

    emit(state.copyWith(
      latitude: latitude,
      longitude: longitude,
      locationQuery: locationQuery,
    ));

    if (latitude != null && longitude != null) {
      _hydrateLocationLabel(latitude, longitude);
    }

    await Future.wait<void>([
      onRecommendedRestaurants(),
      onNearByRestaurants(),
      onTopratedRestaurants(),
    ]);
  }

  Future<UserModel?> _resolveUserModel() async {
    _cachedUserModel ??= userRepository.currentUser ?? await userRepository.getUser();
    return _cachedUserModel;
  }

  String _cacheKey(String prefix, int? userId) {
    if (userId == null) {
      return '${prefix}_guest';
    }
    return '${prefix}_$userId';
  }

  Future<void> _hydrateCachedFeeds({required int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    var nextState = state;
    var hasChanges = false;

    final recommendedKey = _cacheKey(_cacheRecommendedPrefix, userId);
    final recommendedJson = _readFreshCache(prefs, recommendedKey);
    if (recommendedJson != null && recommendedJson.isNotEmpty) {
      try {
        final recommended =
            RecommendedRestResponse.fromJson(jsonDecode(recommendedJson));
        nextState = nextState.copyWith(
          statusRecommRes: FormzStatus.submissionSuccess,
          recommendedRestResponse: recommended,
        );
        hasChanges = true;
      } catch (e) {
        AppLogger.error('Unable to hydrate cached recommended feed', e);
      }
    }

    final topRatedKey = _cacheKey(_cacheTopRatedPrefix, userId);
    final topRatedJson = _readFreshCache(prefs, topRatedKey);
    if (topRatedJson != null && topRatedJson.isNotEmpty) {
      try {
        final topRated = TopReatedRestResponse.fromJson(jsonDecode(topRatedJson));
        nextState = nextState.copyWith(
          statusTopRes: FormzStatus.submissionSuccess,
          topReatedRestResponse: topRated,
        );
        hasChanges = true;
      } catch (e) {
        AppLogger.error('Unable to hydrate cached top rated feed', e);
      }
    }

    final nearByKey = _cacheKey(_cacheNearByPrefix, userId);
    final nearByJson = _readFreshCache(prefs, nearByKey);
    if (nearByJson != null && nearByJson.isNotEmpty) {
      try {
        final nearBy = NearByRestaurantsResponse.fromJson(jsonDecode(nearByJson));
        nextState = nextState.copyWith(
          statusApi: FormzStatus.submissionSuccess,
          nearByRestaurants: nearBy,
        );
        hasChanges = true;
      } catch (e) {
        AppLogger.error('Unable to hydrate cached nearby feed', e);
      }
    }

    if (hasChanges) {
      emit(nextState);
    }
  }

  Future<void> _writeCache({
    required String prefix,
    required int? userId,
    required String value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(prefix, userId);
    await prefs.setString(key, value);
    await prefs.setInt('$key$_cacheTimestampSuffix',
        DateTime.now().millisecondsSinceEpoch);
  }

  String? _readFreshCache(SharedPreferences prefs, String key) {
    final payload = prefs.getString(key);
    final timestamp = prefs.getInt('$key$_cacheTimestampSuffix');
    if (payload == null || timestamp == null) {
      return null;
    }

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > _cacheTtl.inMilliseconds) {
      prefs.remove(key);
      prefs.remove('$key$_cacheTimestampSuffix');
      return null;
    }

    return payload;
  }

  Future<Response> _performRequestWithRetry(
      Future<Response> Function() operation) async {
    try {
      final first = await operation();
      if (first.statusCode >= 500) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        return operation();
      }
      return first;
    } on Exception {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return operation();
    }
  }

  Future<void> _fetchDiscoveryFeed<T>({
    required int requestToken,
    required HomeState Function(HomeState) loadingState,
    required HomeState Function(HomeState, T data) successState,
    required HomeState Function(HomeState) failureState,
    required Future<Response> Function(UserModel? userModel) request,
    required T Function(String body) decode,
    required String cacheKey,
    required String feedName,
  }) async {
    emit(loadingState(state));

    try {
      final userModel = await _resolveUserModel();
      final response =
          await _performRequestWithRetry(() => request(userModel));

      if (requestToken != _requestToken) {
        return;
      }

      if (response.statusCode == 200) {
        final data = decode(response.body);
        emit(successState(state, data));
        await _writeCache(
          prefix: cacheKey,
          userId: userModel?.data?.user?.id,
          value: response.body,
        );
      } else {
        emit(failureState(state));
        _showApiError(statusCode: response.statusCode, feedName: feedName);
      }
    } on Exception catch (e) {
      AppLogger.error('Unable to load $feedName feed', e);
      if (requestToken != _requestToken) {
        return;
      }
      emit(failureState(state));
      _showApiError(feedName: feedName);
    }
  }

  String _messageForStatusCode(int? statusCode) {
    if (statusCode == null) {
      return 'Unable to reach server. Check your connection and retry.';
    }
    if (statusCode == 401) {
      return 'Session expired. Please login again.';
    }
    if (statusCode == 403) {
      return 'You do not have permission for this request.';
    }
    if (statusCode == 404) {
      return 'Requested resource was not found.';
    }
    if (statusCode == 408) {
      return 'Request timed out. Please retry.';
    }
    if (statusCode == 429) {
      return 'Too many requests. Please wait and retry.';
    }
    if (statusCode >= 500) {
      return 'Server error. Please try again shortly.';
    }
    return 'Request failed. Please try again.';
  }

  void _showApiError({int? statusCode, required String feedName}) {
    AppLogger.error(
      'Home feed request failed',
      {'feed': feedName, 'statusCode': statusCode},
    );
    Helper.showToast(_messageForStatusCode(statusCode));
  }

  Future<Position?> _resolveCoordinates() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } on Exception catch (e) {
      AppLogger.error('Unable to resolve device location', e);
      return null;
    }
  }

  String _formatLocationQuery(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      return '';
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  Future<void> _hydrateLocationLabel(double latitude, double longitude) async {
    final requestToken = ++_locationLabelRequestToken;
    final label = await _resolveLocationLabel(latitude, longitude);
    if (isClosed) {
      return;
    }
    if (requestToken != _locationLabelRequestToken) {
      return;
    }
    if (state.latitude != latitude || state.longitude != longitude) {
      return;
    }
    emit(state.copyWith(locationLabel: label));
  }

  Future<String> _resolveLocationLabel(double latitude, double longitude) async {
    try {
      final marks = await placemarkFromCoordinates(latitude, longitude);
      if (marks.isEmpty) {
        return _formatLocationQuery(latitude, longitude);
      }

      final mark = marks.first;
      final parts = <String>[
        if ((mark.locality ?? '').isNotEmpty) mark.locality!,
        if ((mark.administrativeArea ?? '').isNotEmpty) mark.administrativeArea!,
        if ((mark.country ?? '').isNotEmpty) mark.country!,
      ];
      if (parts.isEmpty) {
        return _formatLocationQuery(latitude, longitude);
      }

      return parts.join(', ');
    } on Exception catch (e) {
      AppLogger.error('Unable to resolve location label', e);
      return _formatLocationQuery(latitude, longitude);
    }
  }

  Map<String, dynamic> _buildFilterMap({bool withLocation = false}) {
    final map = <String, dynamic>{};

    if (withLocation && state.latitude != null && state.longitude != null) {
      map['lat'] = state.latitude!.toString();
      map['lon'] = state.longitude!.toString();
      map['max_distance'] = state.selectedDistance!.toInt().toString();
    }

    if (state.selectedCookingData != null) {
      map['cooking_styles'] = state.selectedCookingData!.id.toString();
    }

    if (state.selectDineTake!.isNotEmpty) {
      if (state.selectDineTake == AppConstants.DINE_IN) {
        map['dine_in'] = '1';
      } else {
        map['take_away'] = '1';
      }
    }

    return map;
  }

  void onRoleChanged({String? role}) {
    emit(state.copyWith(selectDineTake: role));
  }

  void onCookingStyleChanged({CookingStyleData? data}) {
    emit(state.copyWith(selectedCookingData: data));
  }

  void onDistanceChanged({double? distance}) {
    emit(state.copyWith(selectedDistance: distance));
  }

  void onLocationQueryChanged(String value) {
    emit(state.copyWith(locationQuery: value));
  }

  void onLocationSubmitted() {
    final value = state.locationQuery?.trim() ?? '';
    final coordinates = value.split(',');
    if (coordinates.length != 2) {
      Helper.showToast('Use "latitude, longitude" to update location.');
      return;
    }

    final latitude = double.tryParse(coordinates.first.trim());
    final longitude = double.tryParse(coordinates.last.trim());

    if (latitude == null || longitude == null) {
      Helper.showToast('Invalid location format.');
      return;
    }

    final isLatitudeValid = latitude >= -90 && latitude <= 90;
    final isLongitudeValid = longitude >= -180 && longitude <= 180;
    if (!isLatitudeValid || !isLongitudeValid) {
      Helper.showToast('Coordinates are out of range.');
      return;
    }

    emit(state.copyWith(
      latitude: latitude,
      longitude: longitude,
      locationQuery: _formatLocationQuery(latitude, longitude),
    ));
    _hydrateLocationLabel(latitude, longitude);
    onApplyFilter();
  }

  Future<void> onUseCurrentLocation() async {
    if (state.isResolvingLocation) {
      return;
    }

    emit(state.copyWith(isResolvingLocation: true));
    try {
      final coordinates = await _resolveCoordinates();

      if (coordinates == null) {
        Helper.showToast('Unable to access current location. Check permissions.');
        return;
      }

      final latitude = coordinates.latitude;
      final longitude = coordinates.longitude;
      final locationRequestToken = ++_locationLabelRequestToken;
      final label = await _resolveLocationLabel(latitude, longitude);
      if (isClosed) {
        return;
      }
      if (locationRequestToken != _locationLabelRequestToken) {
        return;
      }

      emit(state.copyWith(
        latitude: latitude,
        longitude: longitude,
        locationQuery: _formatLocationQuery(latitude, longitude),
        locationLabel: label,
      ));

      onApplyFilter();
    } finally {
      if (!isClosed && state.isResolvingLocation) {
        emit(state.copyWith(isResolvingLocation: false));
      }
    }
  }

  Future<void> onCookingStyle() async {
    try {
      if (state.cookingStyleList!.isNotEmpty) {
        emit(state.copyWith(
            statusCooking: FormzStatus.submissionSuccess,
            cookingStyleList: state.cookingStyleList));
      } else {
        emit(state.copyWith(statusCooking: FormzStatus.submissionInProgress));

        final response = await _cookRepository.getCookingStyle();

        if (response.statusCode == 200) {
          final cookingStyle = CookingStyle.fromJson(jsonDecode(response.body));
          emit(state.copyWith(
              statusCooking: FormzStatus.submissionSuccess,
              cookingStyleList: cookingStyle.data));
        } else {
          _showApiError(
            statusCode: response.statusCode,
            feedName: 'cooking styles',
          );
          emit(state.copyWith(statusCooking: FormzStatus.submissionFailure));
        }
      }
    } on Exception catch (e) {
      AppLogger.error('Unable to load cooking styles', e);
      emit(state.copyWith(statusCooking: FormzStatus.submissionFailure));
      _showApiError(feedName: 'cooking styles');
    }
  }

  Future<void> onRecommendedRestaurants() async {
    final requestToken = _requestToken;
    await _fetchDiscoveryFeed<RecommendedRestResponse>(
      requestToken: requestToken,
      loadingState: (current) =>
          current.copyWith(statusRecommRes: FormzStatus.submissionInProgress),
      successState: (current, data) => current.copyWith(
        statusRecommRes: FormzStatus.submissionSuccess,
        recommendedRestResponse: data,
      ),
      failureState: (current) =>
          current.copyWith(statusRecommRes: FormzStatus.submissionFailure),
      request: (userModel) => _homeRepository.recommendedRestaurants(
        data: _buildFilterMap(),
        userModel: userModel,
      ),
      decode: (body) => RecommendedRestResponse.fromJson(jsonDecode(body)),
      cacheKey: _cacheRecommendedPrefix,
      feedName: 'recommended restaurants',
    );
  }

  Future<void> onTopratedRestaurants() async {
    final requestToken = _requestToken;
    await _fetchDiscoveryFeed<TopReatedRestResponse>(
      requestToken: requestToken,
      loadingState: (current) =>
          current.copyWith(statusTopRes: FormzStatus.submissionInProgress),
      successState: (current, data) => current.copyWith(
        statusTopRes: FormzStatus.submissionSuccess,
        topReatedRestResponse: data,
      ),
      failureState: (current) =>
          current.copyWith(statusTopRes: FormzStatus.submissionFailure),
      request: (userModel) => _homeRepository.topRatedRestaurants(
        data: _buildFilterMap(withLocation: true),
        userModel: userModel,
      ),
      decode: (body) => TopReatedRestResponse.fromJson(jsonDecode(body)),
      cacheKey: _cacheTopRatedPrefix,
      feedName: 'top rated restaurants',
    );
  }

  Future<void> onNearByRestaurants() async {
    final requestToken = _requestToken;
    await _fetchDiscoveryFeed<NearByRestaurantsResponse>(
      requestToken: requestToken,
      loadingState: (current) =>
          current.copyWith(statusApi: FormzStatus.submissionInProgress),
      successState: (current, data) => current.copyWith(
        statusApi: FormzStatus.submissionSuccess,
        nearByRestaurants: data,
      ),
      failureState: (current) =>
          current.copyWith(statusApi: FormzStatus.submissionFailure),
      request: (userModel) => _homeRepository.nearByRestaurants(
        data: _buildFilterMap(withLocation: true),
        userModel: userModel,
      ),
      decode: (body) => NearByRestaurantsResponse.fromJson(jsonDecode(body)),
      cacheKey: _cacheNearByPrefix,
      feedName: 'nearby restaurants',
    );
  }

  void onApplyFilter() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 300), () {
      _requestToken++;
      onRecommendedRestaurants();
      onNearByRestaurants();
      onTopratedRestaurants();
    });
  }

  @override
  Future<void> close() {
    _filterDebounce?.cancel();
    if (_ownsHomeRepository) {
      _homeRepository.dispose();
    }
    if (_ownsCookRepository) {
      _cookRepository.dispose();
    }
    return super.close();
  }
}
