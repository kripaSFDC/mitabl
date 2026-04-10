import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

import '../cubit/profile_cook_cubit.dart';
import '../elements/timing_view.dart';

class MikitchnTabView extends StatefulWidget {
  const MikitchnTabView({super.key});

  @override
  State<MikitchnTabView> createState() => _MikitchnTabViewState();
}

class _MikitchnTabViewState extends State<MikitchnTabView> {
  PageController? controller = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCookCubit, ProfileCookState>(
      listener: (context, state) {},
      builder: (context, state) {
        final kitchen = state.cookProfile?.data?.kitchen;

        // ── No kitchen record yet ──
        if (kitchen == null) {
          return RefreshIndicator(
            color: MitablColors.primary,
            onRefresh: () async {
              context.read<ProfileCookCubit>().getCookProfile();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: MitablSpacing.pagePadding,
              ),
              children: [
                const SizedBox(height: 80),
                const Icon(
                  Icons.storefront_outlined,
                  size: 64,
                  color: MitablColors.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No mikitchn record exists for this micook profile yet.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MitablColors.onSurface,
                    fontFamily: 'DM Sans',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add your mikitchn from this tab now, and later use the same place to view or edit it.',
                  style: TextStyle(
                    fontSize: 14,
                    color: MitablColors.onSurfaceVariant,
                    fontFamily: 'DM Sans',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 240,
                    child: Semantics(
                      button: true,
                      label: 'Add mikitchn',
                      hint: 'Creates your kitchen profile.',
                      child: ElevatedButton(
                        onPressed: () {
                          navigatorKey.currentState!
                              .pushNamed(
                            '/EditKitchenProfile',
                            arguments: RouteArguments(),
                          )
                              .then((value) {
                            if (!context.mounted) return;
                            if (value == true) {
                              context.read<ProfileCookCubit>().getCookProfile();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MitablColors.primary,
                          foregroundColor: MitablColors.onPrimary,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                        child: const Text('Add mikitchn'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: context.read<ProfileCookCubit>().getCookProfile,
                    style: TextButton.styleFrom(
                      foregroundColor: MitablColors.primary,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                    child: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          );
        }

        // ── Kitchen exists ──
        final isActive = kitchen.status == '1';

        return RefreshIndicator(
          color: MitablColors.primary,
          onRefresh: () async {
            context.read<ProfileCookCubit>().getCookProfile();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: MitablSpacing.pagePadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Hero image / carousel ──
                _buildHeroImage(state),

                // ── Page indicator dots ──
                if (state.pathFiles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPageIndicator(state),
                ],

                const SizedBox(height: 20),

                // ── Kitchen name ──
                Semantics(
                  header: true,
                  label: 'Kitchen name: ${kitchen.name?.toString() ?? ''}',
                  child: ExcludeSemantics(
                    child: Text(
                      kitchen.name?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: MitablColors.onSurface,
                        fontFamily: 'Nunito',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Info rows card ──
                Semantics(
                  container: true,
                  label:
                      'Kitchen details. Address: ${kitchen.address?.toString() ?? '-'}. Phone: ${kitchen.phone?.toString() ?? '-'}. Seats: ${kitchen.noOfSeats ?? 0}.',
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(MitablRadius.card),
                    ),
                    padding: const EdgeInsets.all(MitablSpacing.cardPadding),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          text: kitchen.address?.toString() ?? '-',
                        ),
                        _infoDivider(),
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          text: kitchen.phone?.toString() ?? '-',
                        ),
                        _infoDivider(),
                        _buildInfoRow(
                          icon: Icons.event_seat_outlined,
                          text: '${kitchen.noOfSeats ?? 0} seats',
                        ),
                        if (kitchen.description != null &&
                            kitchen.description!.isNotEmpty) ...[
                          _infoDivider(),
                          _buildInfoRow(
                            icon: Icons.info_outline,
                            text: kitchen.description!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: MitablSpacing.listItem),

                Semantics(
                  container: true,
                  label: isActive
                      ? 'Kitchen account status: activated.'
                      : 'Kitchen account status: inactive.',
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(MitablRadius.card),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: MitablSpacing.cardPadding,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isActive
                                ? MitablColors.accent
                                : MitablColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isActive
                                ? 'Your account is activated'
                                : 'Your account is inactive',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isActive
                                  ? MitablColors.accent
                                  : MitablColors.error,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ),
                        if (!isActive)
                          Semantics(
                            button: true,
                            label: 'Activate kitchen account',
                            hint:
                                'Double tap to activate this kitchen account.',
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MitablColors.primary,
                                foregroundColor: MitablColors.onPrimary,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                              child: const Text('Activate'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: MitablSpacing.listItem),

                // ── Service type chips ──
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildServiceChip(
                      label: 'Dine-in',
                      enabled: kitchen.dineIn == 1,
                    ),
                    _buildServiceChip(
                      label: 'Takeaway',
                      enabled: kitchen.takeAway == 1,
                    ),
                  ],
                ),

                const SizedBox(height: MitablSpacing.listItem),

                // ── Available toggle ──
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: MitablColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(MitablRadius.card),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: MitablSpacing.cardPadding,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: MitablColors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.toggle_on_outlined,
                            size: 20,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: MitablColors.onSurface,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                      Semantics(
                        toggled: kitchen.available == 1,
                        label: 'Kitchen availability',
                        hint: kitchen.available == 1
                            ? 'Currently available.'
                            : 'Currently unavailable.',
                        child: ExcludeSemantics(
                          child: Switch(
                            value: kitchen.available == 1,
                            activeTrackColor: MitablColors.primary,
                            onChanged: (val) {},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: MitablSpacing.listItem),

                // ── Timings row ──
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: MitablColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(MitablRadius.card),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Semantics(
                      button: true,
                      label: 'Kitchen timings',
                      hint: 'Double tap to review or edit kitchen timings.',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(MitablRadius.card),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (contexts) {
                              return BlocProvider.value(
                                value: context.read<ProfileCookCubit>(),
                                child: TimingViewDialog(),
                              );
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MitablSpacing.cardPadding,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: MitablColors.surfaceContainerLowest,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.access_time_rounded,
                                    size: 20,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Timings',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: MitablColors.onSurface,
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: MitablColors.onSurfaceVariant,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: MitablSpacing.listItem),

                // ── Action buttons ──

                // Edit Kitchen – primary
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: 'Edit kitchen',
                    hint: 'Double tap to edit mikitchn details.',
                    child: ElevatedButton(
                      onPressed: () {
                        navigatorKey.currentState!
                            .pushNamed(
                          '/EditKitchenProfile',
                          arguments: RouteArguments(
                            kitchen: kitchen,
                          ),
                        )
                            .then((value) {
                          if (!context.mounted) return;
                          if (value != null && value == true) {
                            context.read<ProfileCookCubit>().getCookProfile();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MitablColors.primary,
                        foregroundColor: MitablColors.onPrimary,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      child: const Text('Edit Kitchen'),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Customer Reviews – outline
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: 'Customer reviews',
                    hint:
                        'Double tap to view customer reviews for this kitchen.',
                    child: OutlinedButton(
                      onPressed: () {
                        navigatorKey.currentState!.pushNamed(
                          '/CustomerReviewPage',
                          arguments: RouteArguments(
                            kitchen: kitchen,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MitablColors.primary,
                        side: const BorderSide(
                          color: MitablColors.outlineVariant,
                        ),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      child: const Text('Customer Reviews'),
                    ),
                  ),
                ),

                // ── Bottom spacing ──
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 80,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sub-widgets
  // ─────────────────────────────────────────────────────────────────────────

  /// Hero image carousel or placeholder (200px height, rounded-20).
  Widget _buildHeroImage(ProfileCookState state) {
    final imageCount = state.pathFiles.length;
    final currentIndex = (state.selectedPage ?? 0) + 1;

    if (state.pathFiles.isNotEmpty) {
      return Semantics(
        image: true,
        label:
            'Kitchen photos carousel. Image $currentIndex of $imageCount. Swipe left or right for more photos.',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MitablRadius.card),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: controller,
              onPageChanged: (page) {
                context.read<ProfileCookCubit>().onImageScroll(
                      index: page,
                    );
              },
              scrollDirection: Axis.horizontal,
              itemCount: state.pathFiles.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl:
                      '${GlobalConfiguration().getValue<String>('image_base_url')}${state.pathFiles[index].path}',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: MitablColors.surfaceContainerLow,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MitablColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: MitablColors.surfaceContainerLow,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // Placeholder
    return Semantics(
      image: true,
      label: 'No kitchen photos uploaded yet.',
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: MitablColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(MitablRadius.card),
        ),
        child: const Center(
          child: Icon(
            Icons.photo_outlined,
            size: 64,
            color: MitablColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Page indicator dots.
  Widget _buildPageIndicator(ProfileCookState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        state.pathFiles.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: state.selectedPage == index
                ? MitablColors.primary
                : MitablColors.outlineVariant,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  /// Info row with icon + text.
  Widget _buildInfoRow({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: MitablColors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: MitablColors.onSurface,
                fontFamily: 'DM Sans',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Thin divider inside info card.
  Widget _infoDivider() {
    return Divider(
      height: 12,
      thickness: 0.5,
      color: MitablColors.outlineVariant.withValues(alpha: 0.5),
    );
  }

  /// Service type chip (Dine-in / Takeaway).
  Widget _buildServiceChip({
    required String label,
    required bool enabled,
  }) {
    return Semantics(
      label: '$label service ${enabled ? 'enabled' : 'disabled'}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? MitablColors.secondaryContainer
              : MitablColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(MitablRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled ? Icons.check_circle : Icons.cancel_outlined,
              size: 16,
              color: enabled
                  ? MitablColors.onSecondaryContainer
                  : MitablColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? MitablColors.onSecondaryContainer
                    : MitablColors.onSurfaceVariant,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
