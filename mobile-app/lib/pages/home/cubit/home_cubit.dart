import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/model/cooking_style.dart';
import 'package:mitabl_user/model/near_by_restaurants_response.dart';
import 'package:mitabl_user/model/recommended_rest_response.dart';
import 'package:mitabl_user/model/top_rated_rest_response.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/cook_repository.dart';
import 'package:mitabl_user/repos/home_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:http/http.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
      {required AuthenticationRepository authenticationRepository,
      required UserRepository userRepository})
      : assert(authenticationRepository != null),
        _authenticationRepository = authenticationRepository,
        userRepository = userRepository,
        super(const HomeState()) {
    onRecommendedRestaurants();
    onTopratedRestaurants();
    onNearByRestaurants();
  }

  final AuthenticationRepository _authenticationRepository;
  final UserRepository userRepository;

  onRoleChanged({String? role}) {
    emit(state.copyWith(selectDineTake: role));
  }

  onCookingStyleChanged({CookingStyleData? data}) {
    emit(state.copyWith(selectedCookingData: data));
  }

  onDistanceChanged({double? distance}) {
    emit(state.copyWith(selectedDistance: distance));
  }

  void onCookingStyle() async {
    try {
      if (state.cookingStyleList!.length > 0) {
        emit(state.copyWith(
            statusCooking: FormzStatus.submissionSuccess,
            cookingStyleList: state.cookingStyleList));
      } else {
        emit(state.copyWith(statusCooking: FormzStatus.submissionInProgress));

        var response =
            await new CookRepository(userRepository).getCookingStyle();

        if (response.statusCode == 200) {
          CookingStyle cookingStyle =
              CookingStyle.fromJson(jsonDecode(response.body));
          emit(state.copyWith(
              statusCooking: FormzStatus.submissionSuccess,
              cookingStyleList: cookingStyle.data));
        } else {
          Helper.showToast('Something went wrong...');
          emit(state.copyWith(statusCooking: FormzStatus.submissionFailure));
        }
      }
    } on Exception catch (e) {
      emit(state.copyWith(statusCooking: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  void onRecommendedRestaurants() async {
    try {
      emit(state.copyWith(statusRecommRes: FormzStatus.submissionInProgress));
      Map<String, dynamic> map = {};
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

      print('mapppssRecommended ${map.toString()}');
      Response response = await new HomeRepository()
          .recommendedRestaurants(data: map, userModel: userRepository.user);
      if (response.statusCode == 200) {
        RecommendedRestResponse recommendedRestResponse =
            new RecommendedRestResponse.fromJson(jsonDecode(response.body));

        emit(state.copyWith(
            statusRecommRes: FormzStatus.submissionSuccess,
            recommendedRestResponse: recommendedRestResponse));
      } else {
        Helper.showToast('Something went wrong...');
        emit(state.copyWith(statusRecommRes: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      emit(state.copyWith(statusRecommRes: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  void onTopratedRestaurants() async {
    try {
      emit(state.copyWith(statusTopRes: FormzStatus.submissionInProgress));
      UserModel? userModel = await userRepository.getUser();

      print(userModel!.data!.accessToken);

      Map<String, dynamic> map = {};
      map['lat'] = '30.6754';
      map['lon'] = '76.7405';
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
      map['max_distance'] = state.selectedDistance!.toInt().toString();
      print('mapppssTop ${map.toString()}');

      Response response = await new HomeRepository()
          .topRatedRestaurants(data: map, userModel: userModel);
      if (response.statusCode == 200) {
        TopReatedRestResponse topReatedRestResponse =
            new TopReatedRestResponse.fromJson(jsonDecode(response.body));

        emit(state.copyWith(
            statusTopRes: FormzStatus.submissionSuccess,
            topReatedRestResponse: topReatedRestResponse));
      } else {
        Helper.showToast('Something went wrong...');
        emit(state.copyWith(statusTopRes: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      emit(state.copyWith(statusTopRes: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  void onNearByRestaurants() async {
    try {
      emit(state.copyWith(statusApi: FormzStatus.submissionInProgress));
      UserModel? userModel = await userRepository.getUser();

      print('BarerToken ${userModel!.data!.accessToken}');

      Map<String, dynamic> map = {};
      map['lat'] = '30.6754';
      map['lon'] = '76.7405';
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
      map['max_distance'] = state.selectedDistance!.toInt().toString();
      // map['cooking_styles'] = '1,2,3';
      print('mapppss ${map.toString()}');

      Response response = await new HomeRepository()
          .nearByRestaurants(data: map, userModel: userModel);
      if (response.statusCode == 200) {
        NearByRestaurantsResponse nearByResp =
            new NearByRestaurantsResponse.fromJson(jsonDecode(response.body));

        emit(state.copyWith(
            statusApi: FormzStatus.submissionSuccess,
            nearByRestaurants: nearByResp));
        // navigatorKey.currentState!.popAndPushNamed(
        //   '/HomePage',
        // );
      } else {
        jsonDecode(response.body);
        Helper.showToast('Something went wrong...');
        emit(state.copyWith(statusApi: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      emit(state.copyWith(statusApi: FormzStatus.submissionFailure));
      Helper.showToast('Something went wrong...');
    }
  }

  void onApplyFilter() async {
    try {
      onRecommendedRestaurants();
      onNearByRestaurants();
      onTopratedRestaurants();
    } catch (e) {
      print('exceptionLogin $e');
    }
  }
}
