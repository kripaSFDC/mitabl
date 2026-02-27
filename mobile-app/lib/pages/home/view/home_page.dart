import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_appbar.dart';
import 'package:mitabl_user/helper/helper.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/pages/home/cubit/home_cubit.dart';
import 'package:mitabl_user/pages/home/element/filter_dialog.dart';
import 'package:mitabl_user/pages/home/element/near_by_restaurant.dart';
import 'package:mitabl_user/pages/home/element/recomm_rest_widget.dart';
import 'package:mitabl_user/pages/home/element/top_rated.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/pages_cook/dashboard_cook/view/dashboard_cook_page.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
              create: (context) => HomeCubit(
                  authenticationRepository:
                      context.read<AuthenticationRepository>(),
                  userRepository: context.read<UserRepository>()),
              child: HomePage(),
            ));
    // );
  }

  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  _HomePage();

  UserModel? userModel;

  @override
  void initState() {
    // setUpFields();

    new UserRepository().getUser().then((value) => userModel = value);
    context.read<ProfileFoodieCubit>().getFoodieProfile();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    return Scaffold(
      body: BlocConsumer<HomeCubit, HomeState>(builder: (context, state) {
        return Container(
          color: Colors.white,
          height: config.AppConfig(context).appHeight(100),
          width: config.AppConfig(context).appWidth(100),
          child: Padding(
            padding: EdgeInsets.only(
                left: config.AppConfig(context).appWidth(2),
                right: config.AppConfig(context).appWidth(2)),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: config.AppConfig(context).appHeight(1),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          child: _FirstName(
                            homePage: this,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => {
                          showDialog(
                              context: context,
                              builder: (contexts) {
                                return BlocProvider.value(
                                  value: context.read<HomeCubit>(),
                                  child: FilterDialog(),
                                );
                              })
                        },
                        icon: SvgPicture.asset(
                          'assets/img/filter.svg',
                          height: config.AppConfig(context).appHeight(2.0),
                        ),
                      )
                    ],
                  ),
                  ListTile(
                      contentPadding: EdgeInsets.only(
                          left: config.AppConfig(context).appHeight(1),
                          right: config.AppConfig(context).appHeight(1)),
                      title: Text(
                        'mitabl recommended',
                        style: GoogleFonts.gothicA1(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: config.AppConfig(context).appWidth(5)),
                      )),
                  state.statusRecommRes!.isSubmissionInProgress
                      ? Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        )
                      : CarouselSlider(
                          options: CarouselOptions(
                            height: config.AppConfig(context).appHeight(28.0),
                            initialPage: 0,
                            aspectRatio: 2.0,
                            enableInfiniteScroll: true,
                            reverse: false,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration:
                                Duration(milliseconds: 1000),
                            enlargeCenterPage: true,
                            autoPlayCurve: Curves.fastOutSlowIn,
                          ),
                          items: state.recommendedRestResponse!
                              .recommendedResturantList!
                              .map((item) {
                            return Builder(
                              builder: (BuildContext context) {
                                return RecommendedRestWidget(
                                  recommendedResturant: item,
                                );
                              },
                            );
                          }).toList(),
                        ),
                  ListTile(
                      contentPadding: EdgeInsets.only(
                          left: config.AppConfig(context).appHeight(1),
                          right: config.AppConfig(context).appHeight(1)),
                      title: Text(
                        'top rated',
                        style: GoogleFonts.gothicA1(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: config.AppConfig(context).appWidth(5)),
                      )),
                  state.statusTopRes!.isSubmissionInProgress
                      ? Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        )
                      : TopRatedWidget(
                          topReatedRestList: state
                              .topReatedRestResponse!.data!.topReatedRestList,
                        ),
                  ListTile(
                      contentPadding: EdgeInsets.only(
                          left: config.AppConfig(context).appHeight(1),
                          right: config.AppConfig(context).appHeight(1)),
                      title: Text(
                        'micook near my location',
                        style: GoogleFonts.gothicA1(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: config.AppConfig(context).appWidth(5)),
                      )),
                  state.statusApi!.isSubmissionInProgress
                      ? Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.grey,
                          ),
                        )
                      : NearByRestaurants(
                          nearByRestaurantsList: state
                              .nearByRestaurants?.data!.nearByRestaurantsList),
                  // _LoginButton(
                  //   loginForm: this,
                  // ),
                ],
              ),
            ),
          ),
        );
      }, listener: (context, state) async {
        print('status form ${state.statusApi}');
        // if (state.statusApi!.isSubmissionFailure) {
        //   ScaffoldMessenger.of(context)
        //       .showSnackBar(SnackBar(content: Text('${state.serverMessage}')));
        // }
      }),
    );
  }
}

class _FirstName extends StatefulWidget {
  final _HomePage? homePage;

  const _FirstName({Key? key, this.homePage}) : super(key: key);

  @override
  State<_FirstName> createState() => _FirstNameState();
}

class _FirstNameState extends State<_FirstName> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(builder: (context, state) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        child: TextFormField(
          // controller: widget.loginForm!.mobileNoTextEditor,
          style: TextStyle(color: Colors.black),
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          maxLength: 15,
          onChanged: (text) {},
          decoration: InputDecoration(
            counterText: '',
            // errorText: state.nameFirst!.invalid
            //     ? 'Please enter a valid first name'
            //     : null,

            suffixIcon: Container(
              padding: EdgeInsets.all(14.0),
              child: SvgPicture.asset(
                'assets/img/search.svg',
                height: config.AppConfig(context).appHeight(2.0),
              ),
            ),
            hintStyle: GoogleFonts.gothicA1(
                color: Theme.of(context).hintColor,
                fontSize: config.AppConfig(context).appWidth(4)),
            // labelText: 'Mobile Number',
            hintText: '492 Morissette Roads',
            contentPadding:
                EdgeInsets.all(config.AppConfig(context).appWidth(2)),
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

class _LoginButton extends StatelessWidget {
  final _HomePage? loginForm;

  const _LoginButton({Key? key, this.loginForm}) : super(key: key);

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
                      'Logout',
                      style: GoogleFonts.gothicA1(
                          fontSize: config.AppConfig(context).appWidth(3.5),
                          color: Colors.white),
                    ),
              minWidth: config.AppConfig(context).appWidth(100),
              height: 50.0,
              onPressed: () {
                // context.read<HomeCubit>().doLogout();
              }),
        );
      },
    );
  }
}
