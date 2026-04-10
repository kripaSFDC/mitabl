import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/pages/home/cubit/home_cubit.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';

/// Full-screen filter page navigated to via [Navigator.push] from [HomePage].
///
/// Shares the same [HomeCubit] instance via [BlocProvider.value].
/// NOT registered as a named route.
class SearchFiltersPage extends StatefulWidget {
  const SearchFiltersPage({super.key});

  @override
  State<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class _SearchFiltersPageState extends State<SearchFiltersPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedPriceIndex;

  @override
  void initState() {
    super.initState();
    // Ensure cooking styles are loaded for filter display
    context.read<HomeCubit>().onCookingStyle();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Diet ID to label mapping matching the design.
  static const Map<int, String> _dietaryOptions = {
    1: 'Vegan',
    2: 'Vegetarian',
    3: 'Gluten-Free',
    4: 'Keto',
    5: 'Pescatarian',
  };

  /// Icons for dietary options matching the HTML design.
  static const Map<int, IconData> _dietaryIcons = {
    1: Icons.eco,
    2: Icons.grass,
    3: Icons.no_food,
    4: Icons.monitor_weight_outlined,
    5: Icons.set_meal,
  };

  final Set<int> _selectedDietIds = {};

  static const _priceTiers = ['\$', '\$\$', '\$\$\$', '\$\$\$\$'];

  void _clearAll() {
    setState(() {
      _searchController.clear();
      _selectedDietIds.clear();
      _selectedPriceIndex = null;
    });
    // Reset cuisine selection and distance to default
    context.read<HomeCubit>().onCookingStyleChanged(data: null);
    context.read<HomeCubit>().onDistanceChanged(distance: 15);
  }

  void _applyFilters() {
    context.read<HomeCubit>().onApplyFilter();
    // Pass selected diet IDs back to the home page for client-side filtering
    Navigator.of(context).pop(_selectedDietIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: MitablColors.surface,
          appBar: const GlassAppBar(title: Text('miFoodi')),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MitablSpacing.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ── Heading with accent span ──
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            color: MitablColors.onSurface,
                            height: 1.2,
                          ),
                          children: const [
                            TextSpan(text: 'What are you\n'),
                            TextSpan(
                              text: 'craving today?',
                              style: TextStyle(
                                color: MitablColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Search bar ──
                      MitablTextField(
                        controller: _searchController,
                        hint: 'Search dishes, cuisines, or restaurants',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Cuisine section (horizontal scroll with images) ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cuisine',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: MitablColors.onSurface,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final cuisines = state.cookingStyleList ?? const [];
                          if (cuisines.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Loading cuisines...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: cuisines.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final cuisine = cuisines[index];
                                final isSelected =
                                    state.selectedCookingData?.id ==
                                        cuisine.id;
                                return GestureDetector(
                                  onTap: () {
                                    context
                                        .read<HomeCubit>()
                                        .onCookingStyleChanged(
                                          data:
                                              isSelected ? null : cuisine,
                                        );
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? MitablColors.primary
                                              : MitablColors
                                                  .surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: isSelected
                                              ? Border.all(
                                                  color: MitablColors
                                                      .primary
                                                      .withValues(
                                                          alpha: 0.1),
                                                  width: 4,
                                                )
                                              : null,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.restaurant,
                                            size: 32,
                                            color: isSelected
                                                ? MitablColors.onPrimary
                                                : MitablColors
                                                    .onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        cuisine.name ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? MitablColors.primary
                                              : MitablColors
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── Dietary Preferences section (pill chips with icons) ──
                      Text(
                        'Dietary Preferences',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dietaryOptions.entries.map((entry) {
                          final dietId = entry.key;
                          final label = entry.value;
                          final isSelected =
                              _selectedDietIds.contains(dietId);
                          final icon = _dietaryIcons[dietId] ?? Icons.eco;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedDietIds.remove(dietId);
                                } else {
                                  _selectedDietIds.add(dietId);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? MitablColors.secondaryContainer
                                    : MitablColors.surfaceContainerLow,
                                borderRadius: MitablRadius.pillBorder,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 18,
                                    color: isSelected
                                        ? MitablColors
                                            .onSecondaryContainer
                                        : MitablColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? MitablColors
                                              .onSecondaryContainer
                                          : MitablColors
                                              .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      // ── Distance section (slider in tonal card) ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: MitablColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Distance',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: MitablColors.primary,
                                    borderRadius:
                                        MitablRadius.pillBorder,
                                  ),
                                  child: Text(
                                    'Within ${state.selectedDistance?.toInt() ?? 15} km',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: MitablColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: MitablColors.primary,
                                inactiveTrackColor:
                                    MitablColors.outlineVariant
                                        .withValues(alpha: 0.3),
                                thumbColor: MitablColors.primary,
                                overlayColor: MitablColors.primary
                                    .withValues(alpha: 0.1),
                                trackHeight: 4,
                                thumbShape:
                                    const RoundSliderThumbShape(
                                  enabledThumbRadius: 12,
                                ),
                              ),
                              child: Slider(
                                value:
                                    state.selectedDistance ?? 15,
                                min: 1,
                                max: 20,
                                divisions: 19,
                                label:
                                    '${state.selectedDistance?.toInt() ?? 15} km',
                                onChanged: (value) {
                                  context
                                      .read<HomeCubit>()
                                      .onDistanceChanged(
                                          distance: value);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '1 km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: MitablColors
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Text(
                                    '20 km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: MitablColors
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Price Range section (4 grid buttons) ──
                      Text(
                        'Price Range',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(
                            _priceTiers.length, (index) {
                          final isSelected =
                              _selectedPriceIndex == index;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < _priceTiers.length - 1
                                    ? 8.0
                                    : 0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPriceIndex =
                                        isSelected ? null : index;
                                  });
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? MitablColors.primary
                                        : MitablColors
                                            .surfaceContainerLow,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: MitablColors
                                                  .primary
                                                  .withValues(
                                                      alpha:
                                                          0.2),
                                              blurRadius: 12,
                                              offset:
                                                  const Offset(
                                                      0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _priceTiers[index],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            FontWeight.w700,
                                        color: isSelected
                                            ? MitablColors
                                                .onPrimary
                                            : MitablColors
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Bottom action buttons ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MitablSpacing.pagePadding,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: MitablColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: MitablColors.onSurface
                          .withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Clear All button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: Material(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: MitablRadius.pillBorder,
                            child: InkWell(
                              borderRadius: MitablRadius.pillBorder,
                              onTap: _clearAll,
                              child: const Center(
                                child: Text(
                                  'Clear All',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Apply Filters button (2x width)
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient:
                                  MitablColors.primaryGradient,
                              borderRadius:
                                  MitablRadius.pillBorder,
                              boxShadow: [
                                BoxShadow(
                                  color: MitablColors.primary
                                      .withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius:
                                    MitablRadius.pillBorder,
                                onTap: _applyFilters,
                                child: const Center(
                                  child: Text(
                                    'Apply Filters',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          MitablColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
