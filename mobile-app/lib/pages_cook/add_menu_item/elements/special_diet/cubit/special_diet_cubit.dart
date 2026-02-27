import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../model/special_diet.dart';

part 'special_diet_state.dart';

class SpecialDietCubit extends Cubit<SpecialDietState> {
  SpecialDietCubit({List<SpecialDietData>? specialDietDataList})
      : super(SpecialDietState(specialDietDataList: specialDietDataList));

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
}
