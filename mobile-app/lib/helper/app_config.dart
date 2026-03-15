import 'package:flutter/material.dart';

class AppConfig {
  late BuildContext _context;
  late double _height;
  late double _width;
  late double _heightPadding;
  late double _widthPadding;

  AppConfig(BuildContext context) {
    _context = context;
    var queryData = MediaQuery.of(_context);
    _height = queryData.size.height / 100.0;

    _width = queryData.size.width / 100.0;
    _heightPadding = _height -
        ((queryData.padding.top + queryData.padding.bottom) / 100.0);
    _widthPadding =
        _width - (queryData.padding.left + queryData.padding.right) / 100.0;
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
  double _normalizedOpacity(double opacity) {
    return opacity.clamp(0.0, 1.0);
  }

  Color _withOpacity(Color color, double opacity) {
    return color.withValues(alpha: _normalizedOpacity(opacity));
  }

  Color mainColor(double opacity) {
    return _withOpacity(const Color(0xFFEA580C), opacity);
  }

  Color secondColor(double opacity) {
    return _withOpacity(const Color(0xFF9A3412), opacity);
  }

  Color accentColor(double opacity) {
    return _withOpacity(const Color(0xFF10B981), opacity);
  }

  Color colorPrimary(double opacity) {
    return _withOpacity(const Color(0xFFEA580C), opacity);
  }

  Color colorPrimaryLight(double opacity) {
    return _withOpacity(const Color(0xFFF97316), opacity);
  }

  Color colorPrimaryDark(double opacity) {
    return _withOpacity(const Color(0xFF7C2D12), opacity);
  }

  Color colorDivider(double opacity) {
    try {
      return const Color(0xFFFFEDD5).withValues(alpha: opacity);
    } catch (e) {
      return const Color(0xFFCCCCCC).withValues(alpha: opacity);
    }
  }

  Color textFieldBackgroundColor(double opacity) {
    try {
      return const Color(0xFFFFF7ED).withValues(alpha: opacity);
    } catch (e) {
      return const Color(0xFFCCCCCC).withValues(alpha: opacity);
    }
  }

  Color hintTextBackgroundColor(double opacity) {
    try {
      return const Color(0xFF9CA3AF).withValues(alpha: opacity);
    } catch (e) {
      return const Color(0xFFCCCCCC).withValues(alpha: opacity);
    }
  }

  // Color mainDarkColor(double opacity) {
  //   try {
  //     return Color(int.parse(settingRepo.setting.value.mainDarkColor.replaceAll("#", "0xFF"))).withValues(alpha: opacity);
  //   } catch (e) {
  //     return Color(0xFFCCCCCC).withValues(alpha: opacity);
  //   }
  // }

  // Color secondDarkColor(double opacity) {
  //   try {
  //     return Color(int.parse(settingRepo.setting.value.secondDarkColor.replaceAll("#", "0xFF"))).withValues(alpha: opacity);
  //   } catch (e) {
  //     return Color(0xFFCCCCCC).withValues(alpha: opacity);
  //   }
  // }

  // Color accentDarkColor(double opacity) {
  //   try {
  //     return Color(int.parse(settingRepo.setting.value.accentDarkColor.replaceAll("#", "0xFF"))).withValues(alpha: opacity);
  //   } catch (e) {
  //     return Color(0xFFCCCCCC).withValues(alpha: opacity);
  //   }
  // }

  Color scaffoldColor(double opacity, {Brightness brightness = Brightness.light}) {
    final baseColor =
        brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFFFFAF5);
    return _withOpacity(baseColor, opacity);
  }

  Color presentButtonColor(double opacity) {
    return _withOpacity(const Color(0xff8CD0E8), opacity);
  }

  Color absentButtonColor(double opacity) {
    return _withOpacity(const Color(0xff8CB648), opacity);
  }

  Color presentButtonBorderColor(double opacity) {
    return _withOpacity(const Color(0xff63B8DD), opacity);
  }

  Color buttonDisableColor(double opacity) {
    return _withOpacity(const Color(0xffF2F3F6), opacity);
  }

  Color buttonDisableBorderColor(double opacity) {
    return _withOpacity(const Color(0xffDCE1E7), opacity);
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


