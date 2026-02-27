import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/model/cooking_style.dart';
import 'package:mitabl_user/model/special_diet.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/cubit/add_menu_cubit.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/elements/cooking_style_dialog.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/elements/special_diet/cubit/special_diet_cubit.dart';
import 'package:mitabl_user/pages_cook/add_menu_item/elements/special_diet/special_diet_dialog.dart';
import 'package:mitabl_user/repos/cook_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

import '../../../helper/common_progress.dart';
import '../../../helper/route_arguement.dart';
import '../../../repos/authentication_repository.dart';

class AddMenuPage extends StatefulWidget {
  AddMenuPage({Key? key, this.routeArguments}) : super(key: key);

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
        builder: (_) => AddMenuPage(
              routeArguments: routeArguments,
            ));
  }

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {

  Future<bool> _onBackPressed() async {
    context.read<AddMenuCubit>().resetFields();
    return true;
  }

  PageController? controller = PageController(viewportFraction: 0.9);
  TextEditingController itemNameController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController cookingStyleController = TextEditingController();

  @override
  void initState() {
    itemNameController.addListener(() {
      context
          .read<AddMenuCubit>()
          .onItemNameChange(value: itemNameController.text);
    });
    priceController.addListener(() {
      context.read<AddMenuCubit>().onPriceChange(value: priceController.text);
    });
    descriptionController.addListener(() {
      print('descriptionListner ${descriptionController.text}');
      context
          .read<AddMenuCubit>()
          .onDescriptionChange(value: descriptionController.text);
    });

    cookingStyleController.addListener(() {});
    cookingStyleController.text = context
        .read<AddMenuCubit>()
        .state
        .selectedCookingStyle!
        .name
        .toString();
    if (widget.routeArguments!.foodData != null) {
      CookingStyleData cookingStyleData = context
          .read<AddMenuCubit>()
          .state
          .cookingStyleList
          .firstWhere((element) =>
              element.id == widget.routeArguments!.foodData!.cookingstyle);
      cookingStyleController.text = cookingStyleData.name!;

      itemNameController.text = widget.routeArguments!.foodData!.foodName!;
      descriptionController.text =
          widget.routeArguments!.foodData!.description!;
      priceController.text = widget.routeArguments!.foodData!.price.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          // leadingWidth: config.AppConfig(context).appWidth(100),
          title: Padding(
            padding: EdgeInsets.only(
                top: config.AppConfig(context).appHeight(3), bottom: 0),
            child: InkWell(
              splashFactory: NoSplash.splashFactory,
              onTap: () {
                if (!widget.routeArguments!.isEdit!) {
                  context.read<AddMenuCubit>().resetFields();
                }
                navigatorKey.currentState!.pop();
              },
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      widget.routeArguments!.isEdit! ? 'Edit Item' : 'Add Item',
                      style: TextStyle(
                        fontFamily:
                            config.FontFamily().itcAvantGardeGothicStdFontFamily,
                        fontWeight: config.FontFamily().medium,
                        color: Theme.of(context).primaryColorDark,
                        fontSize: config.AppConfig(context).appWidth(4.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: BlocConsumer<AddMenuCubit, AddMenuState>(
            builder: (context, state) {
              return Container(
                alignment: Alignment.topCenter,
                color: Colors.white,
                height: config.AppConfig(context).appHeight(100),
                width: config.AppConfig(context).appWidth(100),
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: config.AppConfig(context).appHeight(2),
                          ),
                          Stack(
                            children: [
                              state.pathFiles.isNotEmpty
                                  ? Container(
                                      height:
                                          config.AppConfig(context).appHeight(20),
                                      child: PageView.builder(
                                        padEnds: true,
                                        clipBehavior: Clip.hardEdge,
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
                                                horizontal:
                                                    config.AppConfig(context)
                                                        .appWidth(1)),
                                            child: Stack(
                                              children: [
                                                Container(
                                                  height:
                                                      config.AppConfig(context)
                                                          .appHeight(20),
                                                  width: config.AppConfig(context)
                                                      .appWidth(100),
                                                  decoration: BoxDecoration(
                                                    color: config.AppColors()
                                                        .textFieldBackgroundColor(
                                                            1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            config.AppConfig(
                                                                    context)
                                                                .appWidth(5)),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        '${GlobalConfiguration().getValue<String>('image_base_url')}${state.pathFiles[index].path}',
                                                    errorWidget:
                                                        (context, data, e) {
                                                      return Image.file(File(state
                                                          .pathFiles[index]
                                                          .path!));
                                                    },
                                                    // errorWidget: (context, url, error) =>
                                                    //     Container(
                                                    //       color: Theme.of(context).backgroundColor,
                                                    //     ),
                                                    placeholder: (context, s) =>
                                                        Container(
                                                      color: Theme.of(context)
                                                          .backgroundColor,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                    right: 6,
                                                    top: 6,
                                                    child: InkWell(
                                                      splashFactory:
                                                          NoSplash.splashFactory,
                                                      onTap: () {
                                                        context
                                                            .read<AddMenuCubit>()
                                                            .onDeleteImage(
                                                                path: state
                                                                    .pathFiles[
                                                                        index]
                                                                    .path,
                                                                pictures: state
                                                                        .pathFiles[
                                                                    index]);
                                                      },
                                                      child: Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                        size: config.AppConfig(
                                                                context)
                                                            .appWidth(6),
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          );
                                        },
                                        itemCount: state.pathFiles.length,
                                      ),
                                    )
                                  : Padding(
                                      padding: EdgeInsets.only(
                                          left: config.AppConfig(context)
                                              .appWidth(5),
                                          right: config.AppConfig(context)
                                              .appWidth(5)),
                                      child: Container(
                                        height: config.AppConfig(context)
                                            .appHeight(20),
                                        decoration: BoxDecoration(
                                            color: config.AppColors()
                                                .textFieldBackgroundColor(1),
                                            borderRadius: BorderRadius.circular(
                                                config.AppConfig(context)
                                                    .appWidth(5))),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.photo_outlined,
                                          size: config.AppConfig(context)
                                              .appWidth(30),
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: state.pathFiles.isNotEmpty
                                    ? Container(
                                        alignment: Alignment.center,
                                        height: config.AppConfig(context)
                                            .appHeight(5),
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
                                                  color:
                                                      state.selectedPage == index
                                                          ? Colors.blue
                                                          : Colors.grey,
                                                  shape: BoxShape.circle),
                                            );
                                          },
                                          itemCount: state.pathFiles.length,
                                        ),
                                      )
                                    : SizedBox(),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: config.AppConfig(context).appHeight(2),
                                left: config.AppConfig(context).appWidth(5),
                                right: config.AppConfig(context).appWidth(5)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _UploadButton(),
                                SizedBox(
                                  height: config.AppConfig(context).appHeight(3),
                                ),
                                _ItemName(
                                  menuForm: this,
                                ),
                                SizedBox(
                                  height: config.AppConfig(context).appHeight(2),
                                ),
                                _ItemPrice(
                                  menuForm: this,
                                ),
                                SizedBox(
                                  height: config.AppConfig(context).appHeight(2),
                                ),
                                TextFormField(
                                  onTap: () {
                                    showDialog(
                                        context: context,
                                        builder: (contextB) {
                                          return BlocProvider(
                                            create: (context) => SpecialDietCubit(
                                                specialDietDataList:
                                                    state.specialDietDataList),
                                            child: SpecialDietDialog(),
                                          );
                                        }).then((value) {
                                      if (value != null) {
                                        (value as List<SpecialDietData>)
                                            .forEach((element) {
                                          context
                                              .read<AddMenuCubit>()
                                              .onSpecialDietChange(
                                                  id: element.id,
                                                  value: element.isSelected);
                                        });
                                      }
                                    });
                                  },
                                  readOnly: true,
                                  style: TextStyle(color: Colors.black),
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.name,
                                  // maxLength: 15,
                                  onChanged: (text) {},
                                  decoration: InputDecoration(
                                    suffixIcon: Icon(
                                      Icons.arrow_right,
                                      size: config.AppConfig(context).appWidth(8),
                                    ),
                                    counterText: '',
                                    hintStyle: GoogleFonts.gothicA1(
                                        color: Theme.of(context).hintColor,
                                        fontSize: config.AppConfig(context)
                                            .appWidth(4)),
                                    hintText: 'Special diet',
                                    contentPadding: EdgeInsets.only(
                                        left: config.AppConfig(context)
                                            .appWidth(5)),
                                    fillColor: config.AppColors()
                                        .textFieldBackgroundColor(1),
                                    filled: true,
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                state.specialDietDataList!
                                        .where((element) => element.isSelected!)
                                        .toList()
                                        .isNotEmpty
                                    ? Column(
                                        children: [
                                          SizedBox(
                                            height: config.AppConfig(context)
                                                .appHeight(0.5),
                                          ),
                                          Wrap(
                                            spacing: 0.0,
                                            alignment: WrapAlignment.start,
                                            children: List.generate(
                                                state.specialDietDataList!
                                                    .where((element) =>
                                                        element.isSelected!)
                                                    .toList()
                                                    .length, (index) {
                                              return Transform(
                                                transform: Matrix4.identity()
                                                  ..scale(0.85),
                                                child: Chip(
                                                  padding: EdgeInsets.zero,
                                                  labelStyle: TextStyle(
                                                    fontFamily: config
                                                            .FontFamily()
                                                        .itcAvantGardeGothicStdFontFamily,
                                                    fontWeight:
                                                        config.FontFamily().book,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                  ),
                                                  shape: StadiumBorder(
                                                      side: BorderSide(
                                                          color: Theme.of(context)
                                                              .primaryColor,
                                                          width: 0.5)),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.2),
                                                  label: Text(
                                                    state.specialDietDataList!
                                                                .where((element) =>
                                                                    element
                                                                        .isSelected!)
                                                                .toList()[index]
                                                                .name!
                                                                .length >
                                                            15
                                                        ? state.specialDietDataList!
                                                                .where((element) =>
                                                                    element
                                                                        .isSelected!)
                                                                .toList()[index]
                                                                .name!
                                                                .substring(
                                                                    0, 14) +
                                                            '...'
                                                        : state
                                                            .specialDietDataList!
                                                            .where((element) =>
                                                                element
                                                                    .isSelected!)
                                                            .toList()[index]
                                                            .name!,
                                                    style: TextStyle(
                                                        fontFamily: config
                                                                .FontFamily()
                                                            .itcAvantGardeGothicStdFontFamily,
                                                        fontWeight:
                                                            config.FontFamily()
                                                                .book,
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                    maxLines: 1,
                                                    softWrap: true,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  onDeleted: () {
                                                    context
                                                        .read<AddMenuCubit>()
                                                        .onDeleteSpecialDiet(
                                                            id: state
                                                                .specialDietDataList!
                                                                .where((element) =>
                                                                    element
                                                                        .isSelected!)
                                                                .toList()[index]
                                                                .id);
                                                  },
                                                  deleteIcon: Container(
                                                    height:
                                                        config.AppConfig(context)
                                                            .appHeight(1.5),
                                                    width:
                                                        config.AppConfig(context)
                                                            .appHeight(1.5),
                                                    padding: EdgeInsets.all(
                                                        config.AppConfig(context)
                                                            .appWidth(0)),
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                        borderRadius: BorderRadius
                                                            .all(Radius.circular(
                                                                config.AppConfig(
                                                                        context)
                                                                    .appWidth(
                                                                        10))),
                                                        border: Border.all(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor)),
                                                    child: Icon(
                                                      Icons.clear,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      size: config.AppConfig(
                                                              context)
                                                          .appWidth(2.5),
                                                    ),
                                                  ),
                                                ),
                                              );

                                              Stack(
                                                children: [
                                                  Container(
                                                    height:
                                                        config.AppConfig(context)
                                                            .appHeight(4),
                                                    padding: EdgeInsets.all(
                                                        config.AppConfig(context)
                                                            .appWidth(0)),
                                                    decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withOpacity(0.2),
                                                        borderRadius: BorderRadius.all(
                                                            Radius.circular(
                                                                config.AppConfig(
                                                                        context)
                                                                    .appWidth(
                                                                        5))),
                                                        border: Border.all(
                                                            color: Theme.of(context)
                                                                .primaryColor)),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      state.specialDietDataList!
                                                          .where((element) =>
                                                              element.isSelected!)
                                                          .toList()[index]
                                                          .name!,
                                                      style: TextStyle(
                                                          fontFamily: config
                                                                  .FontFamily()
                                                              .itcAvantGardeGothicStdFontFamily,
                                                          fontWeight:
                                                              config.FontFamily()
                                                                  .book,
                                                          color: Theme.of(context)
                                                              .primaryColor),
                                                      maxLines: 1,
                                                      softWrap: true,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 5,
                                                    right: 5,
                                                    child: InkWell(
                                                      splashFactory:
                                                          NoSplash.splashFactory,
                                                      onTap: () {
                                                        print('delete Chip');
                                                        context
                                                            .read<AddMenuCubit>()
                                                            .onDeleteSpecialDiet(
                                                                id: state
                                                                    .specialDietDataList!
                                                                    .where((element) =>
                                                                        element
                                                                            .isSelected!)
                                                                    .toList()[
                                                                        index]
                                                                    .id);
                                                      },
                                                      child: Container(
                                                        height: config.AppConfig(
                                                                context)
                                                            .appHeight(1.5),
                                                        width: config.AppConfig(
                                                                context)
                                                            .appHeight(1.5),
                                                        padding: EdgeInsets.all(
                                                            config.AppConfig(
                                                                    context)
                                                                .appWidth(0)),
                                                        alignment:
                                                            Alignment.center,
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.all(
                                                                Radius.circular(
                                                                    config.AppConfig(
                                                                            context)
                                                                        .appWidth(
                                                                            10))),
                                                            border: Border.all(
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor)),
                                                        child: Icon(
                                                          Icons.clear,
                                                          color: Theme.of(context)
                                                              .primaryColor,
                                                          size: config.AppConfig(
                                                                  context)
                                                              .appWidth(2.5),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ),
                                          SizedBox(
                                            height: config.AppConfig(context)
                                                .appHeight(0.5),
                                          ),
                                          // GridView.count(
                                          //   shrinkWrap: true,
                                          //   physics:
                                          //       NeverScrollableScrollPhysics(),
                                          //   crossAxisCount: 3,
                                          //   childAspectRatio: 2.4,
                                          //   mainAxisSpacing: 2,
                                          //   crossAxisSpacing: 2,
                                          //   padding: EdgeInsets.all(
                                          //       config.AppConfig(context)
                                          //           .appWidth(1)),
                                          //   children: List.generate(
                                          //       state.specialDietDataList!
                                          //           .where((element) =>
                                          //               element.isSelected!)
                                          //           .toList()
                                          //           .length, (index) {
                                          //     return Stack(
                                          //       children: [
                                          //         Container(
                                          //           height:
                                          //               config.AppConfig(context)
                                          //                   .appHeight(4),
                                          //           padding: EdgeInsets.all(
                                          //               config.AppConfig(context)
                                          //                   .appWidth(0)),
                                          //           decoration: BoxDecoration(
                                          //               color: Theme.of(context)
                                          //                   .primaryColor
                                          //                   .withOpacity(0.2),
                                          //               borderRadius: BorderRadius.all(
                                          //                   Radius.circular(
                                          //                       config.AppConfig(
                                          //                               context)
                                          //                           .appWidth(
                                          //                               5))),
                                          //               border: Border.all(
                                          //                   color: Theme.of(context)
                                          //                       .primaryColor)),
                                          //           alignment: Alignment.center,
                                          //           child: Text(
                                          //             state.specialDietDataList!
                                          //                 .where((element) =>
                                          //                     element.isSelected!)
                                          //                 .toList()[index]
                                          //                 .name!,
                                          //             style: TextStyle(
                                          //                 fontFamily: config
                                          //                         .FontFamily()
                                          //                     .itcAvantGardeGothicStdFontFamily,
                                          //                 fontWeight:
                                          //                     config.FontFamily()
                                          //                         .book,
                                          //                 color: Theme.of(context)
                                          //                     .primaryColor),
                                          //             maxLines: 1,
                                          //             softWrap: true,
                                          //             overflow:
                                          //                 TextOverflow.ellipsis,
                                          //           ),
                                          //         ),
                                          //         Positioned(
                                          //           top: 5,
                                          //           right: 5,
                                          //           child: InkWell(
                                          //             splashFactory:
                                          //                 NoSplash.splashFactory,
                                          //             onTap: () {
                                          //               print('delete Chip');
                                          //               context
                                          //                   .read<AddMenuCubit>()
                                          //                   .onDeleteSpecialDiet(
                                          //                       id: state
                                          //                           .specialDietDataList!
                                          //                           .where((element) =>
                                          //                               element
                                          //                                   .isSelected!)
                                          //                           .toList()[
                                          //                               index]
                                          //                           .id);
                                          //             },
                                          //             child: Container(
                                          //               height: config.AppConfig(
                                          //                       context)
                                          //                   .appHeight(1.5),
                                          //               width: config.AppConfig(
                                          //                       context)
                                          //                   .appHeight(1.5),
                                          //               padding: EdgeInsets.all(
                                          //                   config.AppConfig(
                                          //                           context)
                                          //                       .appWidth(0)),
                                          //               alignment:
                                          //                   Alignment.center,
                                          //               decoration: BoxDecoration(
                                          //                   borderRadius: BorderRadius.all(
                                          //                       Radius.circular(
                                          //                           config.AppConfig(
                                          //                                   context)
                                          //                               .appWidth(
                                          //                                   10))),
                                          //                   border: Border.all(
                                          //                       color: Theme.of(
                                          //                               context)
                                          //                           .primaryColor)),
                                          //               child: Icon(
                                          //                 Icons.clear,
                                          //                 color: Theme.of(context)
                                          //                     .primaryColor,
                                          //                 size: config.AppConfig(
                                          //                         context)
                                          //                     .appWidth(2.5),
                                          //               ),
                                          //             ),
                                          //           ),
                                          //         ),
                                          //       ],
                                          //     );
                                          //   }),
                                          // ),
                                        ],
                                      )
                                    : SizedBox(),
                                SizedBox(
                                  height: config.AppConfig(context).appHeight(2),
                                ),
                                TextFormField(
                                  onTap: () {
                                    showDialog(
                                        context: context,
                                        builder: (contextB) {
                                          return CookingStyleDialog();
                                        }).then((value) {
                                      cookingStyleController.text = context
                                          .read<AddMenuCubit>()
                                          .state
                                          .selectedCookingStyle!
                                          .name
                                          .toString();
                                    });
                                  },
                                  controller: cookingStyleController,
                                  readOnly: true,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize:
                                          config.AppConfig(context).appWidth(4)),
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.name,
                                  // maxLength: 15,
                                  onChanged: (text) {},
                                  decoration: InputDecoration(
                                    suffixIcon: Icon(
                                      Icons.arrow_right,
                                      size: config.AppConfig(context).appWidth(8),
                                    ),
                                    counterText: '',
                                    hintStyle: GoogleFonts.gothicA1(
                                        color: Theme.of(context).hintColor,
                                        fontSize: config.AppConfig(context)
                                            .appWidth(4)),
                                    hintText: 'Cooking style',
                                    contentPadding: EdgeInsets.only(
                                        left: config.AppConfig(context)
                                            .appWidth(5)),
                                    fillColor: config.AppColors()
                                        .textFieldBackgroundColor(1),
                                    filled: true,
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: config.AppConfig(context).appHeight(2),
                                ),
                                _ItemDescription(
                                  menuForm: this,
                                ),
                                SizedBox(
                                  height: config.AppConfig(context).appHeight(2),
                                ),
                                Container(
                                  height: 45,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.topRight,
                                          colors: state.formzStatus!.isValidated
                                              ? [
                                                  Theme.of(context).primaryColor,
                                                  Theme.of(context).primaryColor,
                                                ]
                                              : [
                                                  Colors.grey,
                                                  Colors.grey,
                                                  Colors.grey
                                                ])),
                                  child: MaterialButton(
                                      child: /* state.addFoodStatus!
                                              .isSubmissionInProgress
                                          ? Center(
                                              child: CupertinoActivityIndicator())
                                          :*/
                                          Text(
                                        widget.routeArguments!.isEdit!
                                            ? 'UPDATE'
                                            : 'SAVE',
                                        style: GoogleFonts.gothicA1(
                                            fontSize: config.AppConfig(context)
                                                .appWidth(3.5),
                                            color: Colors.white),
                                      ),
                                      minWidth:
                                          config.AppConfig(context).appWidth(100),
                                      height: 50.0,
                                      onPressed: () {
                                        if (state.formzStatus!.isValidated) {
                                          if (state.pathFiles.isNotEmpty) {
                                            if (state.specialDietDataList!
                                                .firstWhere(
                                                    (element) =>
                                                        element.isSelected!,
                                                    orElse: () {
                                              return SpecialDietData(
                                                  isSelected: false);
                                            }).isSelected!) {
                                              if (state.selectedCookingStyle!
                                                          .isSelected !=
                                                      null &&
                                                  state.selectedCookingStyle!
                                                      .isSelected!) {
                                                context
                                                    .read<AddMenuCubit>()
                                                    .onAddFood(
                                                        isEdit: widget
                                                            .routeArguments!
                                                            .isEdit!,
                                                        foodId: widget
                                                                    .routeArguments!
                                                                    .foodData !=
                                                                null
                                                            ? widget
                                                                .routeArguments!
                                                                .foodData!
                                                                .id
                                                                .toString()
                                                            : '');
                                              } else {
                                                Helper.showToast(
                                                    'Please select cooking style');
                                              }
                                            } else {
                                              Helper.showToast(
                                                  'Please select special diet');
                                            }
                                          } else {
                                            Helper.showToast(
                                                'Please upload images');
                                          }
                                        }
                                      }),
                                ),
                                SizedBox(
                                  height: config.AppConfig(context).appHeight(2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    state.addFoodStatus!.isSubmissionInProgress
                        ? CommonProgressWidget()
                        : SizedBox(),
                  ],
                ),
              );
            },
            listener: (context, state) {}),
      ),
    );
  }
}

class _ItemName extends StatefulWidget {
  final _AddMenuPageState? menuForm;

  const _ItemName({Key? key, this.menuForm}) : super(key: key);

  @override
  State<_ItemName> createState() => _ItemNameState();
}

class _ItemNameState extends State<_ItemName> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMenuCubit, AddMenuState>(builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          controller: widget.menuForm!.itemNameController,
          style: TextStyle(
              color: Colors.black,
              fontSize: config.AppConfig(context).appWidth(4)),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          // maxLength: 15,
          onChanged: (text) {},
          decoration: InputDecoration(
            counterText: '',
            errorText:
                state.itemName!.invalid ? 'Please enter a valid name' : null,

            hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4)),
            // labelText: 'Mobile Number',
            hintText: 'Item name',
            contentPadding: EdgeInsets.symmetric(
              horizontal: config.AppConfig(context).appWidth(5),
            ),
            fillColor: config.AppColors().textFieldBackgroundColor(1),
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            border: InputBorder.none,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }
}

/////\\\\\
class _ItemPrice extends StatefulWidget {
  final _AddMenuPageState? menuForm;

  const _ItemPrice({Key? key, this.menuForm}) : super(key: key);

  @override
  State<_ItemPrice> createState() => _ItemPriceState();
}

class _ItemPriceState extends State<_ItemPrice> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMenuCubit, AddMenuState>(builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          controller: widget.menuForm!.priceController,
          style: TextStyle(
              color: Colors.black,
              fontSize: config.AppConfig(context).appWidth(4)),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          // maxLength: 15,
          onChanged: (text) {},
          decoration: InputDecoration(
            counterText: '',
            errorText:
                state.price!.invalid ? 'Please enter a valid price' : null,

            hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4)),
            // labelText: 'Mobile Number',
            hintText: 'Price',
            contentPadding: EdgeInsets.symmetric(
              horizontal: config.AppConfig(context).appWidth(5),
            ),
            fillColor: config.AppColors().textFieldBackgroundColor(1),
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            border: InputBorder.none,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }
}
////\\\\\\

class _ItemDescription extends StatefulWidget {
  final _AddMenuPageState? menuForm;

  const _ItemDescription({Key? key, this.menuForm}) : super(key: key);

  @override
  State<_ItemDescription> createState() => _ItemDescriptionState();
}

class _ItemDescriptionState extends State<_ItemDescription> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMenuCubit, AddMenuState>(builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          controller: widget.menuForm!.descriptionController,
          style: TextStyle(
              color: Colors.black,
              fontSize: config.AppConfig(context).appWidth(4)),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          // maxLength: 15,
          maxLines: 5,
          onChanged: (text) {},
          decoration: InputDecoration(
            counterText: '',
            errorText: state.description!.invalid
                ? 'Please enter a valid description'
                : null,

            hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4)),
            // labelText: 'Mobile Number',
            hintText: 'Description',
            contentPadding: EdgeInsets.symmetric(
                horizontal: config.AppConfig(context).appWidth(5),
                vertical: config.AppConfig(context).appWidth(5)
                // top: config.AppConfig(context).appWidth(5),
                //   left:config.AppConfig(context).appWidth(5),

                ),
            fillColor: config.AppColors().textFieldBackgroundColor(1),
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            border: InputBorder.none,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }
}

/////

class _UploadButton extends StatefulWidget {
  const _UploadButton({Key? key, this.loginForm}) : super(key: key);

  final _AddMenuPageState? loginForm;

  @override
  _UploadbuttonState createState() => _UploadbuttonState();
}

class _UploadbuttonState extends State<_UploadButton> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddMenuCubit, AddMenuState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Container(
          // alignment: Alignment.center,
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
                'Upload Photos',
                style: TextStyle(
                  fontFamily:
                      config.FontFamily().itcAvantGardeGothicStdFontFamily,
                  fontSize: config.AppConfig(context).appWidth(3.5),
                  color: Colors.white,
                  fontWeight: config.FontFamily().book,
                ),
              ),
              minWidth: config.AppConfig(context).appWidth(80),
              height: 50.0,
              onPressed: () {
                // _pickImage();

                if (state.pathFiles.length <= 4) {
                  showDialog<bool>(
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                'Add image',
                                style: GoogleFonts.gothicA1(
                                    color: Colors.black,
                                    fontSize:
                                        config.AppConfig(context).appWidth(5)),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MaterialButton(
                                    color: Theme.of(context).primaryColor,
                                    child: const Text(
                                      "Gallery",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      navigatorKey.currentState!.pop(false);
                                    },
                                  ),
                                  MaterialButton(
                                    color: Theme.of(context).primaryColor,
                                    child: const Text(
                                      "Camera",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      navigatorKey.currentState!.pop(true);
                                    },
                                  )
                                ],
                              ),
                            );
                          },
                          context: context)
                      .then((value) {
                    if (value != null) {
                      if (value) {
                        //Get from camera
                        _openCamera(context);
                      } else {
                        //Get from gallery
                        _openGallery(context);
                      }
                    }
                  });
                } else {
                  Helper.showToast('Photos limit reached.');
                }
              }),
        );
      },
    );
  }

  void _openGallery(BuildContext context) async {
    var picture = await ImagePicker().pickImage(source: ImageSource.gallery);
    // print('path ${picture!.path}');
    try {
      if (picture!.path.isNotEmpty) {
        print('path ${picture.path}');
        context.read<AddMenuCubit>().onNewImageAdded(path: picture.path);
        // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.loginForm!.controller!
            .jumpTo(widget.loginForm!.controller!.position.maxScrollExtent);
        //});
      } else {
        Helper.showToast('No image selected.');
      }
    } catch (e) {
      //Helper.showToast('No image selected.');
    }
  }

  Future<void> _openCamera(BuildContext context) async {
    var picture = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 50);

    try {
      if (picture!.path.isNotEmpty) {
        print('path ${picture.path}');
        context.read<AddMenuCubit>().onNewImageAdded(path: picture.path);
        // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.loginForm!.controller!
            .jumpTo(widget.loginForm!.controller!.position.maxScrollExtent);
        // });
        // widget.loginForm!.controller!.animateTo(context.read<EditKitchenProfileCubit>().state.pathFiles.length.toDouble(), duration: Duration(milliseconds: 100 ), curve: Curves.ease);

      } else {
        Helper.showToast('No image captured.');
      }
    } catch (e) {
      //Helper.showToast('No image captured.');
    }
  }
}
