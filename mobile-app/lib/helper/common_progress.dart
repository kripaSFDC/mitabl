import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;

class CommonProgressWidget extends StatelessWidget {
  const CommonProgressWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Theme.of(context).hintColor.withOpacity(0.3),
        alignment: Alignment.center,
        height: config.AppConfig(context).appHeight(100),
        width: config.AppConfig(context).appWidth(100),
        child:  Center(
          child: CupertinoActivityIndicator(
            radius: 30,
            color: Theme.of(context).hintColor,
          ),
        ));
  }
}
