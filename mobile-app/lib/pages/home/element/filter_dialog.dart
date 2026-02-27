import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/model/cooking_style.dart';
import 'package:mitabl_user/pages/home/cubit/home_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:formz/formz.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({Key? key}) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  @override
  void initState() {
    context.read<HomeCubit>().onCookingStyle();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(builder: (context, state) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
                Radius.circular(config.AppConfig(context).appWidth(5)))),
        child: Container(
          height: config.AppConfig(context).appHeight(48),
          width: config.AppConfig(context).appWidth(90),
          padding: EdgeInsets.all(
            config.AppConfig(context).appWidth(1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => {},
                    icon: Icon(
                      Icons.abc,
                      color: Colors.transparent,
                    ),
                  ),
                  Text('Filters',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontWeight: FontWeight.w600,
                          fontSize: config.AppConfig(context).appWidth(5))),
                  IconButton(
                    onPressed: () => navigatorKey.currentState!.pop(),
                    icon: SvgPicture.asset(
                      'assets/img/filter_cross.svg',
                      height: config.AppConfig(context).appHeight(2.0),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: config.AppConfig(context).appHeight(1),
              ),
              Spacer(),
              state.statusCooking!.isSubmissionInProgress
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: Colors.grey,
                      ),
                    )
                  : Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: config.AppConfig(context).appWidth(2)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: config.AppColors().textFieldBackgroundColor(1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<CookingStyleData>(
                            value: state.selectedCookingData,
                            hint: Text(
                              "Cooking Style",
                            ),
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            style: TextStyle(
                                color: Theme.of(context).primaryColorDark,
                                fontWeight: FontWeight.w500,
                                fontSize:
                                    config.AppConfig(context).appWidth(4)),
                            onChanged: (CookingStyleData? data) {
                              setState(() {
                                context
                                    .read<HomeCubit>()
                                    .onCookingStyleChanged(data: data);
                              });
                            },
                            items: state.cookingStyleList!
                                .map<DropdownMenuItem<CookingStyleData>>(
                                    (CookingStyleData value) {
                              return DropdownMenuItem<CookingStyleData>(
                                value: value,
                                child: Text(value.name.toString()),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
              SizedBox(
                height: config.AppConfig(context).appHeight(3),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal: config.AppConfig(context).appWidth(5)),
                alignment: Alignment.centerLeft,
                child: Text(
                    'Distance ${state.selectedDistance!.toInt().toString()} km',
                    style: GoogleFonts.gothicA1(
                        color: Theme.of(context).primaryColorDark,
                        fontWeight: FontWeight.w600,
                        fontSize: config.AppConfig(context).appWidth(4))),
              ),
              Slider(
                label: state.selectedDistance.toString(),
                value: state.selectedDistance!.toDouble(),
                onChanged: (value) {
                  context.read<HomeCubit>().onDistanceChanged(distance: value);
                },
                min: 1,
                max: 100,
              ),
              SizedBox(
                height: config.AppConfig(context).appHeight(3),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                    horizontal: config.AppConfig(context).appWidth(2)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () {
                          context
                              .read<HomeCubit>()
                              .onRoleChanged(role: AppConstants.DINE_IN);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                config.AppColors().textFieldBackgroundColor(1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                                config.AppConfig(context).appWidth(2)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        'Dine-in',
                                        style: GoogleFonts.gothicA1(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                            fontWeight: FontWeight.w600,
                                            fontSize: config.AppConfig(context)
                                                .appWidth(4)),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(3),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: state.selectDineTake ==
                                          AppConstants.DINE_IN
                                      ? Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                          child: Icon(
                                            Icons.done,
                                            color: Colors.white,
                                            size: config.AppConfig(context)
                                                .appWidth(5),
                                          ),
                                        )
                                      : Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: config.AppConfig(context)
                                              .appWidth(5),
                                        ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(2),
                    ),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () {
                          context
                              .read<HomeCubit>()
                              .onRoleChanged(role: AppConstants.TAKE_AWAY);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                config.AppColors().textFieldBackgroundColor(1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                                config.AppConfig(context).appWidth(2)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        'Take-away',
                                        style: GoogleFonts.gothicA1(
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                            fontWeight: FontWeight.w600,
                                            fontSize: config.AppConfig(context)
                                                .appWidth(4)),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: config.AppConfig(context).appWidth(3),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: state.selectDineTake ==
                                          AppConstants.TAKE_AWAY
                                      ? Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                          child: Icon(
                                            Icons.done,
                                            color: Colors.white,
                                            size: config.AppConfig(context)
                                                .appWidth(5),
                                          ),
                                        )
                                      : Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: config.AppConfig(context)
                                              .appWidth(5),
                                        ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: config.AppConfig(context).appHeight(6),
              ),
              ApplyButton(
                loginForm: this,
              ),
              Spacer(),
            ],
          ),
        ),
      );
    });
  }
}

class ApplyButton extends StatelessWidget {
  final _FilterDialogState? loginForm;

  const ApplyButton({Key? key, this.loginForm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeCubit, HomeState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Container(
          height: 45,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.topRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor,
                ],
              )),
          child: MaterialButton(
              child: state.status!.isSubmissionInProgress
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'APPLY',
                      style: GoogleFonts.gothicA1(
                          fontSize: config.AppConfig(context).appWidth(3.5),
                          color: Colors.white),
                    ),
              minWidth: config.AppConfig(context).appWidth(50),
              height: 50.0,
              onPressed: () {
                context.read<HomeCubit>().onApplyFilter();
                navigatorKey.currentState!.pop();
              }),
        );
      },
    );
  }
}
