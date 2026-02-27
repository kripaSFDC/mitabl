import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'edit_profile_cook_state.dart';

class EditProfileCookCubit extends Cubit<EditProfileCookState> {
  EditProfileCookCubit() : super(EditProfileCookInitial());
}
