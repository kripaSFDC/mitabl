import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
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
      : super(AddMenuState(selectedCookingStyle: CookingStyleData(name: ''))) {}

  final CookRepository? cookRepository;

  setUnChangedFood({FoodData? foodData}) {
    emit(state.copyWith(selectedFoodMenuUnChanged: foodData));
  }

  setFields({FoodData? foodData}) {
    List<Pictures> picturesList = [];
    foodData!.pictures!.forEach((element) {
      picturesList.add(element);
    });

    emit(state.copyWith(
        pathFiles: picturesList,
        selectedFoodMenu: foodData,
        specialDietDataList: state.specialDietDataListOriginal));

    CookingStyleData cookingStyleData = state.cookingStyleList
        .firstWhere((element) => element.id == foodData.cookingstyle);
    List<CookingStyleData> cookingStyleListTemp = [];
    if (state.cookingStyleList.isNotEmpty) {
      state.cookingStyleList.forEach((element) {
        if (element.id == foodData.cookingstyle) {
          cookingStyleListTemp.add(element.copyWith(isSelected: true));
        } else {
          cookingStyleListTemp.add(element);
        }
      });
    }
    print('selectedStyle ${cookingStyleData.name}');
    emit(state.copyWith(
        selectedCookingStyle: cookingStyleData.copyWith(isSelected: true),
        cookingStyleList: cookingStyleListTemp));

    // List<String> idsDiet = (jsonDecode(foodData.specialDiet!) as List<dynamic>).cast<String>().toList();
    List<String> idsDiet = [];
    json
        .decode(foodData.specialDiet!)
        .toList()[0]
        .replaceAll("[", "")
        .split(',')
        .forEach((e) {
      idsDiet.add(e);
    });

    idsDiet.forEach((element) {
      print('specialDiet ${element}');
      onSpecialDietChange(id: int.parse(element.toString()), value: true);
    });
  }

  getFoodMenu() async {
    try {
      emit(state.copyWith(foodMenuStatus: FormzStatus.submissionInProgress));

      var response = await cookRepository!.getFoodMenu();

      print('foodeMenu ${response.body}');
      if (response.statusCode == 200) {
        FoodMenu foodMenu = FoodMenu.fromJson(jsonDecode(response.body));

        emit(state.copyWith(
            foodMenu: foodMenu, foodMenuStatus: FormzStatus.submissionSuccess));
      } else {
        emit(state.copyWith(foodMenuStatus: FormzStatus.submissionFailure));
      }
    } on Exception catch (e) {
      emit(state.copyWith(foodMenuStatus: FormzStatus.submissionFailure));
    }
  }

  onAddFood({bool? isEdit, String? foodId}) async {
    print('isdit ${isEdit!}');
    try {
      emit(state.copyWith(addFoodStatus: FormzStatus.submissionInProgress));

      List<String> diets = [];
      String dietString = '', deleteImageString = '';
      state.specialDietDataList!
          .where((element) => element.isSelected!)
          .toList()
          .forEach((element) {
        diets.add(element.id.toString());

        if (dietString == '') {
          dietString = element.id.toString();
        } else {
          dietString = dietString + ',' + element.id.toString();
        }
      });

      state.deleteImagesId.forEach((element) {
        if (deleteImageString == '') {
          deleteImageString = element;
        } else {
          deleteImageString = deleteImageString + ',' + element;
        }
      });

      Map<String, dynamic> map = {};
      isEdit
          ? map['food_id'] = foodId
          : map['restaurant_id'] =
              cookRepository!.userRepository!.user!.data!.user!.id;
      map['food_name'] = state.itemName!.value;
      map['price'] = state.price!.value;
      map['cookingstyle'] = state.selectedCookingStyle!.id;
      map['description'] = state.description!.value;
      map['specialDiet[]'] = dietString.toString();
      map['delete_images'] = deleteImageString.toString();

      print('data ${map.toString()}');

      var paths =
          state.pathFiles.where((element) => element.id == null).toList();
      List<String> localPaths = [];
      paths.forEach((element) {
        localPaths.add(element.path!);
      });

      var response = await cookRepository!.saveMenuItem(
          data: map,
          filePaths: localPaths,
          isEdit: isEdit,
          deleteImagsId: state.deleteImagesId);
      if (response.statusCode == 200) {
        if (isEdit) {
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
        Helper.showToast('Something went wrong...');
      }
    } on Exception catch (e) {
      print('exception ${e}');
      emit(state.copyWith(addFoodStatus: FormzStatus.submissionFailure));
    }
  }

  resetFields() {
    getCookingStyle();
    emit(AddMenuState(
        deleteImagesId: [],
        cookingStyleList: state.cookingStyleList,
        specialDietDataListOriginal: state.specialDietDataListOriginal,
        foodMenu: state.foodMenu,
        specialDietDataList: state.specialDietDataListOriginal,
        selectedCookingStyle: CookingStyleData(name: ''),
        selectedFoodMenu: state.selectedFoodMenu));
  }

  onItemNameChange({String? value}) {
    var name = Name.dirty(value!);
    emit(state.copyWith(
        itemName: name,
        formsStatus: Formz.validate([name, state.description!, state.price!])));
  }

  onPriceChange({String? value}) {
    var price = Name.dirty(value!);
    emit(state.copyWith(
        price: price,
        formsStatus:
            Formz.validate([price, state.description!, state.itemName!])));
  }

  onDescriptionChange({String? value}) {
    var description = Name.dirty(value!);
    emit(state.copyWith(
        description: description,
        formsStatus:
            Formz.validate([description, state.price!, state.itemName!])));
  }

  onCookingStyleChange({int? index, bool? value}) {
    List<CookingStyleData> tempList = [];
    List<CookingStyleData> tempListNew = [];
    tempList.addAll(state.cookingStyleList);

    CookingStyleData specialDietData =
        tempList[index!].copyWith(isSelected: true);

    if (value!) {
      tempList.removeAt(index);
      tempList.forEach((element) {
        if (element.isSelected == true) {
          tempListNew.add(element.copyWith(isSelected: false));
        } else {
          tempListNew.add(element);
        }
      });

      tempListNew.insert(index, specialDietData);

      emit(state.copyWith(
          cookingStyleList: tempListNew,
          selectedCookingStyle: specialDietData));
    }
  }

  onDeleteSpecialDiet({int? id}) {
    print('ondelete ${id}');
    List<SpecialDietData> tempList = [];
    tempList.addAll(state.specialDietDataList!);

    int index = tempList.indexWhere((element) => element.id == id);
    print('indexFound ${index}');
    SpecialDietData specialDietData =
        tempList[index].copyWith(isSelected: false);

    tempList.removeAt(index);
    tempList.insert(index, specialDietData);

    emit(state.copyWith(specialDietDataList: tempList));
  }

  onSpecialDietChange({int? id, bool? value}) {
    List<SpecialDietData> tempList = [];
    tempList.addAll(state.specialDietDataList!);
    var index = tempList.indexWhere((element) => element.id == id);
    SpecialDietData specialDietData =
        tempList[index].copyWith(isSelected: value);

    tempList.removeAt(index);
    tempList.insert(index, specialDietData);

    emit(state.copyWith(specialDietDataList: tempList));
  }

  getCookingStyle() async {
    var response = await cookRepository!.getCookingStyle();
    CookingStyle cookingStyle =
        CookingStyle.fromJson(jsonDecode(response.body));

    if (cookingStyle.status == 200) {
      emit(state.copyWith(cookingStyleList: cookingStyle.data));
    }
  }

  getSpecialDiet() async {
    var response = await cookRepository!.getSpecialDiets();
    SpecialDiet specialDiet = SpecialDiet.fromJson(jsonDecode(response.body));

    if (specialDiet.status == 200) {
      emit(state.copyWith(
          specialDietDataList: specialDiet.data,
          specialDietDataListOriginal: specialDiet.data));
    }
  }

  onDeleteImage({String? path, Pictures? pictures}) async {
    print('deleteImage ${path}');
    if (pictures!.id == null) {
      List<Pictures> allPaths = [];
      if (state.pathFiles.isNotEmpty) {
        allPaths.addAll(state.pathFiles);
        allPaths.removeWhere(
            (element) => element.path.toString() == path.toString());
      } else {
        allPaths.removeWhere(
            (element) => element.path.toString() == path.toString());
      }

      emit(state.copyWith(pathFiles: allPaths));
    } else {
      print('SunnyDeleteImage ${path}');
      // var response = await cookRepository!.userRepository!
      //     .deleteImage(id: pictures.id.toString(), type: 'food');
      // if (response.statusCode == 200) {
      List<Pictures> allPaths = [];
      if (state.pathFiles.isNotEmpty) {
        allPaths.addAll(state.pathFiles);
        print(
            'SunnyImageDel ${allPaths.firstWhere((element) => element.path.toString() == path.toString()).id.toString()}');
        state.deleteImagesId = [
          ...state.deleteImagesId,
          (allPaths
              .firstWhere(
                  (element) => element.path.toString() == path.toString())
              .id
              .toString())
        ];
        allPaths.removeWhere(
            (element) => element.path.toString() == path.toString());
      } else {
        state.deleteImagesId = [
          ...state.deleteImagesId,
          (allPaths
              .firstWhere(
                  (element) => element.path.toString() == path.toString())
              .id
              .toString())
        ];
        allPaths.removeWhere(
            (element) => element.path.toString() == path.toString());
      }
      print('SunnyDel ${state.deleteImagesId}');
      emit(state.copyWith(pathFiles: allPaths));
      getFoodMenu();
    }
  }

  onImageScroll({int? index}) {
    emit(state.copyWith(selectedPage: index));
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
        state.copyWith(foodStatusFormStatus: FormzStatus.submissionInProgress));
    var response = await cookRepository!.changFoodStatus(foodId: foodId);

    if (response.statusCode == 200) {
      FoodData foodData = state.selectedFoodMenu!
          .copyWith(status: state.selectedFoodMenu!.status == 1 ? 0 : 1);
      getFoodMenu();
      emit(state.copyWith(
          selectedFoodMenu: foodData,
          selectedFoodMenuUnChanged: foodData,
          foodStatusFormStatus: FormzStatus.submissionSuccess));
    } else {
      getFoodMenu();
      emit(state.copyWith(foodStatusFormStatus: FormzStatus.submissionFailure));
    }
  }
}
