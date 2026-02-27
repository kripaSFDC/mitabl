import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

class CookingStyleDialog extends StatelessWidget {
  const CookingStyleDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddMenuCubit, AddMenuState>(
      listener: (context, state) {},
      builder: (context, state) {
        print('selectedCookingStyle ${state.selectedCookingStyle!.name!}');
        return Container(
          height: config.AppConfig(context).appHeight(40),
          width: config.AppConfig(context).appWidth(50),
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                Text(
                  'Cooking Style',
                  style: TextStyle(
                    fontFamily:
                        config.FontFamily().itcAvantGardeGothicStdFontFamily,
                    fontWeight: config.FontFamily().demi,
                    color: Theme.of(context).primaryColorDark,
                    fontSize: config.AppConfig(context).appWidth(6),
                  ),
                ),
                SizedBox(
                  height: config.AppConfig(context).appHeight(2),
                ),
                Container(
                  height: config.AppConfig(context).appHeight(60),
                  child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          height: config.AppConfig(context).appHeight(0.1),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return CheckboxListTile(
                          value: state.cookingStyleList[index].isSelected!,
                          onChanged: (a) {
                            context
                                .read<AddMenuCubit>()
                                .onCookingStyleChange(value: a, index: index);
                          },
                          title: Text(
                            state.cookingStyleList[index].name!,
                            style: TextStyle(
                              fontFamily: config.FontFamily()
                                  .itcAvantGardeGothicStdFontFamily,
                              fontWeight: config.FontFamily().book,
                              color: Theme.of(context).primaryColorDark,
                              fontSize: config.AppConfig(context).appWidth(4.5),
                            ),
                          ),
                        );
                      },
                      itemCount: state.cookingStyleList.length),
                ),
               /* SizedBox(
                  height: config.AppConfig(context).appHeight(1),
                ),*/
                /*Container(
                  height: 45,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.topRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor,
                          ])),
                  child: MaterialButton(
                      child: Text(
                        'OKAY',
                        style: TextStyle(
                            fontFamily: config.FontFamily()
                                .itcAvantGardeGothicStdFontFamily,
                            fontWeight: config.FontFamily().book,
                            fontSize: config.AppConfig(context).appWidth(3.5),
                            color: Colors.white),
                      ),
                      minWidth: config.AppConfig(context).appWidth(30),
                      height: 50.0,
                      onPressed: () {
                        navigatorKey.currentState!.pop();
                      }),
                ),*/
                SizedBox(
                  height: config.AppConfig(context).appHeight(3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
