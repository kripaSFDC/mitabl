import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  Route route() {
    return MaterialPageRoute(builder: (context) {
      return LandingPage();
    });
  }

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: config.AppConfig(context).appHeight(12),
          ),
          Center(
            child: Image.asset(
              'assets/img/logo.png',
              height: config.AppConfig(context).appHeight(20),
              width: config.AppConfig(context).appWidth(80),
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(
            height: config.AppConfig(context).appHeight(12),
          ),
          Column(
            children: [
              MaterialButton(
                height: config.AppConfig(context).appHeight(6),
                minWidth: config.AppConfig(context).appWidth(80),
                onPressed: () {
                  navigatorKey.currentState!.pushNamed('/LoginPage');
                },
                color: Theme.of(context).primaryColor,
                child: Text(
                  'LOGIN',
                  /*style: GoogleFonts.gothicA1(
                      fontSize: config.AppConfig(context).appWidth(3.5),
                      color: Colors.white),*/
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: config.FontFamily().book),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        config.AppConfig(context).appWidth(10))),
              ),
              SizedBox(
                height: config.AppConfig(context).appHeight(2),
              ),
              MaterialButton(
                height: config.AppConfig(context).appHeight(6),
                minWidth: config.AppConfig(context).appWidth(80),
                onPressed: () {
                  navigatorKey.currentState!.pushNamed('/SignUpPage');
                },
                color: Theme.of(context).primaryColorDark,
                child: Text(
                  'CREATE NEW ACCOUNT',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: config.FontFamily().book),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        config.AppConfig(context).appWidth(10))),
              )
            ],
          ),
          const Spacer(),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'By login in, you agree to our\n',
              style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontSize: 14,
                  fontWeight: config.FontFamily().book),
              children: <TextSpan>[
                TextSpan(
                  text: 'terms of services',
                  recognizer: new TapGestureRecognizer()
                    ..onTap = () async {
                      _launchInBrowser(
                          Uri.parse('https://mitabl.xcelanceweb.com/terms'));
                    },
                  style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: 14,
                      fontWeight: config.FontFamily().book,
                      decoration: TextDecoration.underline),
                ),
                TextSpan(
                  text: ' and',
                ),
                TextSpan(
                    text: ' privacy policy',recognizer: new TapGestureRecognizer()
                  ..onTap = () async {
                    _launchInBrowser(
                        Uri.parse('https://mitabl.xcelanceweb.com/privacy-policy'));
                  },
                    style: TextStyle(
                        color: Theme.of(context).primaryColorDark,
                        fontSize: 14,
                        fontWeight: config.FontFamily().book,
                        decoration: TextDecoration.underline)),
              ],
            ),
          ),
          SizedBox(
            height: config.AppConfig(context).appHeight(2),
          ),
        ],
      )),
    );
  }
}
