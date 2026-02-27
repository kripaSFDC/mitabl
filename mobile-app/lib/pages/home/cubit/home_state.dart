part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState(
      {this.status = FormzStatus.pure,
      this.statusApi = FormzStatus.pure,
      this.statusTopRes = FormzStatus.pure,
      this.statusCooking = FormzStatus.pure,
      this.statusRecommRes = FormzStatus.pure,
      this.serverMessage = '',
      this.cookingStyleList = const [],
      this.selectDineTake = '',
      this.nearByRestaurants,
      this.selectedDistance = 15,
      this.recommendedRestResponse,
      this.selectedCookingData,
      this.topReatedRestResponse});

  final FormzStatus? status;
  final FormzStatus? statusCooking;
  final FormzStatus? statusApi;
  final FormzStatus? statusTopRes;
  final FormzStatus? statusRecommRes;

  final List<CookingStyleData>? cookingStyleList;
  final String? serverMessage;
  final String? selectDineTake;
  final double? selectedDistance;
  final CookingStyleData? selectedCookingData;
  final NearByRestaurantsResponse? nearByRestaurants;
  final TopReatedRestResponse? topReatedRestResponse;
  final RecommendedRestResponse? recommendedRestResponse;

  HomeState copyWith(
      {FormzStatus? status,
      FormzStatus? statusApi,
      FormzStatus? statusTopRes,
      FormzStatus? statusCooking,
      FormzStatus? statusRecommRes,
      String? serverMessage,
      double? selectedDistance,
      CookingStyleData? selectedCookingData,
      List<CookingStyleData>? cookingStyleList,
      String? selectDineTake,
      NearByRestaurantsResponse? nearByRestaurants,
      RecommendedRestResponse? recommendedRestResponse,
      TopReatedRestResponse? topReatedRestResponse}) {
    return HomeState(
        status: status ?? this.status,
        selectedCookingData: selectedCookingData ?? this.selectedCookingData,
        selectDineTake: selectDineTake ?? this.selectDineTake,
        cookingStyleList: cookingStyleList ?? this.cookingStyleList,
        statusTopRes: statusTopRes ?? this.statusTopRes,
        selectedDistance: selectedDistance ?? this.selectedDistance,
        statusRecommRes: statusRecommRes ?? this.statusRecommRes,
        statusApi: statusApi ?? this.statusApi,
        statusCooking: statusCooking ?? this.statusCooking,
        nearByRestaurants: nearByRestaurants ?? this.nearByRestaurants,
        recommendedRestResponse:
            recommendedRestResponse ?? this.recommendedRestResponse,
        topReatedRestResponse:
            topReatedRestResponse ?? this.topReatedRestResponse,
        serverMessage: serverMessage ?? this.serverMessage);
  }

  @override
  List<Object?> get props => [
        status,
        statusApi,
        selectDineTake,
        selectedCookingData,
        serverMessage,
        statusTopRes,
        statusRecommRes,
        statusCooking,
        topReatedRestResponse,
        selectedDistance,
        recommendedRestResponse,
        cookingStyleList,
        nearByRestaurants
      ];
}
