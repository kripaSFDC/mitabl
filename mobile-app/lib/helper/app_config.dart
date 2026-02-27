import 'package:flutter/material.dart';

class AppConfig {
  late BuildContext _context;
  late double _height;
  late double _width;
  late double _heightPadding;
  late double _widthPadding;

  AppConfig(BuildContext _context) {
    this._context = _context;
    var _queryData = MediaQuery.of(this._context);
    _height = _queryData.size.height / 100.0;

    _width = _queryData.size.width / 100.0;
    _heightPadding = _height -
        ((_queryData.padding.top + _queryData.padding.bottom) / 100.0);
    _widthPadding =
        _width - (_queryData.padding.left + _queryData.padding.right) / 100.0;
  }

  double appHeight(double v) {
    return _height * v;
  }

  double appWidth(double v) {
    return _width * v;
  }

  double appVerticalPadding(double v) {
    return _heightPadding * v;
  }

  double appHorizontalPadding(double v) {
//    int.parse(settingRepo.setting.mainColor.replaceAll("#", "0xFF"));
    return _widthPadding * v;
  }
}

class AppColors {
  Color mainColor(double opacity) {
    try {
      return const Color.fromARGB(255, 28, 36, 89);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color secondColor(double opacity) {
    try {
      // return const Color(0xFF90A0B7);
      return Colors.grey.shade500;
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color accentColor(double opacity) {
    try {
      return const Color(0xFF18489C);
      // return  const Color(0xFF4FCD07);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color colorPrimary(double opacity) {
    try {
      // return  const Color.fromARGB(255, 42, 49, 91);
      return const Color(0xff0071BC);
      // return const Color(0xFF4A439F);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color colorPrimaryLight(double opacity) {
    try {
      // return  const Color.fromARGB(255, 42, 49, 91);
      return Colors.grey;
      // return Color(0xffaca1f2);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color colorPrimaryDark(double opacity) {
    try {
      // return  const Color(0xFF286704).withOpacity(opacity);
      // return  Colors.black;
      return const Color(0xFF666666);
      // return const Color(0xFF4A439F);
      // return const Color(0xFF7366FF);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color colorDivider(double opacity) {
    try {
      return const Color(0xFF001757).withOpacity(opacity);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color textFieldBackgroundColor(double opacity) {
    try {
      return const Color(0xFFE9E9E9).withOpacity(opacity);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color hintTextBackgroundColor(double opacity) {
    try {
      return const Color(0xFFAEAEAE).withOpacity(opacity);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  // Color mainDarkColor(double opacity) {
  //   try {
  //     return Color(int.parse(settingRepo.setting.value.mainDarkColor.replaceAll("#", "0xFF"))).withOpacity(opacity);
  //   } catch (e) {
  //     return Color(0xFFCCCCCC).withOpacity(opacity);
  //   }
  // }

  // Color secondDarkColor(double opacity) {
  //   try {
  //     return Color(int.parse(settingRepo.setting.value.secondDarkColor.replaceAll("#", "0xFF"))).withOpacity(opacity);
  //   } catch (e) {
  //     return Color(0xFFCCCCCC).withOpacity(opacity);
  //   }
  // }

  // Color accentDarkColor(double opacity) {
  //   try {
  //     return Color(int.parse(settingRepo.setting.value.accentDarkColor.replaceAll("#", "0xFF"))).withOpacity(opacity);
  //   } catch (e) {
  //     return Color(0xFFCCCCCC).withOpacity(opacity);
  //   }
  // }

  Color scaffoldColor(double opacity) {
    // TODO test if brightness is dark or not
    try {
      // return  const Color(0xffeee6ff).withOpacity(1);
      return Colors.white;
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color presentButtonColor(double opacity) {
    try {
      return const Color(0xff8CD0E8).withOpacity(1);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color absentButtonColor(double opacity) {
    try {
      return const Color(0xff8CB648).withOpacity(1);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color presentButtonBorderColor(double opacity) {
    try {
      return const Color(0xff63B8DD).withOpacity(1);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color buttonDisableColor(double opacity) {
    try {
      return const Color(0xffF2F3F6).withOpacity(1);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }

  Color buttonDisableBorderColor(double opacity) {
    try {
      return const Color(0xffDCE1E7).withOpacity(1);
    } catch (e) {
      return const Color(0xFFCCCCCC).withOpacity(opacity);
    }
  }
}
class FontFamily {
  static final FontFamily _singleton = FontFamily._internal();
  factory FontFamily() {
    return _singleton;
  }
  FontFamily._internal();

  String itcAvantGardeGothicStdFontFamily = "itc_avant_garde_gothic_std";
  FontWeight extraLight = FontWeight.w200;
  FontWeight book = FontWeight.w300;
  FontWeight medium = FontWeight.w500;
  FontWeight demi = FontWeight.w600;
  FontWeight bold = FontWeight.w700;
}

