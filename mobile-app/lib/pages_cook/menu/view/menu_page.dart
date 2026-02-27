import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';

import '../../../helper/common_progress.dart';
import '../../../helper/no_data_widget.dart';
import '../../../model/food_menu.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddMenuCubit, AddMenuState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leadingWidth: config.AppConfig(context).appWidth(25),
            leading: Padding(
              padding: EdgeInsets.only(
                  left: config.AppConfig(context).appWidth(4),
                  top: config.AppConfig(context).appHeight(2)),
              child: Center(
                child: Text(
                  'Menu',
                  style: Theme.of(context).textTheme.headline5?.copyWith(
                        fontSize: config.AppConfig(context).appWidth(5.0),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            actions: [
              Padding(
                padding: EdgeInsets.only(
                    top: config.AppConfig(context).appHeight(0.2)),
                child: IconButton(
                    onPressed: () {
                      navigatorKey.currentState!.pushNamed('/AddMenuPage',
                          arguments: RouteArguments(isEdit: false));
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: config.AppConfig(context).appWidth(7),
                      color: Theme.of(context).primaryColorDark,
                    )),
              )
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<AddMenuCubit>().getFoodMenu();
            },
            child: Stack(
              children: [
                state.foodMenuStatus!.isSubmissionInProgress
                    ? Center()
                    : state.foodMenu != null &&
                            state.foodMenu!.foodData!.length > 0
                        ? Padding(
                            padding: EdgeInsets.only(
                                top: config.AppConfig(context).appHeight(3)),
                            child: ListView.separated(
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: config.AppConfig(context)
                                            .appWidth(3),
                                        vertical: config.AppConfig(context)
                                            .appWidth(2)),
                                    child: InkWell(
                                      splashFactory: NoSplash.splashFactory,
                                      onTap: () {
                                        context
                                            .read<AddMenuCubit>()
                                            .setUnChangedFood(
                                                foodData: state.foodMenu!
                                                    .foodData![index]);
                                        context.read<AddMenuCubit>().setFields(
                                            foodData: state
                                                .foodMenu!.foodData![index]);
                                        navigatorKey.currentState!.pushNamed(
                                            '/MenuDetails',
                                            arguments: RouteArguments(
                                                foodData: state
                                                    .foodMenu!.foodData![index],
                                                isEdit: true));
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: CachedNetworkImage(
                                              alignment: Alignment.center,
                                              height: config.AppConfig(context)
                                                  .appHeight(12),
                                              width: config.AppConfig(context)
                                                  .appWidth(26),
                                              fit: BoxFit.cover,
                                              imageUrl:
                                                  '${GlobalConfiguration().getValue<String>('image_base_url')}${state.foodMenu!.foodData![index].pictures!.isNotEmpty ? state.foodMenu!.foodData![index].pictures![0].path : ''}',
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                color: Theme.of(context)
                                                    .backgroundColor,
                                              ),
                                              placeholder: (context, s) =>
                                                  Container(
                                                color: Theme.of(context)
                                                    .backgroundColor,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: config.AppConfig(context)
                                                .appWidth(3),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${state.foodMenu!.foodData![index].foodName}',
                                                  style: GoogleFonts.gothicA1(
                                                      color: Theme.of(context)
                                                          .primaryColorDark,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          config.AppConfig(
                                                                  context)
                                                              .appWidth(5)),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(
                                                  height:
                                                      config.AppConfig(context)
                                                          .appHeight(0.5),
                                                ),
                                                Text(
                                                  '${state.foodMenu!.foodData![index].description}',
                                                  style: GoogleFonts.gothicA1(
                                                      color: Theme.of(context)
                                                          .primaryColorDark,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontSize:
                                                          config.AppConfig(
                                                                  context)
                                                              .appWidth(4)),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(
                                                  height:
                                                      config.AppConfig(context)
                                                          .appHeight(0.5),
                                                ),
                                                Text(
                                                  'AUD ${state.foodMenu!.foodData![index].price}',
                                                  style: GoogleFonts.gothicA1(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          config.AppConfig(
                                                                  context)
                                                              .appWidth(5)),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return SizedBox(
                                    height: config.AppConfig(context)
                                        .appHeight(0.5),
                                  );
                                },
                                itemCount: state.foodMenu!.foodData!.length),
                          )
                        : const NoDataWidget(),
                state.foodMenuStatus!.isSubmissionInProgress
                    ? CommonProgressWidget()
                    : SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    context.read<AddMenuCubit>().getFoodMenu();
    context.read<AddMenuCubit>().getCookingStyle();
    context.read<AddMenuCubit>().getSpecialDiet();
  }
}
