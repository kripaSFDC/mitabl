import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:mitabl_user/model/cooking_style.dart';
import 'package:mitabl_user/model/food_menu.dart';
import 'package:mitabl_user/model/name.dart';
import 'package:mitabl_user/model/special_diet.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/cook_repository.dart';

import '../../../helper/helper.dart';

part 'add_menu_state.dart';

class AddMenuCubit extends Cubit<AddMenuState> {
  AddMenuCubit(this.cookRepository)
    : super(AddMenuState(selectedCookingStyle: CookingStyleData(name: '')));

  final CookRepository cookRepository;

  setUnChangedFood({FoodData? foodData}) {
    emit(state.copyWith(selectedFoodMenuUnChanged: foodData));
  }

  setFields({FoodData? foodData}) {
    List<Pictures> picturesList = [];
    for (var element in foodData!.pictures!) {
      picturesList.add(element);
    }

    final availableSpecialDiets = _cloneSpecialDietList(
      state.specialDietDataListOriginal,
    );

    emit(
      state.copyWith(
        pathFiles: picturesList,
        selectedFoodMenu: foodData,
        specialDietDataList: availableSpecialDiets,
        availableDate: foodData.availableDate,
        availableDays: foodData.availableDays ?? const [],
        availableFromTime: foodData.availableFromTime,
        availableToTime: foodData.availableToTime,
      ),
    );

    CookingStyleData cookingStyleData = state.cookingStyleList.firstWhere(
      (element) => element.id == foodData.cookingstyle,
    );
    List<CookingStyleData> cookingStyleListTemp = [];
    if (state.cookingStyleList.isNotEmpty) {
      for (var element in state.cookingStyleList) {
        if (element.id == foodData.cookingstyle) {
          cookingStyleListTemp.add(element.copyWith(isSelected: true));
        } else {
          cookingStyleListTemp.add(element);
        }
      }
    }
    emit(
      state.copyWith(
        selectedCookingStyle: cookingStyleData.copyWith(isSelected: true),
        cookingStyleList: cookingStyleListTemp,
      ),
    );

    final idsDiet = _extractSpecialDietIds(foodData.specialDiet);

    for (var element in idsDiet) {
      final parsed = int.tryParse(element.toString());
      if (parsed != null) {
        onSpecialDietChange(id: parsed, value: true);
      }
    }
  }

  getFoodMenu() async {
    try {
      emit(state.copyWith(foodMenuStatus: FormzStatus.submissionInProgress));

      var response = await cookRepository.getFoodMenu();

      if (response.statusCode == 200) {
        FoodMenu foodMenu = FoodMenu.fromJson(jsonDecode(response.body));

        emit(
          state.copyWith(
            foodMenu: foodMenu,
            foodMenuStatus: FormzStatus.submissionSuccess,
          ),
        );
      } else {
        emit(state.copyWith(foodMenuStatus: FormzStatus.submissionFailure));
        Helper.showToast('Unable to load menu items.');
      }
    } catch (e) {
      AppLogger.error('Unable to load menu items', e);
      emit(state.copyWith(foodMenuStatus: FormzStatus.submissionFailure));
      Helper.showToast('Unable to load menu items.');
    }
  }

