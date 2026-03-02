import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
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

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
      {required UserRepository userRepository,
      HomeRepository? homeRepository,
      CookRepository? cookRepository})
      : userRepository = userRepository,
        _homeRepository = homeRepository ?? HomeRepository(),
        _cookRepository = cookRepository ?? CookRepository(userRepository),
        _ownsHomeRepository = homeRepository == null,
        _ownsCookRepository = cookRepository == null,
        super(const HomeState()) {
    _fetchHomeFeeds();
  }

  static const double _fallbackLat = 30.6754;
  static const double _fallbackLon = 76.7405;

  final UserRepository userRepository;
  final HomeRepository _homeRepository;
  final CookRepository _cookRepository;
  final bool _ownsHomeRepository;
  final bool _ownsCookRepository;
  Timer? _filterDebounce;
  int _requestToken = 0;

  Future<void> _fetchHomeFeeds() async {
    await userRepository.getUser();
    final coordinates = await _resolveCoordinates();
    final latitude = coordinates?.latitude ?? _fallbackLat;
    final longitude = coordinates?.longitude ?? _fallbackLon;

    emit(state.copyWith(
      latitude: latitude,
      longitude: longitude,
      locationQuery:
          '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
    ));

    await Future.wait([
      onRecommendedRestaurants(),
      onTopratedRestaurants(),
      onNearByRestaurants(),
    ]);
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

  Map<String, dynamic> _buildFilterMap({bool withLocation = false}) {
    final map = <String, dynamic>{};

    if (withLocation) {
      map['lat'] = (state.latitude ?? _fallbackLat).toString();
      map['lon'] = (state.longitude ?? _fallbackLon).toString();
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

    emit(state.copyWith(latitude: latitude, longitude: longitude));
    onApplyFilter();
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
          Helper.showToast('Something went wrong...');
          emit(state.copyWith(statusCooking: FormzStatus.submissionFailure));
        }
      }
    } on Exception catch (e) {
      AppLogger.error('Unable to load cooking styles', e);
      emit(state.copyWith(statusCooking: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  Future<void> onRecommendedRestaurants() async {
    try {
      emit(state.copyWith(statusRecommRes: FormzStatus.submissionInProgress));
      final userModel = await userRepository.getUser();
      final response = await _homeRepository.recommendedRestaurants(
          data: _buildFilterMap(), userModel: userModel);
      if (response.statusCode == 200) {
        final recommendedRestResponse =
            RecommendedRestResponse.fromJson(jsonDecode(response.body));

        emit(state.copyWith(
            statusRecommRes: FormzStatus.submissionSuccess,
            recommendedRestResponse: recommendedRestResponse));
      } else {
        Helper.showToast('Something went wrong...');
        emit(state.copyWith(statusRecommRes: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      AppLogger.error('Unable to load recommended restaurants', e);
      emit(state.copyWith(statusRecommRes: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  Future<void> onTopratedRestaurants() async {
    final requestToken = _requestToken;
    try {
      emit(state.copyWith(statusTopRes: FormzStatus.submissionInProgress));
      final UserModel? userModel = await userRepository.getUser();

      final Response response = await _homeRepository.topRatedRestaurants(
          data: _buildFilterMap(withLocation: true), userModel: userModel);
      if (requestToken != _requestToken) {
        return;
      }

      if (response.statusCode == 200) {
        final topReatedRestResponse =
            TopReatedRestResponse.fromJson(jsonDecode(response.body));

        emit(state.copyWith(
            statusTopRes: FormzStatus.submissionSuccess,
            topReatedRestResponse: topReatedRestResponse));
      } else {
        Helper.showToast('Something went wrong...');
        emit(state.copyWith(statusTopRes: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      AppLogger.error('Unable to load top rated restaurants', e);
      emit(state.copyWith(statusTopRes: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  Future<void> onNearByRestaurants() async {
    final requestToken = _requestToken;
    try {
      emit(state.copyWith(statusApi: FormzStatus.submissionInProgress));
      final UserModel? userModel = await userRepository.getUser();

      final Response response = await _homeRepository.nearByRestaurants(
          data: _buildFilterMap(withLocation: true), userModel: userModel);
      if (requestToken != _requestToken) {
        return;
      }
      if (response.statusCode == 200) {
        final nearByResp =
            NearByRestaurantsResponse.fromJson(jsonDecode(response.body));

        emit(state.copyWith(
            statusApi: FormzStatus.submissionSuccess,
            nearByRestaurants: nearByResp));
      } else {
        Helper.showToast('Something went wrong...');
        emit(state.copyWith(statusApi: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      AppLogger.error('Unable to load near by restaurants', e);
      emit(state.copyWith(statusApi: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
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
