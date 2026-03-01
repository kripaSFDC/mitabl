import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/pages/home/cubit/home_cubit.dart';
import 'package:mitabl_user/pages/home/element/filter_dialog.dart';
import 'package:mitabl_user/pages/home/element/near_by_restaurant.dart';
import 'package:mitabl_user/pages/home/element/recomm_rest_widget.dart';
import 'package:mitabl_user/pages/home/element/top_rated.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
              create: (context) => HomeCubit(
                  userRepository: context.read<UserRepository>()),
              child: const HomePage(),
            ));
  }

  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  @override
  void initState() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    context.read<ProfileFoodieCubit>().getFoodieProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<HomeCubit, HomeState>(builder: (context, state) {
        return Container(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: config.AppConfig(context).appWidth(2)),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: config.AppConfig(context).appHeight(1)),
                ),
                SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: _LocationInput()),
                      IconButton(
                        onPressed: () => showDialog(
                            context: context,
                            builder: (contexts) {
                              return BlocProvider.value(
                                value: context.read<HomeCubit>(),
                                child: FilterDialog(),
                              );
                            }),
                        icon: SvgPicture.asset(
                          'assets/img/filter.svg',
                          height: config.AppConfig(context).appHeight(2.0),
                        ),
                      )
                    ],
                  ),
                ),
                _SectionTitle(title: 'mitabl recommended'),
                SliverToBoxAdapter(
                  child: state.statusRecommRes!.isSubmissionInProgress
                      ? const Center(
                          child: CupertinoActivityIndicator(color: Colors.grey))
                      : CarouselSlider(
                          options: CarouselOptions(
                            height: config.AppConfig(context).appHeight(28.0),
                            initialPage: 0,
                            aspectRatio: 2.0,
                            enableInfiniteScroll: true,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 3),
                            autoPlayAnimationDuration:
                                const Duration(milliseconds: 1000),
                            enlargeCenterPage: true,
                            autoPlayCurve: Curves.fastOutSlowIn,
                          ),
                          items: (state.recommendedRestResponse
                                      ?.recommendedResturantList ??
                                  const [])
                              .map((item) => RecommRestWidget(data: item))
                              .toList(),
                        ),
                ),
                _SectionTitle(title: 'top rated restaurants'),
                SliverToBoxAdapter(
                  child: state.statusTopRes!.isSubmissionInProgress
                      ? const Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
                        )
                      : TopRatedWidget(
                          topReatedRestList: state.topReatedRestResponse?.data
                              ?.topReatedRestList),
                ),
                _SectionTitle(title: 'micook near my location'),
                SliverToBoxAdapter(
                  child: state.statusApi!.isSubmissionInProgress
                      ? const Center(
                          child: CupertinoActivityIndicator(color: Colors.grey),
                        )
                      : NearByRestaurants(
                          nearByRestaurantsList:
                              state.nearByRestaurants?.data?.nearByRestaurantsList),
                ),
              ],
            ),
          ),
        );
      }, listener: (context, state) async {}),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ListTile(
          contentPadding: EdgeInsets.only(
              left: config.AppConfig(context).appHeight(1),
              right: config.AppConfig(context).appHeight(1)),
          title: Text(
            title,
            style: GoogleFonts.gothicA1(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: config.AppConfig(context).appWidth(5)),
          )),
    );
  }
}

class _LocationInput extends StatefulWidget {
  const _LocationInput();

  @override
  State<_LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<_LocationInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(builder: (context, state) {
      if (_controller.text != state.locationQuery) {
        final value = state.locationQuery ?? '';
        _controller.value = _controller.value.copyWith(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
          composing: TextRange.empty,
        );
      }
      return TextFormField(
        controller: _controller,
        style: const TextStyle(color: Colors.black),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: context.read<HomeCubit>().onLocationQueryChanged,
        onFieldSubmitted: (_) => context.read<HomeCubit>().onLocationSubmitted(),
        decoration: InputDecoration(
          suffixIcon: IconButton(
            onPressed: context.read<HomeCubit>().onLocationSubmitted,
            icon: SvgPicture.asset(
              'assets/img/search.svg',
              height: config.AppConfig(context).appHeight(2.0),
            ),
          ),
          hintStyle: GoogleFonts.gothicA1(
              color: Theme.of(context).hintColor,
              fontSize: config.AppConfig(context).appWidth(4)),
          hintText: 'latitude, longitude',
          helperText: 'Enter coordinates and tap search',
          contentPadding: EdgeInsets.all(config.AppConfig(context).appWidth(2)),
          fillColor: config.AppColors().textFieldBackgroundColor(1),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      );
    });
  }
}
