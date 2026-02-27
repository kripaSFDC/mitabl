import 'dart:async';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:fluttertoast/fluttertoast.dart';

class Helper {
  BuildContext? context;
  DateTime? currentBackPressTime;

  Helper.of(BuildContext _context) {
    this.context = _context;
  }

  static int getIntData(Map<String, dynamic> data) {
    return (data['data'] as int?) ?? 0;
  }

  static double getDoubleData(Map<String, dynamic> data) {
    return (data['data'] as double?) ?? 0;
  }

  static bool getBoolData(Map<String, dynamic> data) {
    return (data['data'] as bool?) ?? false;
  }

  Future<void> showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Are you sure?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                // Navigator.of(context).pop();
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                // return Future.value().value(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showLocationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alert'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    'Please enable permission to all time access to location in your device settings to continue.'),
              ],
            ),
          ),
          actions: <Widget>[
            /*TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),*/
            TextButton(
              child: const Text('Ok'),
              onPressed: () async {
                // await  openAppSettings();
                Navigator.of(context).pop(true);

                // return Future.value().value(true);
              },
            ),
          ],
        );
      },
    );
  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  /// check if the string contains only numbers
  static bool isNumeric(String str) {
    var _numeric = RegExp(r'^-?[0-9]+$');
    return _numeric.hasMatch(str);
  }

  static bool isNumericDecimal(String str) {
    var _numeric = RegExp('^([0-9]+([.][0-9]*)?|[.][0-9]+)\$');
    // print(_numeric.hasMatch(str).toString());
    return _numeric.hasMatch(str);
  }

  static bool validateEmail(String value) {
    var pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    var regex = RegExp(pattern);
    if (!regex.hasMatch(value))
      return false;
    else
      return true;
  }

  static void showToast(dynamic message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER);
  }

  Color setPriorityColor({String? priority}) {
    if (priority!.toLowerCase() == 'low') {
      return const Color(0xff5bc0de);
    } else if (priority.toLowerCase() == 'high') {
      return const Color(0xffd9354f);
    } else if (priority.toLowerCase() == 'medium') {
      return const Color(0xfff0ad4e);
    } else {
      return Colors.white;
    }
  }
}
