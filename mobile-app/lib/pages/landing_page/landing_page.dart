import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
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

  Future<void> _launchInBrowser(Uri url) async {
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
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
          // ── Scrollable content ──
          CustomScrollView(
            slivers: [
              // ── Hero section ──
              SliverToBoxAdapter(
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.78,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        MitablColors.primary.withValues(alpha: 0.08),
                        MitablColors.surface,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 72),

                          // Hero heading
                          const Text(
                            'Taste the\nheart of your\nneighborhood.',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Nunito',
                              color: MitablColors.onSurface,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Home-cooked meals from passionate\ncooks in your community.',
                            style: TextStyle(
                              fontSize: 16,
                              color: MitablColors.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // CTA buttons
                          MitablButton(
                            label: "I'm a Foodie — Join Free",
                            onPressed: () => navigatorKey.currentState!
                                .pushNamed('/SignUpPage'),
                          ),
                          const SizedBox(height: 12),
                          MitablButton(
                            label: "I'm a Cook — Start Selling",
                            variant: MitablButtonVariant.outline,
                            onPressed: () => navigatorKey.currentState!
                                .pushNamed('/SignUpPage'),
                          ),

                          const Spacer(),

                          // Avatar stack + social proof
                          Row(
                            children: [
                              _buildAvatarStack(),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  '500+ home cooks already sharing their craft',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: MitablColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── "What's Cooking" section ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Curated by your neighbours',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real meals from real kitchens, made with love.',
                        style: TextStyle(
                          fontSize: 14,
                          color: MitablColors.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFoodGrid(),
                    ],
                  ),
                ),
              ),

              // ── Featured Cooks section ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Happening now',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Nunito',
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCookCards(),
                    ],
                  ),
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

              // Bottom padding for sticky bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── Sticky top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context),
          ),

          // ── Sticky bottom bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  // ── Helper builders ──

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
              TextButton(
                onPressed: () =>
                    navigatorKey.currentState!.pushNamed('/LoginPage'),
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MitablColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: MitablGlass.blur,
        child: Container(
          color: MitablGlass.background,
          padding: EdgeInsets.only(
            bottom: bottomPadding + 12,
            top: 12,
            left: 24,
            right: 24,
          ),
          child: Row(
            children: [
              Expanded(
                child: MitablButton(
                  label: 'Sign Up',
                  onPressed: () =>
                      navigatorKey.currentState!.pushNamed('/SignUpPage'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MitablButton(
                  label: 'Log In',
                  variant: MitablButtonVariant.outline,
                  onPressed: () =>
                      navigatorKey.currentState!.pushNamed('/LoginPage'),
                ),
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
    ];
    return SizedBox(
      width: 72,
      height: 36,
      child: Stack(
        children: List.generate(3, (i) {
          return Positioned(
            left: i * 20.0,
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

  Widget _buildFoodGrid() {
    const items = [
      {'icon': Icons.ramen_dining, 'label': 'Authentic Ramen'},
      {'icon': Icons.bakery_dining, 'label': 'Fresh Pastries'},
      {'icon': Icons.set_meal, 'label': 'Home-style Curry'},
      {'icon': Icons.local_pizza, 'label': 'Wood-fired Pizza'},
    ];
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) {
        return MitablCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item['icon'] as IconData,
                size: 32,
                color: MitablColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                item['label'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MitablColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCookCards() {
    const cooks = [
      {'name': 'Maria G.', 'cuisine': 'Mexican • Oaxacan', 'rating': '4.9'},
      {'name': 'David L.', 'cuisine': 'Vegan • Bakery', 'rating': '4.8'},
      {'name': "Nonna's", 'cuisine': 'Italian • Pasta', 'rating': '5.0'},
    ];
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cooks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final cook = cooks[i];
          return SizedBox(
            width: 200,
            child: MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            MitablColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person,
                            color: MitablColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cook['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: MitablColors.onSurface,
                              ),
                            ),
                            Text(
                              cook['cuisine']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: MitablColors.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        cook['rating']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MitablColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Open',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MitablColors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
