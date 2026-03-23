import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/pages/home/cubit/home_cubit.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';
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
          appBar: const GlassAppBar(title: null),
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
                      const SizedBox(height: 8),
                      // ── Heading ──
                      Text(
                        'What are you\ncraving today?',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Search bar ──
                      MitablTextField(
                        controller: _searchController,
                        hint: 'Search dishes, cuisines, or restaurants',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Cuisine section (dynamic from API) ──
                      _sectionTitle('Cuisine'),
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
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.2,
                            ),
                            itemCount: cuisines.length,
                            itemBuilder: (context, index) {
                              final cuisine = cuisines[index];
                              final isSelected =
                                  state.selectedCookingData?.id == cuisine.id;
                              return _CuisineTile(
                                icon: Icons.restaurant_outlined,
                                label: cuisine.name ?? '',
                                isSelected: isSelected,
                                onTap: () {
                                  context
                                      .read<HomeCubit>()
                                      .onCookingStyleChanged(
                                        data: isSelected ? null : cuisine,
                                      );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Dietary Preferences section ──
                      _sectionTitle('Dietary Preferences'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dietaryOptions.entries.map((entry) {
                          final dietId = entry.key;
                          final label = entry.value;
                          final isSelected = _selectedDietIds.contains(dietId);
                          return MitablChip(
                            label: label,
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                if (isSelected) {
                                  _selectedDietIds.remove(dietId);
                                } else {
                                  _selectedDietIds.add(dietId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // ── Distance section ──
                      _sectionTitle(
                        'Within ${state.selectedDistance?.toInt() ?? 15}km',
                      ),
                      const SizedBox(height: 4),
                      Slider(
                        value: state.selectedDistance ?? 15,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        activeColor: MitablColors.primary,
                        inactiveColor: MitablColors.tertiaryFixedDim,
                        label:
                            '${state.selectedDistance?.toInt() ?? 15}km',
                        onChanged: (value) {
                          context
                              .read<HomeCubit>()
                              .onDistanceChanged(distance: value);
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Price Range section ──
                      _sectionTitle('Price Range'),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(_priceTiers.length, (index) {
                          final isSelected = _selectedPriceIndex == index;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right:
                                    index < _priceTiers.length - 1 ? 8.0 : 0,
                              ),
                              child: Material(
                                color: isSelected
                                    ? MitablColors.primary
                                    : MitablColors.surfaceContainerLow,
                                borderRadius: MitablRadius.pillBorder,
                                child: InkWell(
                                  borderRadius: MitablRadius.pillBorder,
                                  onTap: () {
                                    setState(() {
                                      _selectedPriceIndex =
                                          isSelected ? null : index;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _priceTiers[index],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? MitablColors.onPrimary
                                              : MitablColors.onSurface,
                                        ),
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
                      color: MitablColors.onSurface.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: MitablButton(
                          label: 'Clear All',
                          variant: MitablButtonVariant.outline,
                          onPressed: _clearAll,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MitablButton(
                          label: 'Apply Filters',
                          variant: MitablButtonVariant.primary,
                          onPressed: _applyFilters,
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: MitablColors.onSurface,
      ),
    );
  }
}

// ── Private helper types ──

class _CuisineTile extends StatelessWidget {
  const _CuisineTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? MitablColors.primary.withValues(alpha: 0.1)
          : MitablColors.surfaceContainerLowest,
      borderRadius: MitablRadius.cardBorder,
      child: InkWell(
        borderRadius: MitablRadius.cardBorder,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: MitablRadius.cardBorder,
            border: Border.all(
              color: isSelected
                  ? MitablColors.primary
                  : MitablColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? MitablColors.primary
                    : MitablColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? MitablColors.primary
                      : MitablColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
