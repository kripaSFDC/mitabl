part of 'add_menu_cubit.dart';

class AddMenuState extends Equatable {
  AddMenuState(
      {this.pathFiles = const [],
      this.selectedPage = 0,
      this.description = const Name.pure(),
      this.itemName = const Name.pure(),
      this.price = const Name.pure(),
      this.cookingStyleList = const [],
      this.specialDietDataList = const [],
      this.specialDietDataListOriginal = const [],
      this.deleteImagesId = const [],
      this.selectedCookingStyle,
      this.formzStatus = FormzStatus.pure,
      this.foodMenuStatus = FormzStatus.pure,
      this.addFoodStatus = FormzStatus.pure,
      this.foodStatusFormStatus = FormzStatus.pure,
      this.foodMenu,
      this.selectedFoodMenu,
      this.selectedFoodMenuUnChanged});

  final FormzStatus? formzStatus;
  final FormzStatus? addFoodStatus;
  final List<Pictures> pathFiles;
  List<String> deleteImagesId;
  final int? selectedPage;
  final Name? itemName;
  final Name? price;
  final Name? description;
  final List<CookingStyleData> cookingStyleList;
  final List<SpecialDietData>? specialDietDataList;
  final List<SpecialDietData>? specialDietDataListOriginal;
  final CookingStyleData? selectedCookingStyle;

  final FoodMenu? foodMenu;
  final FormzStatus? foodMenuStatus;

  final FoodData? selectedFoodMenu;
  final FoodData? selectedFoodMenuUnChanged;
  final FormzStatus? foodStatusFormStatus;

  AddMenuState copyWith(
      {Name? itemName,
      FormzStatus? foodStatusFormStatus,
      FoodData? selectedFoodMenu,
      FoodData? selectedFoodMenuUnChanged,
      FormzStatus? addFoodStatus,
      FormzStatus? foodMenuStatus,
      FoodMenu? foodMenu,
      FormzStatus? formsStatus,
      CookingStyleData? selectedCookingStyle,
      List<CookingStyleData>? cookingStyleList,
      List<String>? deleteImagesId,
      List<SpecialDietData>? specialDietDataList,
      List<SpecialDietData>? specialDietDataListOriginal,
      Name? price,
      Name? description,
      List<Pictures>? pathFiles,
      int? selectedPage}) {
    return AddMenuState(
      selectedFoodMenuUnChanged:
          selectedFoodMenuUnChanged ?? this.selectedFoodMenuUnChanged,
      foodStatusFormStatus: foodStatusFormStatus ?? this.foodStatusFormStatus,
      selectedFoodMenu: selectedFoodMenu ?? this.selectedFoodMenu,
      specialDietDataListOriginal:
          specialDietDataListOriginal ?? this.specialDietDataListOriginal,
      addFoodStatus: addFoodStatus ?? this.addFoodStatus,
      description: description ?? this.description,
      foodMenuStatus: foodMenuStatus ?? this.foodMenuStatus,
      deleteImagesId: deleteImagesId ?? this.deleteImagesId,
      foodMenu: foodMenu ?? this.foodMenu,
      formzStatus: formsStatus ?? this.formzStatus,
      price: price ?? this.price,
      itemName: itemName ?? this.itemName,
      selectedCookingStyle: selectedCookingStyle ?? this.selectedCookingStyle,
      specialDietDataList: specialDietDataList ?? this.specialDietDataList,
      cookingStyleList: cookingStyleList ?? this.cookingStyleList,
      pathFiles: pathFiles ?? this.pathFiles,
      selectedPage: selectedPage ?? this.selectedPage,
    );
  }

  @override
  List<Object?> get props => [
        selectedFoodMenuUnChanged,
        foodStatusFormStatus,
        selectedFoodMenu,
        addFoodStatus,
        addFoodStatus,
        specialDietDataListOriginal,
        description,
        foodMenuStatus,
        foodMenu,
        formzStatus,
        price,
        itemName,
        selectedCookingStyle,
        specialDietDataList,
        cookingStyleList,
        deleteImagesId,
        pathFiles,
        selectedPage
      ];
}
