import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/submit_review/element/interactive_star_rating.dart';
import 'package:mitabl_user/repos/auth_headers.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';

class SubmitReviewPage extends StatefulWidget {
  const SubmitReviewPage({super.key, required this.reviewData});

  final Map<String, dynamic> reviewData;

  static Route route({RouteArguments? routeArguments}) {
    final data = routeArguments?.data is Map<String, dynamic>
        ? routeArguments!.data as Map<String, dynamic>
        : <String, dynamic>{};
    return MaterialPageRoute<void>(
      builder: (_) => SubmitReviewPage(reviewData: data),
    );
  }

  @override
  State<SubmitReviewPage> createState() => _SubmitReviewPageState();
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  final Set<String> _selectedTags = {};

  static const _reviewTags = [
    'Great taste',
    'Good portions',
    'Fast service',
    'Fresh ingredients',
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitchenName =
        (widget.reviewData['kitchen_name'] ?? 'Kitchen').toString();
    final kitchenAvatar =
        (widget.reviewData['kitchen_avatar'] ?? '').toString();
    final orderId =
        (widget.reviewData['order_id'] ?? '').toString();
    final avatarUrl = kitchenAvatar.isNotEmpty
        ? '${GlobalConfiguration().getValue<String>('base_url')}/$kitchenAvatar'
        : '';

    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: const GlassAppBar(title: Text('Leave a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        child: Column(
          children: [
            // Cook info
            MitablCard(
              child: Row(
                children: [
                  ClipOval(
                    child: avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _defaultAvatar(),
                          )
                        : _defaultAvatar(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kitchenName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        if (orderId.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Order #MF-$orderId',
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

            const SizedBox(height: MitablSpacing.listItem),

            // Star rating
            MitablCard(
              child: Column(
                children: [
                  const Text(
                    'How was the meal?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 16),
                  InteractiveStarRating(
                    rating: _rating,
                    onRatingChanged: (value) {
                      setState(() => _rating = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ratingLabel(_rating),
                    style: const TextStyle(
                      fontSize: 14,
                      color: MitablColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Review tags
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What did you enjoy?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reviewTags.map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return MitablChip(
                        label: tag,
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // Review text
            MitablCard(
              child: MitablTextField(
                controller: _reviewController,
                label: 'Your Review',
                hint: 'Share your experience...',
                maxLines: 4,
                textInputAction: TextInputAction.done,
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            MitablButton(
              label: 'Submit Review',
              isLoading: _isSubmitting,
              onPressed: _rating > 0 ? _submitReview : null,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.restaurant,
        color: MitablColors.onSurfaceVariant,
        size: 28,
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    try {
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      final headers = authorizedHeadersForUser(
        userModel,
        includeJsonContentType: true,
      );

      final restaurantId =
          widget.reviewData['restaurant_id']?.toString() ?? '';

      final response = await http.post(
        ApiContract.uri('v2/addreviewtorestaurant'),
        headers: headers,
        body: jsonEncode({
          'restaurant_id': restaurantId,
          'rating': _rating,
          'review': _reviewController.text.trim(),
          'tags': _selectedTags.toList(),
        }),
      ).timeout(ApiContract.requestTimeout);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.of(context).pop(true);
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant not found. Please try again.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to submit review. Please try again.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
