import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/model/near_by_restaurants_response.dart' as nb;
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

/// A vertical cook card used in the discovery feed.
///
/// Works with any restaurant/kitchen data by accepting common fields
/// rather than binding to a specific model.
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

  @override
  Widget build(BuildContext context) {
    return MitablCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Hero image with rating badge and heart button ──
          Stack(
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(MitablRadius.card),
                  topRight: Radius.circular(MitablRadius.card),
                ),
                child: _primaryImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _primaryImageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 180,
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
                    : _imageFallback(),
              ),

              // Rating badge (top-left)
              if ((rating ?? 0) > 0)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MitablColors.primary,
                      borderRadius: BorderRadius.circular(MitablRadius.chipSmall),
                    ),
                    child: Text(
                      '\u2605 $_formattedRating',
                      style: const TextStyle(
                        color: MitablColors.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              // Heart icon button (top-right)
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      // Favourite functionality — UI only for now
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: MitablColors.surface.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 20,
                        color: MitablColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Cook info section (overlapping avatar + name) ──
          Transform.translate(
            offset: const Offset(0, -16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Cook avatar circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MitablColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MitablColors.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 16,
                      color: MitablColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: MitablColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Description ──
          if (description != null && description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
              child: Transform.translate(
                offset: const Offset(0, -8),
                child: Text(
                  description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),

          // ── Bottom info row ──
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Row(
              children: [
                // Distance
                if (_formattedDistance.isNotEmpty) ...[
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: MitablColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formattedDistance,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Service type indicators
                if (dineIn == 1) ...[
                  Icon(
                    Icons.restaurant_outlined,
                    size: 14,
                    color: MitablColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Dine-in',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (takeAway == 1) ...[
                  Icon(
                    Icons.takeout_dining_outlined,
                    size: 14,
                    color: MitablColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Take-away',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(MitablRadius.card),
          topRight: Radius.circular(MitablRadius.card),
        ),
      ),
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
