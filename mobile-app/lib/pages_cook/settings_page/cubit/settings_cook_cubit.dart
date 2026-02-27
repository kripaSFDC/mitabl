import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'settings_cook_state.dart';

class SettingsCookCubit extends Cubit<SettingsCookState> {
  SettingsCookCubit() : super(SettingsCookInitial());
}
