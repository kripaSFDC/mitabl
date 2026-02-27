import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;

class SplashPage extends StatefulWidget {
  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => SplashPage());
  }

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Image.asset(
              'assets/img/logo.png',
              height: config.AppConfig(context).appHeight(20),
              width: config.AppConfig(context).appWidth(80),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
