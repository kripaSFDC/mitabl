import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;

import '../../../repos/authentication_repository.dart';
import '../cubit/requests_cubit.dart';

class AcceptRejectDialog extends StatelessWidget {
  const AcceptRejectDialog(
      {Key? key, this.isAccept, this.isFromOrderView = false, this.id})
      : super(key: key);

  final bool? isAccept;
  final bool? isFromOrderView;
  final dynamic? id;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: config.AppConfig(context).appHeight(30),
        width: config.AppConfig(context).appWidth(90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => navigatorKey.currentState!.pop(),
                  icon: SvgPicture.asset(
                    'assets/img/filter_cross.svg',
                    height: config.AppConfig(context).appHeight(2.0),
                  ),
                )
              ],
            ),
            Spacer(
              flex: 1,
            ),
            Text(
              'Order Request',
              style: TextStyle(
                fontFamily:
                    config.FontFamily().itcAvantGardeGothicStdFontFamily,
                fontWeight: config.FontFamily().demi,
                color: Theme.of(context).primaryColorDark,
                fontSize: config.AppConfig(context).appWidth(5.5),
              ),
            ),
            SizedBox(
              height: config.AppConfig(context).appHeight(2),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: config.AppConfig(context).appWidth(10)),
              child: Text(
                'Are you sure you want to ${isAccept! ? 'accept' : 'decline'} the order?',
                style: TextStyle(
                  fontFamily:
                      config.FontFamily().itcAvantGardeGothicStdFontFamily,
                  fontWeight: config.FontFamily().book,
                  color: Theme.of(context).primaryColorDark,
                  fontSize: config.AppConfig(context).appWidth(4.0),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: config.AppConfig(context).appHeight(3),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: config.AppConfig(context).appWidth(5)),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: config.AppConfig(context).appHeight(4.5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: Theme.of(context).primaryColor),
                      child: MaterialButton(
                          child: Text(
                            'YES',
                            style: TextStyle(
                              fontSize: config.AppConfig(context).appWidth(3.5),
                              color: Colors.white,
                              fontFamily: config.FontFamily()
                                  .itcAvantGardeGothicStdFontFamily,
                              fontWeight: config.FontFamily().book,
                            ),
                          ),
                          height: config.AppConfig(context).appHeight(6),
                          minWidth: config.AppConfig(context).appWidth(100),
                          onPressed: () {
                            context.read<RequestsCubit>().onOrderAcceptDecline(
                                isAccept: isAccept, orderId: id, isFromOrderView : isFromOrderView);
                          }),
                    ),
                  ),
                  SizedBox(
                    width: config.AppConfig(context).appWidth(3),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: config.AppConfig(context).appHeight(4.5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: Color(0xffE9E9E9)),
                      child: MaterialButton(
                          child: Text(
                            'NO',
                            style: TextStyle(
                              fontSize: config.AppConfig(context).appWidth(3.5),
                              color: config.AppColors().colorPrimaryDark(1),
                              fontFamily: config.FontFamily()
                                  .itcAvantGardeGothicStdFontFamily,
                              fontWeight: config.FontFamily().book,
                            ),
                          ),
                          height: config.AppConfig(context).appHeight(6),
                          minWidth: config.AppConfig(context).appWidth(100),
                          onPressed: () {
                            navigatorKey.currentState!.pop();
                          }),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: config.AppConfig(context).appHeight(4),
            ),
            Spacer(
              flex: 1,
            ),
          ],
        ),
      ),
    );
  }
}
