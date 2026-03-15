import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  Route route() {
    return MaterialPageRoute(
      builder: (context) {
        return const LandingPage();
      },
    );
  }

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  Future<void> _launchInBrowser(Uri url) async {
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${url.toString()}')),
        );
      }
    } on Exception {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${url.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _launchInBrowser(Uri.parse(ApiContract.webUrl('terms')));
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _launchInBrowser(Uri.parse(ApiContract.webUrl('privacy-policy')));
      };
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: config.AppConfig(context).appHeight(12)),
            Center(
              child: Image.asset(
                'assets/img/logo.png',
                height: config.AppConfig(context).appHeight(20),
                width: config.AppConfig(context).appWidth(80),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: config.AppConfig(context).appHeight(12)),
            Column(
              children: [
                MaterialButton(
                  height: config.AppConfig(context).appHeight(6),
                  minWidth: config.AppConfig(context).appWidth(80),
                  onPressed: () {
                    navigatorKey.currentState!.pushNamed('/LoginPage');
                  },
                  color: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      config.AppConfig(context).appWidth(10),
                    ),
                  ),
                  child: Text(
                    'LOGIN',
                    /*style: GoogleFonts.gothicA1(
                      fontSize: config.AppConfig(context).appWidth(3.5),
                      color: const Color(0xFFFFFBF7)),*/
                    style: TextStyle(
                      color: const Color(0xFFFFFBF7),
                      fontSize: 18,
                      fontWeight: config.FontFamily().book,
                    ),
                  ),
                ),
                SizedBox(height: config.AppConfig(context).appHeight(2)),
                MaterialButton(
                  height: config.AppConfig(context).appHeight(6),
                  minWidth: config.AppConfig(context).appWidth(80),
                  onPressed: () {
                    navigatorKey.currentState!.pushNamed('/SignUpPage');
                  },
                  color: Theme.of(context).primaryColorDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      config.AppConfig(context).appWidth(10),
                    ),
                  ),
                  child: Text(
                    'CREATE NEW ACCOUNT',
                    style: TextStyle(
                      color: const Color(0xFFFFFBF7),
                      fontSize: 18,
                      fontWeight: config.FontFamily().book,
                    ),
                  ),
                ),
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
                  fontWeight: config.FontFamily().book,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'terms of services',
                    recognizer: _termsRecognizer,
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: 14,
                      fontWeight: config.FontFamily().book,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and'),
                  TextSpan(
                    text: ' privacy policy',
                    recognizer: _privacyRecognizer,
                    style: TextStyle(
                      color: Theme.of(context).primaryColorDark,
                      fontSize: 14,
                      fontWeight: config.FontFamily().book,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: config.AppConfig(context).appHeight(2)),
          ],
        ),
      ),
    );
  }
}
