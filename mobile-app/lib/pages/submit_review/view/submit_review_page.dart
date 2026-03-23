import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/submit_review/element/interactive_star_rating.dart';
import 'package:mitabl_user/repos/auth_headers.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
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
  final List<XFile> _selectedPhotos = [];
  final ImagePicker _imagePicker = ImagePicker();

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
    final foodImage =
        (widget.reviewData['food_image'] ?? '').toString();
    final avatarUrl = kitchenAvatar.isNotEmpty
        ? '${GlobalConfiguration().getValue<String>('base_url')}/$kitchenAvatar'
        : '';
    final foodImageUrl = foodImage.isNotEmpty
        ? '${GlobalConfiguration().getValue<String>('base_url')}/$foodImage'
        : '';

    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(
        title: const Text('Mitabl'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // ── "How was the meal?" heading (centered) ──
            const Text(
              'How was the meal?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your feedback helps the culinary community grow.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MitablColors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 28),

            // ── Restaurant Quick Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Kitchen avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: (foodImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: foodImageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  avatarUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: avatarUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              _defaultAvatar(),
                                        )
                                      : _defaultAvatar(),
                            )
                          : avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _defaultAvatar(),
                                )
                              : _defaultAvatar()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kitchenName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: MitablColors.onSurface,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        if (orderId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Order #$orderId \u2022 Delivered yesterday',
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

            const SizedBox(height: 28),

            // ── Star Rating (centered, large) ──
            InteractiveStarRating(
              rating: _rating,
              starSize: 48,
              color: MitablColors.primary,
              onRatingChanged: (value) {
                setState(() => _rating = value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              _ratingLabel(_rating),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _rating > 0
                    ? MitablColors.primary
                    : MitablColors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 32),

            // ── "Write your experience" section ──
            Align(
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Write your experience',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            MitablTextField(
              controller: _reviewController,
              hint: 'Share your thoughts on $kitchenName...',
              maxLines: 5,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 24),

            // ── "Add photos" section ──
            Align(
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Add photos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MitablColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Upload button
                  GestureDetector(
                    onTap: _pickPhotos,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: MitablColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: MitablColors.outlineVariant.withValues(alpha: 0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 24,
                            color: const Color(0xFF89726B),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Upload',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF89726B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Selected photo thumbnails
                  ..._selectedPhotos.asMap().entries.map((entry) {
                    final index = entry.key;
                    final photo = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(photo.path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPhotos.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: MitablColors.onSurface
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Submit Review button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: (_rating > 0 && !_isSubmitting)
                      ? MitablColors.primaryGradient
                      : null,
                  color: (_rating > 0 && !_isSubmitting)
                      ? null
                      : MitablColors.tertiaryFixedDim,
                  borderRadius: MitablRadius.pillBorder,
                  boxShadow: (_rating > 0 && !_isSubmitting)
                      ? [
                          BoxShadow(
                            color:
                                MitablColors.primary.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: MitablRadius.pillBorder,
                    onTap: (_rating > 0 && !_isSubmitting)
                        ? _submitReview
                        : null,
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MitablColors.onPrimary,
                              ),
                            )
                          : const Text(
                              'Submit Review',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.onPrimary,
                                fontFamily: 'Nunito',
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhotos() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedPhotos.addAll(images);
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick images.')),
      );
    }
  }

  Widget _defaultAvatar() {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFE5E2DD),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          color: MitablColors.onSurfaceVariant,
          size: 32,
        ),
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
        return 'Great';
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
      final headers = authorizedHeadersForUser(userModel);

      final restaurantId =
          widget.reviewData['restaurant_id']?.toString() ?? '';
      final orderId =
          widget.reviewData['order_id']?.toString() ?? '';
      final reviewText = _reviewController.text.trim().isNotEmpty
          ? _reviewController.text.trim()
          : 'General';
      const reviewTag = 'General';

      final uri = ApiContract.uri('v2/addreviewtorestaurant');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      request.fields['restaurant_id'] = restaurantId;
      request.fields['order_id'] = orderId;
      request.fields['rating'] = _rating.toString();
      request.fields['review'] = reviewText;
      request.fields['review_tag'] = reviewTag;

      // Add photos
      for (final photo in _selectedPhotos) {
        request.files.add(
          await http.MultipartFile.fromPath('photos[]', photo.path),
        );
      }

      final streamResponse =
          await request.send().timeout(ApiContract.requestTimeout);
      final response = await http.Response.fromStream(streamResponse);

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
