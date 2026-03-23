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
      // Revert on failure
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
      backgroundColor: MitablColors.surface,
      body: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) async {},
        builder: (context, state) {
          // ── Build combined feed list from recommended + nearby ──
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
              // ── Top safe-area spacing ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 8,
                ),
              ),

              // ── Greeting header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
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
                                color: MitablColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: MitablColors.primary,
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
                                      fontSize: 13,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Profile avatar button
                      GestureDetector(
                        onTap: () => Navigator.of(context)
                            .pushNamed('/ProfileFoodie'),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: MitablColors.primaryContainer,
                          child: Text(
                            firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: MitablColors.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search bar ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.of(context).push<List<int>>(
                        MaterialPageRoute<List<int>>(
                          builder: (_) => BlocProvider.value(
                            value: context.read<HomeCubit>(),
                            child: const SearchFiltersPage(),
                          ),
                        ),
                      );
                      // result contains selected dietary filter IDs
                      // for client-side filtering if needed
                      if (result != null && result.isNotEmpty && context.mounted) {
                        // Diet IDs available for client-side filtering
                        debugPrint('Selected diet IDs: $result');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        color: MitablColors.surfaceContainerLow,
                        borderRadius: MitablRadius.pillBorder,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 20,
                            color: MitablColors.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'What are you craving?',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: MitablColors.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Category pills (sticky) ──
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
                      final matching =
                          state.cookingStyleList?.firstWhere(
                        (c) => c.id == id,
                      );
                      context
                          .read<HomeCubit>()
                          .onCookingStyleChanged(data: matching);
                    }
                    context.read<HomeCubit>().onApplyFilter();
                  },
                ),
              ),

              // ── Section title ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 8,
                    bottom: 12,
                  ),
                  child: Text(
                    'Cooking today near you',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: MitablColors.onSurface,
                    ),
                  ),
                ),
              ),

              // ── Loading state ──
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

              // ── Error/offline state ──
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

              // ── Cook cards feed ──
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
                        // Recommended item
                        final item = recommendedItems[index];
                        kitchenId = item.id;
                        name = item.name ?? '';
                        description = item.description;
                        rating = item.ratingCount;
                        images = item.images;
                        dineIn = item.dineIn;
                        takeAway = item.takeAway;
                      } else {
                        // Nearby item
                        final nearByIndex =
                            index - recommendedItems.length;
                        final item = nearByItems[nearByIndex];
                        kitchenId = item.id;
                        name = item.name ?? '';
                        description = item.description?.toString();
                        // Parse rating from dynamic
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
                          horizontal: 20,
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

              // ── Loading more indicator ──
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

              // ── Bottom padding for safe area ──
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

// ── Persistent header delegate for category pills ──

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
    return DiscoveryCategoryPills(
      categories: categories,
      selectedId: selectedId,
      onSelected: onSelected,
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryPillsDelegate oldDelegate) {
    return categories != oldDelegate.categories ||
        selectedId != oldDelegate.selectedId;
  }
}
