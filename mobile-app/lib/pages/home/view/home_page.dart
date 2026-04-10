import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/formz_compat.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/cooking_style.dart';
import 'package:mitabl_user/model/near_by_restaurants_response.dart';
import 'package:mitabl_user/pages/home/cubit/home_cubit.dart';
import 'package:mitabl_user/pages/home/element/discovery_category_pills.dart';
import 'package:mitabl_user/pages/home/element/discovery_cook_card.dart';
import 'package:mitabl_user/pages/home/view/search_filters_page.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/pages/profile_foodie/cubit/profile_foodie_cubit.dart';
import 'package:mitabl_user/repos/cook_repository.dart';
import 'package:mitabl_user/repos/favourites_repository.dart';
import 'package:mitabl_user/repos/home_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) {
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
      },
    );
  }

  @override
  State<StatefulWidget> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  late final ScrollController _scrollController;
  late final FavouritesRepository _favouritesRepository;
  final Set<int> _favouritedIds = {};

  @override
  void initState() {
    _scrollController = ScrollController()..addListener(_handleScroll);
    _favouritesRepository = FavouritesRepository();
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
    _favouritesRepository.dispose();
    super.dispose();
  }

  Future<void> _toggleFavourite(int kitchenId) async {
    final wasAlreadyFavourited = _favouritedIds.contains(kitchenId);
    setState(() {
      if (wasAlreadyFavourited) {
        _favouritedIds.remove(kitchenId);
      } else {
        _favouritedIds.add(kitchenId);
      }
    });
    try {
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      await _favouritesRepository.toggleFavourite(
        userModel: userModel,
        targetId: kitchenId.toString(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasAlreadyFavourited) {
          _favouritedIds.add(kitchenId);
        } else {
          _favouritedIds.remove(kitchenId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update favourites right now.'),
        ),
      );
    }
  }

  String _greetingLabel() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String _firstName(BuildContext context) {
    try {
      final profileState = context.read<ProfileFoodieCubit>().state;
      final name = profileState.firstName?.value;
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {
      // ProfileFoodieCubit might not be available yet
    }
    return '';
  }

  void _navigateToOrderMenu(BuildContext context, int kitchenId) {
    Navigator.of(context).pushNamed(
      '/OrderMenu',
      arguments: RouteArguments(
        data: OrderRouteData(kitchenId: kitchenId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // background-light
      body: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) async {},
        builder: (context, state) {
          final recommendedItems =
              state.recommendedRestResponse?.recommendedResturantList ??
                  const [];
          final nearByItems =
              state.nearByRestaurants?.data?.nearByRestaurantsList ??
                  const [];
          final totalFeedCount =
              recommendedItems.length + nearByItems.length;

          final firstName = _firstName(context);
          final greetingName = firstName.isNotEmpty ? ', $firstName' : '';

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sticky header
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.95),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A)
                            .withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Greeting row with notification button
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_greetingLabel()}$greetingName',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    context.read<HomeCubit>().onUseCurrentLocation();
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          (state.locationLabel ?? '').isNotEmpty
                                              ? state.locationLabel!
                                              : 'Set location',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.expand_more,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Notification button
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed('/Notifications'),
                            child: Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF), // surface
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F172A)
                                          .withValues(alpha: 0.06),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              // Red notification dot
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEA580C), // primary
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFFFFFF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Search bar
                      GestureDetector(
                        onTap: () async {
                          final result =
                              await Navigator.of(context).push<List<int>>(
                            MaterialPageRoute<List<int>>(
                              builder: (_) => BlocProvider.value(
                                value: context.read<HomeCubit>(),
                                child: const SearchFiltersPage(),
                              ),
                            ),
                          );
                          if (result != null &&
                              result.isNotEmpty &&
                              context.mounted) {
                            debugPrint('Selected diet IDs: $result');
                          }
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A)
                                    .withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.search,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'What are you craving?',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Category pills (sticky)
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryPillsDelegate(
                  categories: state.cookingStyleList,
                  selectedId: state.selectedCookingData?.id,
                  onSelected: (id) {
                    if (id == null) {
                      context
                          .read<HomeCubit>()
                          .onCookingStyleChanged(data: null);
                    } else {
                      final matching = state.cookingStyleList
                          ?.cast<dynamic>()
                          .firstWhere(
                            (c) => c.id == id,
                            orElse: () => null,
                          );
                      context
                          .read<HomeCubit>()
                          .onCookingStyleChanged(data: matching);
                    }
                    context.read<HomeCubit>().onApplyFilter();
                  },
                ),
              ),

              // Section title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: 12,
                  ),
                  child: Text(
                    'Cooking today near you',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),

              // Loading state
              if (state.statusApi!.isSubmissionInProgress &&
                  state.statusRecommRes!.isSubmissionInProgress &&
                  totalFeedCount == 0)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CupertinoActivityIndicator(
                        color: MitablColors.primary,
                      ),
                    ),
                  ),
                ),

              // Error/offline state
              if (state.statusApi!.isSubmissionFailure &&
                  state.statusRecommRes!.isSubmissionFailure &&
                  totalFeedCount == 0)
                SliverToBoxAdapter(
                  child: OfflineErrorWidget(
                    onRetry: () {
                      context.read<HomeCubit>().onApplyFilter();
                    },
                  ),
                ),

              // Cook cards feed
              if (totalFeedCount > 0)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      int? kitchenId;
                      String name = '';
                      String? description;
                      double? rating;
                      List<Images>? images;
                      double? distance;
                      int? dineIn;
                      int? takeAway;

                      if (index < recommendedItems.length) {
                        final item = recommendedItems[index];
                        kitchenId = item.id;
                        name = item.name ?? '';
                        description = item.description;
                        rating = item.ratingCount;
                        images = item.images;
                        dineIn = item.dineIn;
                        takeAway = item.takeAway;
                      } else {
                        final nearByIndex =
                            index - recommendedItems.length;
                        final item = nearByItems[nearByIndex];
                        kitchenId = item.id;
                        name = item.name ?? '';
                        description = item.description?.toString();
                        final rawRating = item.ratingCount;
                        if (rawRating is num) {
                          rating = rawRating.toDouble();
                        } else {
                          rating = double.tryParse(
                              rawRating?.toString() ?? '');
                        }
                        images = item.images;
                        distance = item.distance;
                        dineIn = item.dineIn;
                        takeAway = item.takeAway;
                      }

                      final resolvedId = kitchenId ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: MitablSpacing.listItem / 2,
                        ),
                        child: DiscoveryCookCard(
                          id: resolvedId,
                          name: name,
                          description: description,
                          rating: rating,
                          images: images,
                          distance: distance,
                          dineIn: dineIn,
                          takeAway: takeAway,
                          isFavourited:
                              _favouritedIds.contains(resolvedId),
                          onFavouriteToggle: resolvedId > 0
                              ? () => _toggleFavourite(resolvedId)
                              : null,
                          onTap: kitchenId == null
                              ? null
                              : () => _navigateToOrderMenu(
                                    context,
                                    kitchenId!,
                                  ),
                        ),
                      );
                    },
                    childCount: totalFeedCount,
                  ),
                ),

              // Loading more indicator
              if (state.isLoadingMoreNearBy)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CupertinoActivityIndicator(
                        color: MitablColors.primary,
                      ),
                    ),
                  ),
                ),

              // Bottom padding for safe area
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Persistent header delegate for category pills
class _CategoryPillsDelegate extends SliverPersistentHeaderDelegate {
  _CategoryPillsDelegate({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CookingStyleData>? categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  double get minExtent => 50;

  @override
  double get maxExtent => 50;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFFFFFFF), // background-light
      child: DiscoveryCategoryPills(
        categories: categories,
        selectedId: selectedId,
        onSelected: onSelected,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryPillsDelegate oldDelegate) {
    return categories != oldDelegate.categories ||
        selectedId != oldDelegate.selectedId;
  }
}
