import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/model/near_by_restaurants_response.dart' as nb;
import 'package:mitabl_user/widgets/design_tokens.dart';

/// Discovery cook card matching the HTML design:
/// - rounded-[20px] bg-surface shadow-soft
/// - h-[180px] hero image with badges (rating top-left, Trending/Vegan top-left)
/// - Heart button top-right on image
/// - Cook avatar top-RIGHT of content area (-top-6 right-4)
/// - Kitchen name text-[22px] font-extrabold
/// - Description text-sm text-muted
/// - border-t bottom row with distance, time, price tier
class DiscoveryCookCard extends StatelessWidget {
  const DiscoveryCookCard({
    super.key,
    required this.id,
    required this.name,
    this.description,
    this.rating,
    this.images,
    this.distance,
    this.dineIn,
    this.takeAway,
    this.onTap,
    this.isFavourited = false,
    this.onFavouriteToggle,
    this.readyTime,
    this.priceTier,
  });

  final int id;
  final String name;
  final String? description;
  final double? rating;
  final List<nb.Images>? images;
  final double? distance;
  final int? dineIn;
  final int? takeAway;
  final VoidCallback? onTap;
  final bool isFavourited;
  final VoidCallback? onFavouriteToggle;
  final String? readyTime;
  final String? priceTier;

  String? get _primaryImageUrl {
    final imgList = images;
    if (imgList == null || imgList.isEmpty) return null;
    final path = imgList.first.path;
    if (path == null || path.isEmpty) return null;
    final baseUrl =
        GlobalConfiguration().getValue<String>('image_base_url');
    return '$baseUrl$path';
  }

  String get _formattedRating =>
      (rating ?? 0).toStringAsFixed(1);

  String get _formattedDistance {
    if (distance == null) return '';
    return '${distance!.toStringAsFixed(1)} mi';
  }

  String get _priceTierLabel {
    if (priceTier != null && priceTier!.isNotEmpty) return priceTier!;
    return '\$\$';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAF8), // surface
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3E3129).withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero image with badges and heart
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  if (_primaryImageUrl != null)
                    CachedNetworkImage(
                      imageUrl: _primaryImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: MitablColors.surfaceContainerLow,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: MitablColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _imageFallback(),
                    )
                  else
                    _imageFallback(),

                  // Badges top-left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        // Rating badge
                        if ((rating ?? 0) > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFCFAF8)
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Color(0xFFD96C4A), // primary
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formattedRating,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3E3129),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // "Trending" badge (shown for high-rated items)
                        if ((rating ?? 0) >= 4.9) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD96C4A),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Trending',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Heart button top-right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: onFavouriteToggle,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFAF8)
                              .withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isFavourited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: isFavourited
                                ? MitablColors.error
                                : const Color(0xFF3E3129),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content area with cook avatar overlapping
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kitchen name
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: const Color(0xFF3E3129),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Description
                      if (description != null && description!.isNotEmpty)
                        Text(
                          description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8D7A6F),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Bottom info row with border-t
                      Container(
                        padding: const EdgeInsets.only(top: 12, bottom: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFF7F4EF), // background-light
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Distance
                            if (_formattedDistance.isNotEmpty) ...[
                              const Icon(
                                Icons.directions_walk,
                                size: 16,
                                color: Color(0xFF8D7A6F),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formattedDistance,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8D7A6F),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '\u2022',
                                style: TextStyle(
                                  color: Color(0xFF8D7A6F),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Ready time
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: Color(0xFF8D7A6F),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                readyTime != null && readyTime!.isNotEmpty
                                    ? 'Ready $readyTime'
                                    : 'Available today',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8D7A6F),
                                ),
                              ),
                            ),
                            // Price tier
                            Text(
                              _priceTierLabel,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3E3129),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Cook avatar overlapping top-right
                Positioned(
                  top: -24,
                  right: 16,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFCFAF8),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const ClipOval(
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 24,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: MitablColors.surfaceContainerLow,
      child: const Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 48,
          color: MitablColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
