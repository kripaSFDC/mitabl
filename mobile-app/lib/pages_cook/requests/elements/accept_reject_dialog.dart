import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;

import '../../../repos/authentication_repository.dart';
import '../cubit/requests_cubit.dart';

class AcceptRejectDialog extends StatelessWidget {
  const AcceptRejectDialog({
    super.key,
    this.isAccept,
    this.isFromOrderView = false,
    this.id,
  });

  final bool? isAccept;
  final bool? isFromOrderView;
  final dynamic id;

  @override
  Widget build(BuildContext context) {
    final cancelReasonController = TextEditingController();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: config.AppConfig(context).appHeight(isAccept! ? 30 : 40),
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
                ),
              ],
            ),
            const Spacer(flex: 1),
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
            SizedBox(height: config.AppConfig(context).appHeight(2)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: config.AppConfig(context).appWidth(10),
              ),
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
            if (!isAccept!) ...[
              SizedBox(height: config.AppConfig(context).appHeight(2)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: config.AppConfig(context).appWidth(8),
                ),
                child: TextField(
                  controller: cancelReasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Reason for decline',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
            SizedBox(height: config.AppConfig(context).appHeight(3)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: config.AppConfig(context).appWidth(5),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: config.AppConfig(context).appHeight(4.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Theme.of(context).primaryColor,
                      ),
                      child: MaterialButton(
                        height: config.AppConfig(context).appHeight(6),
                        minWidth: config.AppConfig(context).appWidth(100),
                        onPressed: () {
                          final cancelComment = cancelReasonController.text
                              .trim();
                          if (!isAccept! && cancelComment.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a reason for declining the order.',
                                ),
                              ),
                            );
                            return;
                          }
                          context.read<RequestsCubit>().onOrderAcceptDecline(
                            isAccept: isAccept,
                            orderId: id,
                            isFromOrderView: isFromOrderView,
                            cancelComment: cancelComment,
                          );
                        },
                        child: Text(
                          'YES',
                          style: TextStyle(
                            fontSize: config.AppConfig(context).appWidth(3.5),
                            color: const Color(0xFFFFFBF7),
                            fontFamily: config.FontFamily()
                                .itcAvantGardeGothicStdFontFamily,
                            fontWeight: config.FontFamily().book,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: config.AppConfig(context).appWidth(3)),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: config.AppConfig(context).appHeight(4.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: const Color(0xffE9E9E9),
                      ),
                      child: MaterialButton(
                        height: config.AppConfig(context).appHeight(6),
                        minWidth: config.AppConfig(context).appWidth(100),
                        onPressed: () {
                          navigatorKey.currentState!.pop();
                        },
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: config.AppConfig(context).appHeight(4)),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
