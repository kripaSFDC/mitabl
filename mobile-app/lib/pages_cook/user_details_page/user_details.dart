import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/star_rating.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helper/route_arguement.dart';

class UserDetails extends StatelessWidget {
  const UserDetails({super.key, this.routeArguments});

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => UserDetails(routeArguments: routeArguments),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _contactCustomer(
    BuildContext context,
    dynamic phoneValue,
  ) async {
    final phone = phoneValue?.toString().trim() ?? '';
    final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.isEmpty) {
      _showSnackBar(
        context,
        'No phone number is available for this customer yet.',
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: normalized);
    try {
      final launched = await launchUrl(uri);
      if (!context.mounted) return;
      if (!launched) {
        _showSnackBar(context, 'Unable to start a call to $phone');
      }
    } catch (_) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Unable to start a call to $phone');
    }
  }

  Future<void> _showCreditsSupportDialog(
    BuildContext context,
    String customerName,
  ) async {
    final supportUri = Uri(
      scheme: 'mailto',
      path: 'admin@mitabl.com',
      queryParameters: {
        'subject': 'Customer credit adjustment for $customerName',
      },
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Manage Credits'),
          content: Text(
            'Credit adjustments for $customerName are handled by Mitabl support right now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final launched = await launchUrl(supportUri);
                  if (!context.mounted) return;
                  if (!launched) {
                    _showSnackBar(
                      context,
                      'Unable to open support email right now.',
                    );
                  }
                } catch (_) {
                  if (!context.mounted) return;
                  _showSnackBar(
                    context,
                    'Unable to open support email right now.',
                  );
                }
              },
              child: const Text('Email Support'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showOrderHistoryDialog(BuildContext context) async {
    const entries = [
      {
        'date': 'Yesterday, 18:30',
        'title': 'Order #8832 - Processing',
        'subtitle': '2x Lamb Shank, 1x Apple Tart',
        'price': '\$42.50',
      },
      {
        'date': 'Oct 12, 2023',
        'title': 'Order #7921 - Delivered',
        'subtitle': '1x Miso Salmon, 1x Green Tea',
        'price': '\$28.00',
      },
      {
        'date': 'Oct 05, 2023',
        'title': 'Order #7644 - Delivered',
        'subtitle': 'Chef selection',
        'price': '\$35.20',
      },
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Full Order History',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: MitablColors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ...entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MitablColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry['date']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  entry['title']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry['subtitle']!,
                                  style: const TextStyle(
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            entry['price']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: MitablColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = routeArguments!.customer!;

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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF1F5F9),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back,
                            size: 18, color: MitablColors.onSurfaceVariant),
                        SizedBox(width: 4),
                        Text(
                          'Back to Orders',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Hero Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: MitablColors.onSurface.withValues(alpha: 0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background blob
                        Positioned(
                          top: -64,
                          right: -64,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              color: MitablColors.secondaryContainer
                                  .withValues(alpha: 0.20),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar with rotation and VIP badge
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Transform.rotate(
                                      angle: -0.05,
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: MitablColors
                                                .surfaceContainerLow,
                                            width: 4,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                '${GlobalConfiguration().getValue<String>('image_base_url')}${customer.avatar!}',
                                            fit: BoxFit.cover,
                                            errorWidget: (context, data, e) =>
                                                Container(
                                              color: MitablColors
                                                  .surfaceContainerLow,
                                              child: const Icon(
                                                Icons.person,
                                                size: 40,
                                                color: MitablColors
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            placeholder: (context, s) =>
                                                Container(
                                              color: MitablColors
                                                  .surfaceContainerLow,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // VIP badge
                                    Positioned(
                                      bottom: -8,
                                      right: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF506140),
                                          borderRadius: MitablRadius.pillBorder,
                                          boxShadow: [
                                            BoxShadow(
                                              color: MitablColors.onSurface
                                                  .withValues(alpha: 0.10),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'VIP',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                // Name and info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name.toString(),
                                        style: const TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: MitablColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 16,
                                            color: MitablColors.primary,
                                          ),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Member since 2022',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: MitablColors
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _contactCustomer(
                                        context,
                                        customer.phone,
                                      ),
                                      icon: const Icon(Icons.call, size: 18),
                                      label: const Text(
                                        'Contact Customer',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MitablColors.primary,
                                        foregroundColor: MitablColors.onPrimary,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: MitablRadius.pillBorder,
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _showCreditsSupportDialog(
                                        context,
                                        customer.name?.toString() ?? 'customer',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            MitablColors.surfaceContainerLow,
                                        foregroundColor:
                                            MitablColors.onSurfaceVariant,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: MitablRadius.pillBorder,
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Manage Credits',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats cards row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: MitablColors.secondaryContainer
                                .withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL ORDERS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: MitablColors.onSecondaryContainer,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '24',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: MitablColors.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: MitablColors.onSecondaryContainer
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 28,
                                  color: MitablColors.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: MitablColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AVG. RATING',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.rating?.toStringAsFixed(1) ??
                                        '4.9',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: MitablColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              StarRating(
                                rating: customer.rating ?? 4.9,
                                size: 24,
                                color: MitablColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Customer Preferences
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Preferences',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _PreferenceChip(label: 'Gluten-Free Only'),
                            _PreferenceChip(label: 'No Spicy Food'),
                            _PreferenceChip(label: 'Prefer Local Sourcing'),
                            _PreferenceChip(label: 'Eco-Friendly Packaging'),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          height: 1,
                          color: MitablColors.outlineVariant
                              .withValues(alpha: 0.10),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'PRIVATE VENDOR NOTES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: MitablColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            customer.description?.toString() ??
                                '"Loves extra arugula on everything. Usually orders for Sunday lunch."',
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: MitablColors.onSurface,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Order History
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: MitablColors.onSurface.withValues(alpha: 0.06),
                          blurRadius: 40,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order History',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: MitablColors.onSurface,
                              ),
                            ),
                            Icon(Icons.history,
                                color: MitablColors.onSurfaceVariant),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Timeline items
                        const _OrderTimelineItem(
                          isFirst: true,
                          isActive: true,
                          date: 'Yesterday, 18:30',
                          title: 'Order #8832 - Processing',
                          subtitle: '2x Lamb Shank, 1x Apple Tart',
                          price: '\$42.50',
                          priceHighlight: true,
                        ),
                        const _OrderTimelineItem(
                          isFirst: false,
                          isActive: false,
                          date: 'Oct 12, 2023',
                          title: 'Order #7921 - Delivered',
                          subtitle: '1x Miso Salmon, 1x Green Tea',
                          price: '\$28.00',
                          priceHighlight: false,
                        ),
                        const _OrderTimelineItem(
                          isFirst: false,
                          isActive: false,
                          isLast: true,
                          date: 'Oct 05, 2023',
                          title: 'Order #7644 - Delivered',
                          price: '\$35.20',
                          priceHighlight: false,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _showOrderHistoryDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MitablColors.surfaceContainerLow,
                              foregroundColor: MitablColors.onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'View Full History',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MitablColors.onSurface.withValues(alpha: 0.05),
        borderRadius: MitablRadius.pillBorder,
        border: Border.all(
          color: MitablColors.outlineVariant.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: MitablColors.onSurface,
        ),
      ),
    );
  }
}

class _OrderTimelineItem extends StatelessWidget {
  const _OrderTimelineItem({
    required this.isFirst,
    required this.isActive,
    required this.date,
    required this.title,
    this.subtitle,
    required this.price,
    required this.priceHighlight,
    this.isLast = false,
  });

  final bool isFirst;
  final bool isActive;
  final String date;
  final String title;
  final String? subtitle;
  final String price;
  final bool priceHighlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF506140)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MitablColors.surfaceContainerLowest,
                      width: 4,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: MitablColors.secondaryContainer,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: priceHighlight
                          ? MitablColors.primary
                          : MitablColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
