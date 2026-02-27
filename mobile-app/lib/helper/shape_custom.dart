import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;

class CustomShapeCook extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint0 = Paint()
      ..color = config.AppColors().colorPrimary(1)
      // ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    Path path0 = Path();
    path0.moveTo(size.width, 0);
    path0.quadraticBezierTo(
        size.width * 0.4375000, 0, size.width * 0.2500000, 0);
    path0.quadraticBezierTo(
        0, size.height * 0.2000000, 0, size.height * 0.5000000);
    path0.quadraticBezierTo(
        0, size.height * 0.8000000, size.width * 0.2500000, size.height);
    path0.quadraticBezierTo(
        size.width * 0.4375000, size.height, size.width, size.height);
    path0.lineTo(size.width, 0);
    path0.close();

    canvas.drawPath(path0, paint0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