  onAddFood({bool? isEdit, String? foodId}) async {
    try {
      emit(state.copyWith(addFoodStatus: FormzStatus.submissionInProgress));

      List<String> diets = [];
      String deleteImageString = '';
      state.specialDietDataList!
          .where((element) => element.isSelected!)
          .toList()
          .forEach((element) {
            diets.add(element.id.toString());
          });

      for (var element in state.deleteImagesId) {
        if (deleteImageString == '') {
          deleteImageString = element;
        } else {
          deleteImageString = '$deleteImageString,$element';
        }
      }

      Map<String, dynamic> map = {};
      final currentUser =
          cookRepository.userRepository!.currentUser ??
          await cookRepository.userRepository!.getUser();
      if (isEdit == true) {
        map['food_id'] = foodId;
      } else {
        map['restaurant_id'] = currentUser!.data!.user!.id;
      }
      map['food_name'] = state.itemName!.value;
      map['price'] = state.price!.value;
      map['cookingstyle'] = state.selectedCookingStyle!.id;
      map['description'] = state.description!.value;
      map['specialDietIds'] = diets;
      map['delete_images'] = deleteImageString.toString();
      map['available_date'] = state.availableDate;
      map['available_days'] = state.availableDays;
      map['available_from_time'] = state.availableFromTime;
      map['available_to_time'] = state.availableToTime;

      var paths = state.pathFiles
          .where((element) => element.id == null)
          .toList();
      List<String> localPaths = [];
      for (var element in paths) {
        localPaths.add(element.path!);
      }

      var response = await cookRepository.saveMenuItem(
        data: map,
        filePaths: localPaths,
        isEdit: isEdit,
        deleteImagsId: state.deleteImagesId,
      );
      if (response.statusCode == 200) {
        if (isEdit == true) {
          // Helper.showToast('Food updated successfully.');
        } else {
          // Helper.showToast('Food added successfully.');
        }
        resetFields();
        getFoodMenu();
        emit(state.copyWith(addFoodStatus: FormzStatus.submissionSuccess));
        navigatorKey.currentState!.pop(true);
      } else {
        emit(state.copyWith(addFoodStatus: FormzStatus.submissionFailure));
        getFoodMenu();
        String message = 'Something went wrong...';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            message =
                decoded['isError']?.toString() ??
                decoded['message']?.toString() ??
                message;
          }
        } catch (_) {}
        Helper.showToast(message);
      }
    } on Exception {
      emit(state.copyWith(addFoodStatus: FormzStatus.submissionFailure));
    }
  }

  resetFields() {
    getCookingStyle();
    emit(
      AddMenuState(
        deleteImagesId: const [],
        cookingStyleList: _cloneCookingStyleList(state.cookingStyleList),
        specialDietDataListOriginal: _cloneSpecialDietList(
          state.specialDietDataListOriginal,
        ),
        foodMenu: state.foodMenu,
        specialDietDataList: _cloneSpecialDietList(
          state.specialDietDataListOriginal,
        ),
        availableDate: null,
        availableDays: const [],
        availableFromTime: null,
        availableToTime: null,
        selectedCookingStyle: CookingStyleData(name: ''),
        selectedFoodMenu: state.selectedFoodMenu,
      ),
    );
  }

  onItemNameChange({String? value}) {
    var name = Name.dirty(value!);
    emit(
      state.copyWith(
        itemName: name,
        formsStatus: Formz.validate([name, state.description!, state.price!]),
      ),
    );
  }

  onPriceChange({String? value}) {
    var price = Name.dirty(value!);
    emit(
      state.copyWith(
        price: price,
        formsStatus: Formz.validate([
          price,
          state.description!,
          state.itemName!,
        ]),
      ),
    );
  }

  onDescriptionChange({String? value}) {
    var description = Name.dirty(value!);
    emit(
      state.copyWith(
        description: description,
        formsStatus: Formz.validate([
          description,
          state.price!,
          state.itemName!,
        ]),
      ),
    );
  }

  onCookingStyleChange({int? index, bool? value}) {
    List<CookingStyleData> tempList = [];
    List<CookingStyleData> tempListNew = [];
    tempList.addAll(state.cookingStyleList);

    CookingStyleData specialDietData = tempList[index!].copyWith(
      isSelected: true,
    );

    if (value!) {
      tempList.removeAt(index);
      for (var element in tempList) {
        if (element.isSelected == true) {
          tempListNew.add(element.copyWith(isSelected: false));
        } else {
          tempListNew.add(element);
        }
      }

      tempListNew.insert(index, specialDietData);

      emit(
        state.copyWith(
          cookingStyleList: tempListNew,
          selectedCookingStyle: specialDietData,
        ),
      );
    }
  }

  onDeleteSpecialDiet({int? id}) {
    List<SpecialDietData> tempList = [];
    tempList.addAll(state.specialDietDataList!);

    int index = tempList.indexWhere((element) => element.id == id);
    SpecialDietData specialDietData = tempList[index].copyWith(
      isSelected: false,
    );

    tempList.removeAt(index);
    tempList.insert(index, specialDietData);

    emit(state.copyWith(specialDietDataList: tempList));
  }

  onSpecialDietChange({int? id, bool? value}) {
    List<SpecialDietData> tempList = [];
    tempList.addAll(state.specialDietDataList!);
    var index = tempList.indexWhere((element) => element.id == id);
    SpecialDietData specialDietData = tempList[index].copyWith(
      isSelected: value,
    );

    tempList.removeAt(index);
    tempList.insert(index, specialDietData);

    emit(state.copyWith(specialDietDataList: tempList));
  }

  getCookingStyle() async {
    try {
      var response = await cookRepository.getCookingStyle();
      CookingStyle cookingStyle = CookingStyle.fromJson(
        jsonDecode(response.body),
      );

      if (cookingStyle.status == 200) {
        emit(
          state.copyWith(
            cookingStyleList: _cloneCookingStyleList(cookingStyle.data ?? []),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Unable to load cooking styles', e);
      Helper.showToast('Unable to load cooking styles.');
    }
  }

  getSpecialDiet() async {
    try {
      var response = await cookRepository.getSpecialDiets();
      SpecialDiet specialDiet = SpecialDiet.fromJson(jsonDecode(response.body));

      if (specialDiet.status == 200) {
        final specialDiets = _cloneSpecialDietList(
          specialDiet.data ?? const [],
        );
        emit(
          state.copyWith(
            specialDietDataList: specialDiets,
            specialDietDataListOriginal: _cloneSpecialDietList(specialDiets),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Unable to load special diets', e);
      Helper.showToast('Unable to load special diets.');
    }
  }

  onDeleteImage({String? path, Pictures? pictures}) async {
    if (pictures!.id == null) {
      List<Pictures> allPaths = [];
      if (state.pathFiles.isNotEmpty) {
        allPaths.addAll(state.pathFiles);
        allPaths.removeWhere(
          (element) => element.path.toString() == path.toString(),
        );
      } else {
        allPaths.removeWhere(
          (element) => element.path.toString() == path.toString(),
        );
      }

      emit(state.copyWith(pathFiles: allPaths));
    } else {
      // var response = await cookRepository!.userRepository!
      //     .deleteImage(id: pictures.id.toString(), type: 'food');
      // if (response.statusCode == 200) {
      List<Pictures> allPaths = [...state.pathFiles];
      List<String> deletedImageIds = [...state.deleteImagesId];
      final removedPicture = allPaths.cast<Pictures?>().firstWhere(
        (element) => element?.path.toString() == path.toString(),
        orElse: () => null,
      );

      if (removedPicture == null) {
        return;
      }

      if (removedPicture.id != null) {
        deletedImageIds.add(removedPicture.id.toString());
      }

      allPaths.removeWhere(
        (element) => element.path.toString() == path.toString(),
      );

      emit(
        state.copyWith(pathFiles: allPaths, deleteImagesId: deletedImageIds),
      );
      getFoodMenu();
    }
  }

  onImageScroll({int? index}) {
    emit(state.copyWith(selectedPage: index));
  }

  void onAvailableDateChanged({String? value}) {
    emit(
      state.copyWith(
        availableDate: value,
        availableDays: (value != null && value.isNotEmpty)
            ? const []
            : state.availableDays,
      ),
    );
  }

  void onAvailableDayToggled({required int day}) {
    final nextDays = [...state.availableDays];
    if (nextDays.contains(day)) {
      nextDays.remove(day);
    } else {
      nextDays.add(day);
      nextDays.sort();
    }

    emit(
      state.copyWith(
        availableDate: nextDays.isNotEmpty ? '' : state.availableDate,
        availableDays: nextDays,
      ),
    );
  }

  void onAvailableTimeChanged({
    String? availableFromTime,
    String? availableToTime,
  }) {
    emit(
      state.copyWith(
        availableFromTime: availableFromTime ?? state.availableFromTime,
        availableToTime: availableToTime ?? state.availableToTime,
      ),
    );
  }

  onNewImageAdded({String? path}) {
    Pictures pictures = Pictures(path: path);
    List<Pictures> allPaths = [];
    if (state.pathFiles.isNotEmpty) {
      allPaths.addAll(state.pathFiles);
      allPaths.add(pictures);
    } else {
      allPaths.add(pictures);
    }

    emit(state.copyWith(pathFiles: allPaths));
  }

  //StatusChange
  onFoodStatusChange({bool? value, String? foodId}) async {
    emit(
      state.copyWith(foodStatusFormStatus: FormzStatus.submissionInProgress),
    );
    var response = await cookRepository.changFoodStatus(foodId: foodId);

    if (response.statusCode == 200) {
      FoodData foodData = state.selectedFoodMenu!.copyWith(
        status: state.selectedFoodMenu!.status == 1 ? 0 : 1,
      );
      getFoodMenu();
      emit(
        state.copyWith(
          selectedFoodMenu: foodData,
          selectedFoodMenuUnChanged: foodData,
          foodStatusFormStatus: FormzStatus.submissionSuccess,
        ),
      );
    } else {
      getFoodMenu();
      emit(state.copyWith(foodStatusFormStatus: FormzStatus.submissionFailure));
    }
  }

  @override
  Future<void> close() {
    cookRepository.dispose();
    return super.close();
  }

  List<String> _extractSpecialDietIds(String? specialDietRaw) {
    if (specialDietRaw == null || specialDietRaw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = json.decode(specialDietRaw);
      if (decoded is List) {
        if (decoded.length == 1 && decoded.first is String) {
          return decoded.first
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList();
        }
        return decoded
            .map((value) => value.toString())
            .where((value) => value.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    return [];
  }

  List<CookingStyleData> _cloneCookingStyleList(
    List<CookingStyleData> cookingStyles,
  ) {
    return cookingStyles
        .map((style) => style.copyWith())
        .toList(growable: false);
  }

  List<SpecialDietData> _cloneSpecialDietList(
    List<SpecialDietData>? specialDiets,
  ) {
    if (specialDiets == null) {
      return const [];
    }

    return specialDiets.map((diet) => diet.copyWith()).toList(growable: false);
  }
}
