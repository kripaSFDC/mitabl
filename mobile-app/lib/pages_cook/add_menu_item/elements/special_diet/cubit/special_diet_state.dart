part of 'special_diet_cubit.dart';

class SpecialDietState extends Equatable {
  const SpecialDietState({this.specialDietDataList = const []});

  final List<SpecialDietData>? specialDietDataList;

  SpecialDietState copyWith({List<SpecialDietData>? specialDietDataList}) {
    return SpecialDietState(
        specialDietDataList: specialDietDataList ?? this.specialDietDataList);
  }

  @override
  List<Object?> get props => [specialDietDataList];
}
