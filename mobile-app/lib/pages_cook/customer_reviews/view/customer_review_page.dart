import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/star_rating.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

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
  @override
  Widget build(BuildContext context) {
    final reviews = widget.routeArguments!.kitchen!.reviewsData!;
    final hasReviews = reviews.isNotEmpty;

    // Compute average rating
    double avgRating = 0;
    if (hasReviews) {
      double sum = 0;
      for (final r in reviews) {
        sum += (r.rating ?? 0);
      }
      avgRating = sum / reviews.length;
    }

    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: const GlassAppBar(
        title: Text('Customer Reviews'),
      ),
      body: hasReviews
          ? ListView(
              padding: const EdgeInsets.all(MitablSpacing.pagePadding),
              children: [
                // Rating summary card
                MitablCard(
                  child: Column(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: GoogleFonts.nunito(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StarRating(
                        rating: avgRating,
                        size: 28,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MitablSpacing.listItem),

                // Individual review cards
                ...List.generate(reviews.length, (index) {
                  final review = reviews[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < reviews.length - 1
                          ? MitablSpacing.listItem
                          : 0,
                    ),
                    child: MitablCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CachedNetworkImage(
                                imageUrl:
                                    "${GlobalConfiguration().getValue<String>('base_url')}/${review.user!.avatar}",
                                imageBuilder: (context, imageProvider) =>
                                    CircleAvatar(
                                  radius: 22,
                                  backgroundImage: imageProvider,
                                ),
                                errorWidget: (context, url, error) =>
                                    const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: MitablColors.surfaceContainerLow,
                                  child: Icon(
                                    Icons.person,
                                    color: MitablColors.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ),
                                placeholder: (context, s) => const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: MitablColors.surfaceContainerLow,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.user!.name!,
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: MitablColors.onSurface,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    StarRating(
                                      rating: review.rating!,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ExpandableReviewText(text: review.review ?? ''),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            )
          : Center(
              child: Text(
                'No reviews yet',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
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
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: MitablColors.onSurface,
          height: 1.5,
        ),
        maxLines: _expanded ? null : 4,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
    );
  }
}
