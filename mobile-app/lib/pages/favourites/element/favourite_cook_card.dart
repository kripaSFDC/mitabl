import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

/// A card displaying a favourite cook/kitchen with hero image, rating, and
/// unfavourite heart button.
class FavouriteCookCard extends StatelessWidget {
  const FavouriteCookCard({
    super.key,
    required this.favourite,
    required this.onUnfavourite,
    this.onTap,
  });

  final Map<String, dynamic> favourite;
  final VoidCallback onUnfavourite;
  final VoidCallback? onTap;

  static String _formatRating(dynamic value) {
    if (value is double) return value.toStringAsFixed(1);
    if (value is int) return value.toStringAsFixed(1);
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed.toStringAsFixed(1);
    return '';
  }

  static String _formatDistance(dynamic value) {
    if (value is double) return '${value.toStringAsFixed(1)} km';
    if (value is int) return '${value.toStringAsFixed(1)} km';
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return '${parsed.toStringAsFixed(1)} km';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final name =
        (favourite['name'] ?? favourite['title'] ?? 'Kitchen').toString();
    final description =
        (favourite['subtitle'] ?? favourite['description'] ?? '').toString();

    // Prefer hero image from images[] array, fall back to avatar
    final imagesList = favourite['images'];
    String imagePath = '';
    if (imagesList is List && imagesList.isNotEmpty) {
      final firstImage = imagesList.first;
      if (firstImage is Map) {
        imagePath = (firstImage['path'] ?? '').toString();
      } else if (firstImage is String) {
        imagePath = firstImage;
      }
    }
    if (imagePath.isEmpty) {
      imagePath = (favourite['avatar'] ?? favourite['image'] ?? '').toString();
    }

    // Rating from rating_count (float) or rating
    final ratingRaw = favourite['rating_count'] ?? favourite['rating'];
    final rating = ratingRaw != null ? _formatRating(ratingRaw) : '';

    // Distance
    final distanceRaw = favourite['distance'];
    final distanceLabel =
        distanceRaw != null ? _formatDistance(distanceRaw) : '';

    // Cook avatar
    final cockData = favourite['cock'];
    final cookAvatarPath =
        cockData is Map ? (cockData['avatar'] ?? '').toString() : '';
    final baseUrl = GlobalConfiguration().getValue<String>('base_url');
    final imageUrl = imagePath.isNotEmpty ? '$baseUrl/$imagePath' : '';
    final cookAvatarUrl =
        cookAvatarPath.isNotEmpty ? '$baseUrl/$cookAvatarPath' : '';
    final cookName =
        cockData is Map ? (cockData['name'] ?? '').toString() : '';

    return MitablCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image with rating badge and heart button
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(MitablRadius.card),
                  topRight: Radius.circular(MitablRadius.card),
                ),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 160,
                          color: MitablColors.surfaceContainerLow,
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 40,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 160,
                          color: MitablColors.surfaceContainerLow,
                          child: const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 40,
                              color: MitablColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        height: 160,
                        width: double.infinity,
                        color: MitablColors.surfaceContainerLow,
                        child: const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 40,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),

              // Rating badge
              if (rating.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MitablColors.onSurface.withValues(alpha: 0.7),
                      borderRadius: MitablRadius.pillBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Distance badge
              if (distanceLabel.isNotEmpty)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MitablColors.onSurface.withValues(alpha: 0.7),
                      borderRadius: MitablRadius.pillBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          distanceLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Heart button
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onUnfavourite,
                    borderRadius: MitablRadius.pillBorder,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MitablColors.surfaceContainerLowest
                            .withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: MitablColors.error,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Cook info with avatar
          Padding(
            padding: const EdgeInsets.all(MitablSpacing.cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cook avatar
                if (cookAvatarUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: cookAvatarUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: MitablColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 20,
                            color: MitablColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: MitablColors.onSurface,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      if (cookName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'by $cookName',
                          style: const TextStyle(
                            fontSize: 12,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
