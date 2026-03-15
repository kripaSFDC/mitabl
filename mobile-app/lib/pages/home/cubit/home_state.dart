part of 'home_cubit.dart';

class HomeState extends Equatable {
  static const _unset = Object();

  const HomeState({
    this.status = FormzStatus.pure,
    this.statusApi = FormzStatus.pure,
    this.statusTopRes = FormzStatus.pure,
    this.statusCooking = FormzStatus.pure,
    this.statusRecommRes = FormzStatus.pure,
    this.topRatedPage = 1,
    this.nearByPage = 1,
    this.hasMoreTopRated = true,
    this.hasMoreNearBy = true,
    this.isLoadingMoreTopRated = false,
    this.isLoadingMoreNearBy = false,
    this.isResolvingLocation = false,
    this.serverMessage = '',
    this.locationLabel = '',
    this.cookingStyleList = const [],
    this.selectDineTake = '',
    this.locationQuery = '',
    this.latitude,
    this.longitude,
    this.nearByRestaurants,
    this.selectedDistance = 15,
    this.recommendedRestResponse,
    this.selectedCookingData,
    this.topReatedRestResponse,
  });

  final FormzStatus? status;
  final FormzStatus? statusCooking;
  final FormzStatus? statusApi;
  final FormzStatus? statusTopRes;
  final FormzStatus? statusRecommRes;
  final int topRatedPage;
  final int nearByPage;
  final bool hasMoreTopRated;
  final bool hasMoreNearBy;
  final bool isLoadingMoreTopRated;
  final bool isLoadingMoreNearBy;
  final bool isResolvingLocation;

  final List<CookingStyleData>? cookingStyleList;
  final String? serverMessage;
  final String? locationLabel;
  final String? selectDineTake;
  final String? locationQuery;
  final double? latitude;
  final double? longitude;
  final double? selectedDistance;
  final CookingStyleData? selectedCookingData;
  final NearByRestaurantsResponse? nearByRestaurants;
  final TopReatedRestResponse? topReatedRestResponse;
  final RecommendedRestResponse? recommendedRestResponse;

  HomeState copyWith({
    FormzStatus? status,
    FormzStatus? statusApi,
    FormzStatus? statusTopRes,
    FormzStatus? statusCooking,
    FormzStatus? statusRecommRes,
    int? topRatedPage,
    int? nearByPage,
    bool? hasMoreTopRated,
    bool? hasMoreNearBy,
    bool? isLoadingMoreTopRated,
    bool? isLoadingMoreNearBy,
    bool? isResolvingLocation,
    String? serverMessage,
    Object? locationLabel = _unset,
    Object? locationQuery = _unset,
    Object? latitude = _unset,
    Object? longitude = _unset,
    double? selectedDistance,
    Object? selectedCookingData = _unset,
    List<CookingStyleData>? cookingStyleList,
    String? selectDineTake,
    Object? nearByRestaurants = _unset,
    Object? recommendedRestResponse = _unset,
    Object? topReatedRestResponse = _unset,
  }) {
    return HomeState(
      status: status ?? this.status,
      selectedCookingData: identical(selectedCookingData, _unset)
          ? this.selectedCookingData
          : selectedCookingData as CookingStyleData?,
      selectDineTake: selectDineTake ?? this.selectDineTake,
      locationQuery: identical(locationQuery, _unset)
          ? this.locationQuery
          : locationQuery as String?,
      latitude: identical(latitude, _unset)
          ? this.latitude
          : latitude as double?,
      longitude: identical(longitude, _unset)
          ? this.longitude
          : longitude as double?,
      cookingStyleList: cookingStyleList ?? this.cookingStyleList,
      statusTopRes: statusTopRes ?? this.statusTopRes,
      topRatedPage: topRatedPage ?? this.topRatedPage,
      nearByPage: nearByPage ?? this.nearByPage,
      hasMoreTopRated: hasMoreTopRated ?? this.hasMoreTopRated,
      hasMoreNearBy: hasMoreNearBy ?? this.hasMoreNearBy,
      isLoadingMoreTopRated:
          isLoadingMoreTopRated ?? this.isLoadingMoreTopRated,
      isLoadingMoreNearBy: isLoadingMoreNearBy ?? this.isLoadingMoreNearBy,
      selectedDistance: selectedDistance ?? this.selectedDistance,
      statusRecommRes: statusRecommRes ?? this.statusRecommRes,
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      statusApi: statusApi ?? this.statusApi,
      statusCooking: statusCooking ?? this.statusCooking,
      locationLabel: identical(locationLabel, _unset)
          ? this.locationLabel
          : locationLabel as String?,
      nearByRestaurants: identical(nearByRestaurants, _unset)
          ? this.nearByRestaurants
          : nearByRestaurants as NearByRestaurantsResponse?,
      recommendedRestResponse: identical(recommendedRestResponse, _unset)
          ? this.recommendedRestResponse
          : recommendedRestResponse as RecommendedRestResponse?,
      topReatedRestResponse: identical(topReatedRestResponse, _unset)
          ? this.topReatedRestResponse
          : topReatedRestResponse as TopReatedRestResponse?,
      serverMessage: serverMessage ?? this.serverMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    statusApi,
    selectDineTake,
    selectedCookingData,
    serverMessage,
    locationQuery,
    latitude,
    longitude,
    statusTopRes,
    topRatedPage,
    nearByPage,
    hasMoreTopRated,
    hasMoreNearBy,
    isLoadingMoreTopRated,
    isLoadingMoreNearBy,
    statusRecommRes,
    statusCooking,
    isResolvingLocation,
    topReatedRestResponse,
    selectedDistance,
    recommendedRestResponse,
    locationLabel,
    cookingStyleList,
    nearByRestaurants,
  ];
}
