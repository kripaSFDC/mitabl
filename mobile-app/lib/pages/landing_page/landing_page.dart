import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  Route route() {
    return MaterialPageRoute(
      builder: (context) {
        return const LandingPage();
      },
    );
  }

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  List<Map<String, dynamic>> _featuredCooks = const [];
  bool _isLoadingCooks = true;

  Future<void> _launchInBrowser(Uri url) async {
    try {
      final launched =
          await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${url.toString()}')),
        );
      }
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${url.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _launchInBrowser(Uri.parse(ApiContract.webUrl('terms')));
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _launchInBrowser(Uri.parse(ApiContract.webUrl('privacy-policy')));
      };
    _loadFeaturedCooks();
  }

  Future<void> _loadFeaturedCooks() async {
    try {
      final url = ApiContract.uri('v2/discovery/recommended');
      final response =
          await http.get(url).timeout(ApiContract.requestTimeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> items = const [];
        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            items = data['recommended_resturant_list'] ??
                data['items'] ??
                const [];
          } else if (data is List) {
            items = data;
          }
          if (items.isEmpty &&
              decoded['recommended_resturant_list'] is List) {
            items = decoded['recommended_resturant_list'];
          }
        } else if (decoded is List) {
          items = decoded;
        }
        if (mounted) {
          setState(() {
            _featuredCooks = items
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            _isLoadingCooks = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingCooks = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCooks = false);
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Top bar spacer ──
              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 56),
              ),

              // ── Hero Section ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                            color: MitablColors.onSurface,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                          children: [
                            TextSpan(text: 'Taste the heart\nof your\n'),
                            TextSpan(
                              text: 'neighborhood.',
                              style: TextStyle(color: MitablColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Experience authentic, home-cooked meals prepared by passionate local chefs. From family secrets to modern twists, discover the soul of community dining.',
                        style: TextStyle(
                          fontSize: 14,
                          color: MitablColors.onSurfaceVariant
                              .withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CTA buttons — Get Started + Login
                      Row(
                        children: [
                          Expanded(
                            child: MitablButton(
                              label: 'Get Started',
                              onPressed: () => navigatorKey.currentState!
                                  .pushNamed('/SignUpPage'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MitablButton(
                              label: 'Login',
                              variant: MitablButtonVariant.outline,
                              onPressed: () => navigatorKey.currentState!
                                  .pushNamed('/LoginPage'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Food Photo Grid ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: _buildFoodPhotoGrid(),
                ),
              ),

              // ── "LOCAL FIRST" + Curated Section ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LOCAL FIRST',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Curated by\nneighbors, for\nneighbors.',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                          color: MitablColors.onSurface,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Every chef on Mitabl is verified for quality and safety, bringing you the same love they put into their own family\'s dinner.',
                        style: TextStyle(
                          fontSize: 14,
                          color: MitablColors.onSurfaceVariant
                              .withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Avatar stack with count
                      Row(
                        children: [
                          _buildAvatarStack(),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MitablColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Text(
                              '+24',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Feature Cards ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    children: [
                      // Zero-Waste Prep card
                      MitablCard(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: MitablColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.eco_outlined,
                                  color: MitablColors.onSecondaryContainer,
                                  size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Zero-Waste Prep',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: MitablColors.onSurface,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Cooked to order, reducing food waste in your community.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: MitablColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Authentic Flavors card
                      MitablCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Authentic Flavors',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                MitablChip(label: 'Family Recipe'),
                                MitablChip(label: 'Small Batch'),
                                MitablChip(label: 'Local Herbs'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Culinary Atelier Hero Image ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: ClipRRect(
                    borderRadius: MitablRadius.cardBorder,
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: MitablColors.primary.withValues(alpha: 0.15),
                        borderRadius: MitablRadius.cardBorder,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  MitablColors.onSurface.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                          // Text overlay
                          const Positioned(
                            left: 20,
                            right: 20,
                            bottom: 20,
                            child: Text(
                              'Bringing the culinary\natelier experience to your\ndoorstep.',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Nunito',
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Happening Now Section ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Happening now.',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Nunito',
                              color: MitablColors.onSurface,
                            ),
                          ),
                          TextButton(
                            onPressed: () => navigatorKey.currentState!
                                .pushNamed('/SignUpPage'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'View All Menus',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: MitablColors.primary,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward,
                                    size: 16, color: MitablColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explore meals being prepared in your area today.',
                        style: TextStyle(
                          fontSize: 13,
                          color: MitablColors.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── Cook Menu Cards ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildHappeningNowCards(),
                ),
              ),

              // ── Terms / Privacy ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'By signing up, you agree to our ',
                      style: const TextStyle(
                        color: MitablColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          recognizer: _termsRecognizer,
                          style: const TextStyle(
                            color: MitablColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          recognizer: _privacyRecognizer,
                          style: const TextStyle(
                            color: MitablColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),

          // ── Sticky top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: MitablGlass.blur,
        child: Container(
          color: MitablGlass.background,
          padding: EdgeInsets.only(
            top: topPadding + 8,
            bottom: 8,
            left: 24,
            right: 16,
          ),
          child: Row(
            children: [
              const Text(
                'Mitabl',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                  color: MitablColors.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.menu,
                    color: MitablColors.onSurface, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    final colors = [
      MitablColors.primary,
      MitablColors.secondaryContainer,
      MitablColors.tertiaryFixedDim,
      const Color(0xFF6B7280),
    ];
    return SizedBox(
      width: 92,
      height: 36,
      child: Stack(
        children: List.generate(4, (i) {
          return Positioned(
            left: i * 18.0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: MitablColors.surface,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFoodPhotoGrid() {
    // 2x3 grid of food photography placeholders with warm tonal colors
    final items = [
      {'color': const Color(0xFF8B4513), 'icon': Icons.ramen_dining},
      {'color': const Color(0xFFC75B39), 'icon': Icons.local_pizza},
      {'color': const Color(0xFF6B8E23), 'icon': Icons.set_meal},
      {'color': const Color(0xFFD4A574), 'icon': Icons.bakery_dining},
      {'color': const Color(0xFF9C3E20), 'icon': Icons.dinner_dining},
      {'color': const Color(0xFF8FBC8F), 'icon': Icons.soup_kitchen},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: 6,
      itemBuilder: (_, i) {
        final item = items[i];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: (item['color'] as Color).withValues(alpha: 0.85),
            child: Icon(
              item['icon'] as IconData,
              color: Colors.white.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHappeningNowCards() {
    if (_isLoadingCooks) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: MitablColors.primary),
        ),
      );
    }

    final baseUrl = GlobalConfiguration().getValue<String>('base_url');

    // Use real data or fallback
    final List<Map<String, dynamic>> cooks;
    if (_featuredCooks.isNotEmpty) {
      cooks = _featuredCooks.take(3).toList();
    } else {
      cooks = const [
        {
          'name': 'Slow-Roasted Ragù',
          'description':
              'A 12-hour simmered beef ragù using my nonna\'s secret spice blend and local San...',
          'price': 15,
          'ready_time': '45m',
          'distance': '8.2',
        },
        {
          'name': 'Honey Glazed Salmon',
          'description':
              'Wild-caught salmon with a wildflower honey glaze, served with grilled seasonal asparagus.',
          'price': 22,
          'ready_time': '20m',
          'distance': '3.1',
        },
        {
          'name': 'Curry Laksa Bowl',
          'description':
              'Spicy coconut noodle soup with poached chicken, tofu puffs, and fresh Vietnamese...',
          'price': 15,
          'ready_time': '7 PM',
          'distance': '2.8',
        },
      ];
    }

    return Column(
      children: cooks.asMap().entries.map((entry) {
        final cook = entry.value;
        final isReal = _featuredCooks.isNotEmpty;

        // Extract data
        String name, desc, distanceLabel;
        double price;
        String readyTime;
        String? imageUrl;

        if (isReal) {
          name = (cook['name'] ?? 'Kitchen').toString();
          desc = (cook['description'] ?? '').toString();
          price = 0;
          distanceLabel =
              cook['distance'] != null ? '${cook['distance']} miles away' : '';
          readyTime = '';

          // Try to get food items for dish name + price
          final foods = cook['foods'];
          if (foods is List && foods.isNotEmpty) {
            final firstFood = foods.first;
            if (firstFood is Map) {
              name = (firstFood['food_name'] ?? name).toString();
              price = double.tryParse(
                      (firstFood['price'] ?? '0').toString()) ??
                  0;
              desc = (firstFood['description'] ?? desc).toString();
            }
          }

          // Image
          final images = cook['images'];
          if (images is List && images.isNotEmpty) {
            final first = images.first;
            final path = first is Map
                ? (first['path'] ?? '').toString()
                : first.toString();
            if (path.isNotEmpty) imageUrl = '$baseUrl/$path';
          }
        } else {
          name = cook['name'] as String;
          desc = cook['description'] as String;
          price = (cook['price'] as int).toDouble();
          readyTime = cook['ready_time'] as String;
          distanceLabel = '${cook['distance']} miles away';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MitablCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: MitablColors.primary.withValues(alpha: 0.12),
                        child: imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: Icon(Icons.restaurant,
                                      size: 40,
                                      color: MitablColors.onSurfaceVariant),
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.restaurant,
                                      size: 40,
                                      color: MitablColors.onSurfaceVariant),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.restaurant,
                                    size: 40,
                                    color: MitablColors.onSurfaceVariant),
                              ),
                      ),
                    ),
                    // Distance badge
                    if (distanceLabel.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: MitablColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            distanceLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: MitablColors.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Nunito',
                                color: MitablColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (price > 0)
                            Text(
                              '\$${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 13,
                          color: MitablColors.onSurfaceVariant
                              .withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (readyTime.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14,
                                color: MitablColors.onSurfaceVariant
                                    .withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'Ready in $readyTime',
                              style: TextStyle(
                                fontSize: 12,
                                color: MitablColors.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
