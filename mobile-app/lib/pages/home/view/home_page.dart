import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/pages/home/cubit/home_cubit.dart';
import 'package:mitabl_user/pages/home/element/filter_dialog.dart';
import 'package:mitabl_user/pages/home/element/near_by_restaurant.dart';
import 'package:mitabl_user/pages/home/element/recomm_rest_widget.dart';
import 'package:mitabl_user/pages/home/element/top_rated.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/repos/cook_repository.dart';
import 'package:mitabl_user/repos/home_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (context) => HomeRepository(
              httpClient: context.read<UserRepository>().httpClient,
            ),
            dispose: (repository) => repository.dispose(),
          ),
          RepositoryProvider(
            create: (context) => CookRepository(
              context.read<UserRepository>(),
              httpClient: context.read<UserRepository>().httpClient,
            ),
            dispose: (repository) => repository.dispose(),
          ),
        ],
        child: BlocProvider(
          create: (context) => HomeCubit(
            repo: context.read<UserRepository>(),
            homeRepository: context.read<HomeRepository>(),
            cookRepository: context.read<CookRepository>(),
          ),
          child: const HomePage(),
        ),
      );
    });
  }

  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController()..addListener(_handleScroll);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    context.read<ProfileFoodieCubit>().getFoodieProfile();
    super.initState();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.extentAfter < 320) {
      context.read<HomeCubit>().loadMoreNearBy();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<HomeCubit, HomeState>(
          builder: (context, state) {
            return Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: config.AppConfig(context).appWidth(2)),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                          height: config.AppConfig(context).appHeight(1)),
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
                                    child: const FilterDialog(),
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
                    const _SectionTitle(title: 'mitabl recommended'),
                    SliverToBoxAdapter(
                      child: state.statusRecommRes!.isSubmissionInProgress
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                  color: Colors.grey))
                          : (() {
                              final recommendedItems = state
                                      .recommendedRestResponse
                                      ?.recommendedResturantList ??
                                  const [];
                              return CarouselSlider(
                                options: CarouselOptions(
                                  height:
                                      config.AppConfig(context).appHeight(28.0),
                                  initialPage: 0,
                                  aspectRatio: 2.0,
                                  enableInfiniteScroll: true,
                                  autoPlay: recommendedItems.length > 1,
                                  autoPlayInterval: const Duration(seconds: 3),
                                  autoPlayAnimationDuration:
                                      const Duration(milliseconds: 1000),
                                  enlargeCenterPage: true,
                                  autoPlayCurve: Curves.fastOutSlowIn,
                                ),
                                items: recommendedItems
                                    .map((item) => RecommendedRestWidget(
                                          recommendedResturant: item,
                                        ))
                                    .toList(),
                              );
                            })(),
                    ),
                    const _SectionTitle(title: 'top rated restaurants'),
                    SliverToBoxAdapter(
                      child: state.statusTopRes!.isSubmissionInProgress
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                  color: Colors.grey),
                            )
                          : TopRatedWidget(
                              canLoadMore: state.hasMoreTopRated,
                              isLoadingMore: state.isLoadingMoreTopRated,
                              onLoadMore:
                                  context.read<HomeCubit>().loadMoreTopRated,
                              topReatedRestList: state.topReatedRestResponse
                                  ?.data?.topReatedRestList),
                    ),
                    const _SectionTitle(title: 'micook near my location'),
                    SliverToBoxAdapter(
                      child: state.statusApi!.isSubmissionInProgress
                          ? const Center(
                              child: CupertinoActivityIndicator(
                                  color: Colors.grey),
                            )
                          : NearByRestaurants(
                              nearByRestaurantsList: state.nearByRestaurants
                                  ?.data?.nearByRestaurantsList),
                    ),
                    if (state.isLoadingMoreNearBy)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child:
                                CupertinoActivityIndicator(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          listener: (context, state) async {}),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            style: const TextStyle(color: Colors.black),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            onChanged: context.read<HomeCubit>().onLocationQueryChanged,
            onFieldSubmitted: (_) =>
                context.read<HomeCubit>().onLocationSubmitted(),
            decoration: InputDecoration(
              suffixIconConstraints: const BoxConstraints(minWidth: 88),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Use current location',
                    onPressed: state.isResolvingLocation
                        ? null
                        : context.read<HomeCubit>().onUseCurrentLocation,
                    icon: state.isResolvingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CupertinoActivityIndicator(color: Colors.grey),
                          )
                        : Icon(
                            Icons.my_location_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                  ),
                  IconButton(
                    onPressed: context.read<HomeCubit>().onLocationSubmitted,
                    icon: SvgPicture.asset(
                      'assets/img/search.svg',
                      height: config.AppConfig(context).appHeight(2.0),
                    ),
                  ),
                ],
              ),
              hintStyle: GoogleFonts.gothicA1(
                  color: Theme.of(context).hintColor,
                  fontSize: config.AppConfig(context).appWidth(4)),
              hintText: 'latitude, longitude',
              helperText: 'Use current location or enter coordinates',
              contentPadding:
                  EdgeInsets.all(config.AppConfig(context).appWidth(2)),
              fillColor: config.AppColors().textFieldBackgroundColor(1),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if ((state.locationLabel ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                state.locationLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.gothicA1(
                  color: Theme.of(context).primaryColorDark,
                  fontSize: config.AppConfig(context).appWidth(3.2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    });
  }
}
