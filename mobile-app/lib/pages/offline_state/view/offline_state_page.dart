import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MitablColors.surface, // warm oat
              Color(0xFFFFF8F0), // lighter warm cream
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MitablSpacing.pagePadding * 1.5,
            ),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Mitabl logo text at the top
                Text(
                  'Mitabl',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: MitablColors.primary,
                  ),
                ),

                const Spacer(flex: 2),

                // Illustration placeholder: rounded rect with stacked icons
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: MitablColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 60,
                        color: MitablColors.outlineVariant,
                      ),
                      Positioned(
                        bottom: 40,
                        right: 50,
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: 30,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  "Oops! It looks like you're offline.",
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: MitablColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your internet connection and try again.',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: MitablColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 2),

                SizedBox(
                  width: double.infinity,
                  child: MitablButton(
                    label: 'Retry',
                    variant: MitablButtonVariant.primary,
                    fullWidth: true,
                    icon: const Icon(
                      Icons.refresh,
                      color: MitablColors.onPrimary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: MitablButton(
                    label: 'Back to Dashboard',
                    variant: MitablButtonVariant.outline,
                    fullWidth: true,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/DashboardCook',
                      (r) => false,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
