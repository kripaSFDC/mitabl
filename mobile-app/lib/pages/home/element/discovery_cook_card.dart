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
    // Default based on nothing
    return '\$\$';
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
          // -- Hero image with rating badge and heart button --
          Stack(
            children: [
              // Image - 200px height per design
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(MitablRadius.card),
                  topRight: Radius.circular(MitablRadius.card),
                ),
                child: _primaryImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _primaryImageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 200,
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

              // Rating badge (top-LEFT) - semi-transparent dark pill with star
              if ((rating ?? 0) > 0)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MitablColors.onSurface.withValues(alpha: 0.65),
                      borderRadius: MitablRadius.pillBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formattedRating,
                          style: const TextStyle(
                            color: MitablColors.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                    onTap: onFavouriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: MitablColors.surface.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavourited
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                        color: isFavourited
                            ? MitablColors.error
                            : MitablColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // -- Cook name row --
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: MitablColors.onSurface,
              ),
            ),
          ),

          // -- Description --
          if (description != null && description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 4),
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

          // -- Bottom info row: Distance + Ready time + Price tier --
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                  const SizedBox(width: 10),
                ],

                // Ready time
                if (readyTime != null && readyTime!.isNotEmpty) ...[
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: MitablColors.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Ready $readyTime',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                const Spacer(),

                // Price tier
                Text(
                  _priceTierLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      height: 200,
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
