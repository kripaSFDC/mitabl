import 'package:formz/formz.dart' as formz;

typedef FormzInput<T, E> = formz.FormzInput<T, E>;
typedef FormzInputErrorCacheMixin<T, E> = formz.FormzInputErrorCacheMixin<T, E>;
typedef FormzMixin = formz.FormzMixin;

enum FormzStatus {
  pure,
  valid,
  invalid,
  submissionInProgress,
  submissionSuccess,
  submissionFailure,
  submissionCanceled,
}

extension FormzStatusX on FormzStatus {
  bool get isPure => this == FormzStatus.pure;
  bool get isValid => this == FormzStatus.valid;
  bool get isInvalid => this == FormzStatus.invalid;
  // Keep legacy behavior from older formz releases.
  bool get isValidated => isValid || isInvalid;

  bool get isSubmissionInProgress => this == FormzStatus.submissionInProgress;
  bool get isSubmissionSuccess => this == FormzStatus.submissionSuccess;
  bool get isSubmissionFailure => this == FormzStatus.submissionFailure;
  bool get isSubmissionCanceled => this == FormzStatus.submissionCanceled;
}

extension FormzInputLegacyX<T, E> on formz.FormzInput<T, E> {
  bool get valid => isValid;
  bool get invalid => isNotValid;
}

class Formz {
  static FormzStatus validate(List<formz.FormzInput<dynamic, dynamic>> inputs) {
    return formz.Formz.validate(inputs) ? FormzStatus.valid : FormzStatus.invalid;
  }

  static bool isPure(List<formz.FormzInput<dynamic, dynamic>> inputs) {
    return formz.Formz.isPure(inputs);
  }
}
