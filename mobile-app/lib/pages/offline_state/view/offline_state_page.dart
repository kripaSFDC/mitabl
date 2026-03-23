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
      backgroundColor: MitablColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MitablSpacing.pagePadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 80,
                  color: MitablColors.onSurfaceVariant,
                ),
                const SizedBox(height: 32),
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
                const SizedBox(height: 40),
                MitablButton(
                  label: 'Retry',
                  variant: MitablButtonVariant.primary,
                  icon: const Icon(
                    Icons.refresh,
                    color: MitablColors.onPrimary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
                MitablButton(
                  label: 'Back to Dashboard',
                  variant: MitablButtonVariant.outline,
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/DashboardCook',
                    (r) => false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
