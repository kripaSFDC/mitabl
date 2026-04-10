import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/star_rating.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

import '../../../helper/route_arguement.dart';

class CustomerReviewPage extends StatefulWidget {
  const CustomerReviewPage({super.key, this.routeArguments});
  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => CustomerReviewPage(routeArguments: routeArguments),
    );
  }

  @override
  State<CustomerReviewPage> createState() => _CustomerReviewPageState();
}

class _CustomerReviewPageState extends State<CustomerReviewPage> {
  static const Color _starColor = MitablColors.primary;
  bool _sortHighestFirst = true;

  Map<int, int> _computeDistribution(List reviews) {
    final Map<int, int> dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final star = (r.rating ?? 0).round().clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    return dist;
  }

  @override
  Widget build(BuildContext context) {
    final reviews = [...(widget.routeArguments?.kitchen?.reviewsData ?? [])];
    reviews.sort((left, right) {
      final leftRating = left.rating ?? 0;
      final rightRating = right.rating ?? 0;
      return _sortHighestFirst
          ? rightRating.compareTo(leftRating)
          : leftRating.compareTo(rightRating);
    });
    final hasReviews = reviews.isNotEmpty;

    double avgRating = 0;
    if (hasReviews) {
      double sum = 0;
      for (final r in reviews) {
        sum += (r.rating ?? 0);
      }
      avgRating = sum / reviews.length;
    }

    final distribution = _computeDistribution(reviews);

    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: Column(
        children: [
          // TopAppBar
          SafeArea(
            bottom: false,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: MitablColors.surface.withValues(alpha: 0.80),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.menu, color: MitablColors.primary),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'miCook Vendor',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: MitablColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(
                        color: MitablColors.primary.withValues(alpha: 0.10),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.person,
                        color: MitablColors.onSurfaceVariant, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: hasReviews
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Summary Dashboard Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: MitablColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: MitablColors.onSurface
                                  .withValues(alpha: 0.06),
                              blurRadius: 48,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: rating number + stars
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'OVERALL RATING',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        avgRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          color: MitablColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '/ 5.0',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: MitablColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      StarRating(
                                        rating: avgRating,
                                        size: 22,
                                        color: _starColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${reviews.length} reviews)',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: MitablColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Right: distribution bars
                            SizedBox(
                              width: 160,
                              child: Column(
                                children: List.generate(3, (i) {
                                  final star = 5 - i;
                                  final count = distribution[star] ?? 0;
                                  final fraction = reviews.isNotEmpty
                                      ? count / reviews.length
                                      : 0.0;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          child: Text(
                                            '$star',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  MitablColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: fraction,
                                              minHeight: 6,
                                              backgroundColor:
                                                  const Color(0xFFF1F5F9),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(Color(0xFF506140)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Reviews List header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Latest Feedback',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: MitablColors.onSurface,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _sortHighestFirst = !_sortHighestFirst;
                              });
                            },
                            icon: const Icon(Icons.filter_list,
                                size: 18, color: MitablColors.primary),
                            label: Text(
                              _sortHighestFirst
                                  ? 'Sort: Highest Rating'
                                  : 'Sort: Lowest Rating',
                              style: const TextStyle(
                                color: MitablColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Individual review cards
                      ...List.generate(reviews.length, (index) {
                        final review = reviews[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < reviews.length - 1 ? 16 : 0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: MitablColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl:
                                              "${GlobalConfiguration().getValue<String>('base_url')}/${review.user!.avatar}",
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: const Color(0xFFFFEDD5),
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            width: 48,
                                            height: 48,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFFFEDD5),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color:
                                                  MitablColors.onSurfaceVariant,
                                              size: 24,
                                            ),
                                          ),
                                          placeholder: (context, s) =>
                                              Container(
                                            width: 48,
                                            height: 48,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFFFFEDD5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review.user!.name!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: MitablColors.onSurface,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              review.reviewTag ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: MitablColors
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Star rating
                                    Row(
                                      children: List.generate(5, (i) {
                                        return Icon(
                                          Icons.star,
                                          size: 18,
                                          color:
                                              i < (review.rating ?? 0).round()
                                                  ? _starColor
                                                  : MitablColors.outlineVariant,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Review text
                                _ExpandableReviewText(
                                    text: review.review ?? ''),
                                // Tags
                                if (review.reviewTag != null &&
                                    review.reviewTag!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: const BoxDecoration(
                                          color:
                                              MitablColors.secondaryContainer,
                                          borderRadius: MitablRadius.pillBorder,
                                        ),
                                        child: Text(
                                          review.reviewTag!,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                            color: MitablColors
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  )
                : const Center(
                    child: Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableReviewText extends StatefulWidget {
  const _ExpandableReviewText({required this.text});

  final String text;

  @override
  State<_ExpandableReviewText> createState() => _ExpandableReviewTextState();
}

class _ExpandableReviewTextState extends State<_ExpandableReviewText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Text(
        widget.text,
        style: const TextStyle(
          fontSize: 14,
          color: MitablColors.onSurfaceVariant,
          height: 1.5,
        ),
        maxLines: _expanded ? null : 4,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
    );
  }
}
