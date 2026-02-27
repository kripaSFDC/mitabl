import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;

class NoDataWidget extends StatelessWidget {
  const NoDataWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/img/no_data.svg',
              height: config.AppConfig(context).appHeight(20),
            ),
            SizedBox(
              height: config.AppConfig(context).appHeight(4),
            ),
            Text(
              'No data found',
              style: TextStyle(
                  fontFamily:
                      config.FontFamily().itcAvantGardeGothicStdFontFamily,
                  fontWeight: config.FontFamily().medium,
                  color: config.AppColors().colorPrimaryDark(1),
                  fontSize: config.AppConfig(context).appWidth(5)),
            )
          ]),
    );
  }
}
