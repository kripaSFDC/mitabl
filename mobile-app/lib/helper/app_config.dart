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

  // ── The Culinary Atelier — Vibrant Orange Design System Colors ──

  Color mainColor(double opacity) {
    return _withOpacity(const Color(0xFFEA580C), opacity);
  }

  Color secondColor(double opacity) {
    return _withOpacity(const Color(0xFFEA580C), opacity);
  }

  Color accentColor(double opacity) {
    return _withOpacity(const Color(0xFF506140), opacity);
  }

  Color colorPrimary(double opacity) {
    return _withOpacity(const Color(0xFFEA580C), opacity);
  }

  Color colorPrimaryLight(double opacity) {
    return _withOpacity(const Color(0xFFEA580C), opacity);
  }

  Color colorPrimaryDark(double opacity) {
    return _withOpacity(const Color(0xFF0F172A), opacity);
  }

  Color colorDivider(double opacity) {
    return _withOpacity(const Color(0xFFF1F5F9), opacity);
  }

  Color textFieldBackgroundColor(double opacity) {
    return _withOpacity(const Color(0xFFF1F5F9), opacity);
  }

  Color hintTextBackgroundColor(double opacity) {
    return _withOpacity(const Color(0xFF475569), opacity);
  }

  Color scaffoldColor(double opacity, {Brightness brightness = Brightness.light}) {
    final baseColor =
        brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
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


