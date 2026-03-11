import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';
import 'package:mitabl_user/helper/formz_compat.dart';

class MenuDetails extends StatefulWidget {
  const MenuDetails({super.key, this.routeArguments});

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
        builder: (_) => MenuDetails(
              routeArguments: routeArguments,
            ));
  }

  @override
  State<MenuDetails> createState() => _MenuDetailsState();
}

class _MenuDetailsState extends State<MenuDetails> {
  PageController? controller = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<bool> _onBackPressed() async {
    context.read<AddMenuCubit>().resetFields();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        if (await _onBackPressed() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: config.AppConfig(context).appWidth(80),
          leading: Padding(
            padding: EdgeInsets.only(
                left: config.AppConfig(context).appWidth(4),
                top: config.AppConfig(context).appHeight(3)),
            child: InkWell(
              splashFactory: NoSplash.splashFactory,
              onTap: () {
                context.read<AddMenuCubit>().resetFields();
                navigatorKey.currentState!.pop();
              },
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    color: Theme.of(context).primaryColorDark,
                    size: config.AppConfig(context).appWidth(5),
                  ),
                  SizedBox(
                    width: config.AppConfig(context).appWidth(2),
                  ),
                  Flexible(
                    child: Text(
                      'Menu',
                      style: TextStyle(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(5),
                          fontFamily: config.FontFamily()
                              .itcAvantGardeGothicStdFontFamily,
                          fontWeight: config.FontFamily().medium),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: BlocBuilder<AddMenuCubit, AddMenuState>(
          builder: (context, state) {
            // print('builderselectedFoodMenu ${state.selectedFoodMenu!.id}');
            return Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: config.AppConfig(context).appHeight(4),
                    ),
                    Stack(
                      children: [
                        state.pathFiles.isNotEmpty
                            ? Container(
                                height: config.AppConfig(context).appHeight(20),
                                width: config.AppConfig(context).appWidth(100),
                                padding: EdgeInsets.zero,
                                child: PageView.builder(
                                  padEnds: true,
                                  clipBehavior: Clip.hardEdge,
                                  // pageSnapping: true,
                                  controller: controller,
                                  onPageChanged: (page) {
                                    context
                                        .read<AddMenuCubit>()
                                        .onImageScroll(index: page);
                                  },
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: config.AppConfig(context)
                                              .appWidth(1)),
                                      child: Container(
                                        height: config.AppConfig(context)
                                            .appHeight(20),
                                        width: config.AppConfig(context)
                                            .appWidth(100),
                                        decoration: BoxDecoration(
                                          color: config.AppColors()
                                              .textFieldBackgroundColor(1),
                                          borderRadius: BorderRadius.circular(
                                              config.AppConfig(context)
                                                  .appWidth(5)),
                                        ),
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.zero,
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              '${GlobalConfiguration().getValue<String>('image_base_url')}${state.pathFiles[index].path}',
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Theme.of(context)
                                                .colorScheme.surface,
                                          ),
                                          placeholder: (context, s) =>
                                              Container(
                                            color: Theme.of(context)
                                                .colorScheme.surface,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  itemCount: state.pathFiles.length,
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.only(
                                    left: config.AppConfig(context).appWidth(5),
                                    right:
                                        config.AppConfig(context).appWidth(5)),
                                child: Container(
                                  height:
                                      config.AppConfig(context).appHeight(20),
                                  decoration: BoxDecoration(
                                      color: config.AppColors()
                                          .textFieldBackgroundColor(1),
                                      borderRadius: BorderRadius.circular(
                                          config.AppConfig(context)
                                              .appWidth(5))),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.photo_outlined,
                                    size:
                                        config.AppConfig(context).appWidth(30),
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          // alignment: Alignment.center,

                          child: state.pathFiles.isNotEmpty
                              ? Container(
                                  alignment: Alignment.center,
                                  height:
                                      config.AppConfig(context).appHeight(5),
                                  child: ListView.separated(
                                    // controller: controller,
                                    separatorBuilder: (context, index) {
                                      return SizedBox(
                                        width: config.AppConfig(context)
                                            .appWidth(2),
                                      );
                                    },
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        width: config.AppConfig(context)
                                            .appWidth(2),
                                        decoration: BoxDecoration(
                                            color: state.selectedPage == index
                                                ? const Color(0xff0071BC)
                                                : const Color(0xffD6D6D6),
                                            shape: BoxShape.circle),
                                      );
                                    },
                                    itemCount: state.pathFiles.length,
                                  ),
                                )
                              : const SizedBox(),
                        )
                      ],
                    ),
                    SizedBox(
                      height: config.AppConfig(context).appHeight(4),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: config.AppConfig(context).appWidth(3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.routeArguments!.foodData!.foodName ?? '',
                            style: TextStyle(
                                fontFamily: config.FontFamily()
                                    .itcAvantGardeGothicStdFontFamily,
                                fontWeight: config.FontFamily().medium,
                                fontSize:
                                    config.AppConfig(context).appWidth(4.5),
                                color: const Color(0xff666666)),
                          ),
                          SizedBox(
                            height: config.AppConfig(context).appHeight(1.5),
                          ),
                          Text(
                            widget.routeArguments!.foodData!.description ?? '',
                            style: TextStyle(
                              fontFamily: config.FontFamily()
                                  .itcAvantGardeGothicStdFontFamily,
                              // fontWeight: config.FontFamily().medium,
                              fontSize: config.AppConfig(context).appWidth(3.5),
                              color: const Color(0xff666666),
                            ),
                            maxLines: 6,
                          ),
                          SizedBox(
                            height: config.AppConfig(context).appHeight(2),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "AUD ${widget.routeArguments!.foodData!.price ?? ''}",
                                style: TextStyle(
                                    fontFamily: config.FontFamily()
                                        .itcAvantGardeGothicStdFontFamily,
                                    fontWeight: config.FontFamily().medium,
                                    fontSize:
                                        config.AppConfig(context).appWidth(5),
                                    color: Theme.of(context).primaryColor),
                                maxLines: 3,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Available',
                                    style: TextStyle(
                                        fontFamily: config.FontFamily()
                                            .itcAvantGardeGothicStdFontFamily,
                                        color:
                                            Theme.of(context).primaryColorDark,
                                        fontSize: config.AppConfig(context)
                                            .appWidth(3.2)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                    width:
                                        config.AppConfig(context).appWidth(2),
                                  ),
                                  Switch(
                                    value: state.selectedFoodMenu!.status == 1,
                                    activeTrackColor: const Color(0xffE9E9E9),
                                    activeThumbColor: Theme.of(context).primaryColor,
                                    onChanged: (val) {
                                      context
                                          .read<AddMenuCubit>()
                                          .onFoodStatusChange(
                                              foodId: state.selectedFoodMenu!.id
                                                  .toString());
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: config.AppConfig(context).appHeight(6),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              alignment: Alignment.center,
                              height: config.AppConfig(context).appHeight(6),
                              width: config.AppConfig(context).appWidth(80),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.topRight,
                                    colors: state.selectedFoodMenu!.status == 1
                                        ? [
                                            Theme.of(context).primaryColor,
                                            Theme.of(context).primaryColor,
                                          ]
                                        : [
                                            const Color(0xffE9E9E9),
                                            const Color(0xffE9E9E9),
                                          ],
                                  )),
                              child: MaterialButton(
                                  height:
                                      config.AppConfig(context).appHeight(6),
                                  minWidth:
                                      config.AppConfig(context).appWidth(100),
                                  onPressed: () {
                                    if (state.selectedFoodMenu!.status == 1) {
                                      context.read<AddMenuCubit>().setFields(
                                          foodData:
                                              state.selectedFoodMenuUnChanged);
                                      navigatorKey.currentState!
                                          .pushNamed('/AddMenuPage',
                                              arguments: RouteArguments(
                                                  foodData:
                                                      state.selectedFoodMenu,
                                                  isEdit: true))
                                          .then((value) {
                                        if (value != null && value == true) {
                                          navigatorKey.currentState!.pop(true);
                                        }
                                      });
                                    }
                                  },
                                  child: Text(
                                    'EDIT ITEM',
                                    style: TextStyle(
                                        fontSize: config.AppConfig(context)
                                            .appWidth(3.5),
                                        color: Colors.white),
                                  )),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                state.foodStatusFormStatus!.isSubmissionInProgress
                    ? const CommonProgressWidget()
                    : const SizedBox(),
              ],
            );
          },
        ),
      ),
    );
  }
}
