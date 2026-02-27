part of 'dashboard_cook_cubit.dart';

class DashboardCookState extends Equatable {
  const DashboardCookState({this.selectedIndex = 0, this.dashboardData});

  final int? selectedIndex;
  final dd.DashboardData? dashboardData;

  DashboardCookState copyWith(
      {dd.DashboardData? dashboardData, int? selectedIndex}) {
    return DashboardCookState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      dashboardData: dashboardData ?? this.dashboardData,
    );
  }

  @override
  List<Object?> get props => [selectedIndex, dashboardData];
}
