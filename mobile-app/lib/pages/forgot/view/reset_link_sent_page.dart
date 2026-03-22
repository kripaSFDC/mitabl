import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

/// Confirmation screen shown after a password reset link is sent.
class ResetLinkSentPage extends StatelessWidget {
  const ResetLinkSentPage({super.key, this.email = ''});

  final String email;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => ResetLinkSentPage(
        email: routeArguments?.data?.toString() ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Success icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: MitablColors.secondaryContainer
                        .withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 44,
                    color: MitablColors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 28),

                // Heading
                const Text(
                  'Check your email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                    color: MitablColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  "We've sent a password reset link to",
                  style: TextStyle(
                    fontSize: 15,
                    color: MitablColors.onSurfaceVariant
                        .withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MitablColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 36),

                // Back to Login
                MitablButton(
                  label: 'Back to Login',
                  onPressed: () {
                    navigatorKey.currentState!.pushNamedAndRemoveUntil(
                      '/LoginPage',
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Resend link
                MitablButton(
                  label: 'Resend Link',
                  variant: MitablButtonVariant.outline,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reset link resent to your email'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),

                // Chef's Tip card
                MitablCard(
                  color: MitablColors.surfaceContainerLow,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: MitablColors.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tips_and_updates_outlined,
                          size: 18,
                          color: MitablColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Chef's Tip",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: MitablColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Check your "Spam" or "Promotions" folder if you don\'t see the email in your primary inbox within 2 minutes.',
                              style: TextStyle(
                                fontSize: 13,
                                color: MitablColors.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
