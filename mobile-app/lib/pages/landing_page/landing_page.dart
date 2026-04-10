import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
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
  late final GlobalKey<ScaffoldState> _scaffoldKey;
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
    _scaffoldKey = GlobalKey<ScaffoldState>();
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
      key: _scaffoldKey,
      backgroundColor: MitablColors.surface,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Top bar spacer ──
              SliverToBoxAdapter(
                child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 60),
              ),

              // ── Hero Section ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Hero headline – text-5xl = 48px on mobile
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito',
                            color: MitablColors.onSurface,
                            height: 1.1,
                            letterSpacing: -1.0,
                          ),
                          children: [
                            TextSpan(text: 'Taste the\nheart of your '),
                            TextSpan(
                              text: 'neighborhood.',
                              style: TextStyle(
                                color: MitablColors.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subtitle – text-lg = 18px
                      const Text(
                        'Experience authentic, home-cooked meals prepared by passionate local chefs. From family secrets to modern twists, discover the soul of community dining.',
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'DM Sans',
                          color: MitablColors.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // CTA buttons
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          // Get Started – primary pill
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => navigatorKey.currentState!
                                  .pushNamed('/SignUpPage'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MitablColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor:
                                    MitablColors.primary.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40),
                              ),
                              child: const Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ),
                          ),
                          // Login – secondary-container pill
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => navigatorKey.currentState!
                                  .pushNamed('/LoginPage'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    MitablColors.secondaryContainer,
                                foregroundColor:
                                    MitablColors.onSecondaryContainer,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Food Photo Grid (2-column editorial) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: _buildEditorialImageGrid(),
                ),
              ),

              // ── Bento Grid Features ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                  child: Column(
                    children: [
                      // Large "Local First" feature card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'LOCAL FIRST',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF431407),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Curated by neighbors, for neighbors.',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Nunito',
                                color: MitablColors.onSurface,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Every chef on Mitabl is verified for quality and safety, bringing you the same love they put into their own family's dinner.",
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'DM Sans',
                                color: MitablColors.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Avatar stack
                            _buildAvatarStack(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Two small feature cards in a row
                      Row(
                        children: [
                          // Zero-Waste Prep
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: MitablColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.eco,
                                      size: 48,
                                      color: Color(0xFF506140)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Zero-Waste Prep',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Nunito',
                                      color: MitablColors.onSecondaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Cooked to order, reducing food waste in your community.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'DM Sans',
                                      color: MitablColors.onSecondaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Authentic Flavors
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Authentic Flavors',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Nunito',
                                      color: Color(0xFF431407),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildFlavorTag('Family Recipe'),
                                      _buildFlavorTag('Small Batch'),
                                      _buildFlavorTag('Local Herbs'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Culinary Atelier hero image card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 300,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: MitablColors.surfaceContainerLow,
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
                                      Colors.black.withValues(alpha: 0.1),
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: 24,
                                left: 24,
                                right: 24,
                                child: Text(
                                  'Bringing the culinary atelier experience to your doorstep.',
                                  style: TextStyle(
                                    fontSize: 24,
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
                    ],
                  ),
                ),
              ),

              // ── Happening Now Section ──
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 48),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 48),
                  color: const Color(0xFFF1F5F9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Happening now.',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                  color: MitablColors.onSurface,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Explore meals being prepared in your area today.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'DM Sans',
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => navigatorKey.currentState!
                                .pushNamed('/SignUpPage'),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View All Menus',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.primary,
                                    fontFamily: 'DM Sans',
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward,
                                    size: 18, color: MitablColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildHappeningNowCards(),
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
                        fontFamily: 'DM Sans',
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

          // ── Bottom nav bar (mobile) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: MitablColors.primary,
            ),
            child: Text(
              'mitabl',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Get Started'),
            onTap: () {
              Navigator.pop(context);
              navigatorKey.currentState?.pushNamed('/SignUpPage');
            },
          ),
          ListTile(
            title: const Text('Login'),
            onTap: () {
              Navigator.pop(context);
              navigatorKey.currentState?.pushNamed('/LoginPage');
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Terms of Service'),
            onTap: () {
              Navigator.pop(context);
              _launchInBrowser(Uri.parse(ApiContract.webUrl('terms')));
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pop(context);
              _launchInBrowser(Uri.parse(ApiContract.webUrl('privacy-policy')));
            },
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
            top: topPadding + 12,
            bottom: 12,
            left: 24,
            right: 24,
          ),
          child: Row(
            children: [
              const Text(
                'mitabl',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Nunito',
                  color: MitablColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu,
                    color: MitablColors.onSurfaceVariant, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: MitablGlass.blur,
        child: Container(
          decoration: BoxDecoration(
            color: MitablGlass.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 12,
            bottom: bottomPadding + 24,
            left: 16,
            right: 16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Welcome (active)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: MitablColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bakery_dining, color: Colors.white, size: 24),
                    SizedBox(height: 2),
                    Text(
                      'WELCOME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DM Sans',
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Join (inactive)
              GestureDetector(
                onTap: () =>
                    navigatorKey.currentState!.pushNamed('/SignUpPage'),
                child: const Opacity(
                  opacity: 0.7,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add,
                          color: MitablColors.onSurfaceVariant, size: 24),
                      SizedBox(height: 2),
                      Text(
                        'JOIN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DM Sans',
                          letterSpacing: 0.5,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Support (inactive)
              const Opacity(
                opacity: 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline,
                        color: MitablColors.onSurfaceVariant, size: 24),
                    SizedBox(height: 2),
                    Text(
                      'SUPPORT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'DM Sans',
                        letterSpacing: 0.5,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorialImageGrid() {
    // Two columns with staggered heights matching the HTML
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              // h-64 = 256px
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 256,
                  color: MitablColors.surfaceContainerLow,
                  child: const Center(
                    child: Icon(Icons.ramen_dining,
                        size: 48,
                        color: MitablColors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // h-48 = 192px
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 192,
                  color: MitablColors.surfaceContainerLow,
                  child: const Center(
                    child: Icon(Icons.local_pizza,
                        size: 48,
                        color: MitablColors.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right column (offset down – pt-12 = 48px top padding)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              children: [
                // h-48 = 192px
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 192,
                    color: MitablColors.surfaceContainerLow,
                    child: const Center(
                      child: Icon(Icons.local_pizza,
                          size: 48,
                          color: MitablColors.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // h-64 = 256px
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 256,
                    color: MitablColors.surfaceContainerLow,
                    child: const Center(
                      child: Icon(Icons.set_meal,
                          size: 48,
                          color: MitablColors.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarStack() {
    return Row(
      children: [
        SizedBox(
          width: 124,
          height: 48,
          child: Stack(
            children: [
              ...List.generate(3, (i) {
                return Positioned(
                  left: i * 28.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: [
                        MitablColors.primary,
                        MitablColors.secondaryContainer,
                        MitablColors.tertiaryFixedDim,
                      ][i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MitablColors.surface,
                        width: 4,
                      ),
                    ),
                    child: const Icon(Icons.person,
                        size: 20, color: Colors.white),
                  ),
                );
              }),
              // +24 circle
              Positioned(
                left: 3 * 28.0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MitablColors.surface,
                      width: 4,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '+24',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF431407),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlavorTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: MitablColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF431407),
        ),
      ),
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
          'name': 'Slow-Roasted Ragu',
          'description':
              'A 12-hour simmered beef ragu using my nonna\'s secret spice blend and local San Marzano tomatoes.',
          'price': 18,
          'ready_time': '45m',
          'distance': '4.2',
        },
        {
          'name': 'Honey Glazed Salmon',
          'description':
              'Wild-caught salmon with a wildflower honey glaze, served with grilled seasonal asparagus.',
          'price': 22,
          'ready_time': '20m',
          'distance': '1.8',
        },
        {
          'name': 'Curry Laksa Bowl',
          'description':
              'Spicy coconut noodle soup with poached chicken, tofu puffs, and fresh Vietnamese mint.',
          'price': 15,
          'ready_time': '7 PM',
          'distance': '0.5',
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
          padding: const EdgeInsets.only(bottom: 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food image – h-56 = 224px
                Stack(
                  children: [
                    Container(
                      height: 224,
                      width: double.infinity,
                      color: MitablColors.surfaceContainerLow,
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
                    // Distance badge
                    if (distanceLabel.isNotEmpty)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: BackdropFilter(
                            filter: MitablGlass.blur,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                distanceLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.primary,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Content – p-6 = 24px
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DM Sans',
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
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: MitablColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          color: MitablColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (readyTime.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 14,
                                color: MitablColors.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(
                              readyTime.contains('PM')
                                  ? 'Pre-order for $readyTime'
                                  : 'Ready in $readyTime',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'DM Sans',
                                color: MitablColors.onSurfaceVariant,
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
