import 'package:flutter/material.dart';

/// An interactive 5-star rating widget with tap-to-select stars.
class InteractiveStarRating extends StatelessWidget {
  const InteractiveStarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starSize = 40,
    this.color = Colors.amber,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double starSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= rating ? Icons.star : Icons.star_border,
              size: starSize,
              color: color,
            ),
          ),
        );
      }),
    );
  }
}
