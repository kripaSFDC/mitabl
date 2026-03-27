import 'package:flutter/material.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class OfflineStatePage extends StatelessWidget {
  const OfflineStatePage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => const OfflineStatePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: Stack(
        children: [
          // Decorative organic blurs
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            right: 0,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: const Color(0xFFB9CDA4).withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                color: const Color(0xFFB9CDA4).withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // TopAppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.lock_outlined,
                          color: MitablColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mitabl',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: MitablColors.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.refresh,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration container with tonal layering
                    SizedBox(
                      width: 256,
                      height: 256,
                      child: Stack(
                        children: [
                          // Back rotated shape
                          Positioned.fill(
                            child: Transform.rotate(
                              angle: 0.1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: MitablColors.secondaryContainer
                                      .withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          // Middle rotated shape
                          Positioned.fill(
                            child: Transform.rotate(
                              angle: -0.05,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB599)
                                      .withValues(alpha: 0.30),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          // Main illustration card
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: MitablColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: MitablColors.onSurface
                                        .withValues(alpha: 0.06),
                                    blurRadius: 40,
                                    offset: const Offset(0, 24),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    // Placeholder illustration
                                    Center(
                                      child: Icon(
                                        Icons.restaurant_rounded,
                                        size: 80,
                                        color: MitablColors.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    // Disconnected badge
                                    Positioned(
                                      bottom: 16,
                                      right: 16,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: MitablColors.surface
                                              .withValues(alpha: 0.80),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.signal_wifi_off_rounded,
                                          color: MitablColors.primary,
                                          size: 24,
                                        ),
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
                    const SizedBox(height: 40),

                    // Heading
                    const Text(
                      "Oops! It looks like you're offline.",
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: MitablColors.onSurface,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    SizedBox(
                      width: 280,
                      child: Text(
                        'Please check your internet connection and try again.',
                        style: TextStyle(
                          fontSize: 17,
                          color: MitablColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Retry button (gradient primary)
                    SizedBox(
                      width: 256,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: MitablColors.primaryGradient,
                          borderRadius: MitablRadius.pillBorder,
                          boxShadow: [
                            BoxShadow(
                              color: MitablColors.primary
                                  .withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: MitablRadius.pillBorder,
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.sync,
                                  color: MitablColors.onPrimary,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: MitablColors.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Back to Dashboard (secondary)
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/DashboardCook',
                          (r) => false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MitablColors.secondaryContainer,
                          foregroundColor:
                              MitablColors.onSecondaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: MitablRadius.pillBorder,
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'BACK TO DASHBOARD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
