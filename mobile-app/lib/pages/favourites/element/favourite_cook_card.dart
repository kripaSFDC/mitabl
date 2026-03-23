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

  @override
  Widget build(BuildContext context) {
    final name =
        (favourite['name'] ?? favourite['title'] ?? 'Kitchen').toString();
    final description =
        (favourite['subtitle'] ?? favourite['description'] ?? '').toString();
    final imagePath = (favourite['avatar'] ?? favourite['image'] ?? '').toString();
    final rating = favourite['rating']?.toString() ?? '';
    final imageUrl = imagePath.isNotEmpty
        ? '${GlobalConfiguration().getValue<String>('base_url')}/$imagePath'
        : '';

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

          // Cook info
          Padding(
            padding: const EdgeInsets.all(MitablSpacing.cardPadding),
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
    );
  }
}
