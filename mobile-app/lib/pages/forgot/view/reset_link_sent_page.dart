import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

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
      body: Stack(
        children: [
          // Background decorative blurs
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.width * 0.4,
              decoration: BoxDecoration(
                color: MitablColors.secondaryContainer.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mitabl',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: MitablColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),

                    // Grill icon with glow
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Glow behind
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD5)
                                .withValues(alpha: 0.30),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Main icon container
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: MitablColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: MitablColors.onSurface
                                    .withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.outdoor_grill,
                            size: 56,
                            color: MitablColors.primary,
                          ),
                        ),
                        // Steam / air decoration
                        Positioned(
                          top: -16,
                          right: -8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.air,
                                size: 20,
                                color: MitablColors.primary
                                    .withValues(alpha: 0.40),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.air,
                                  size: 16,
                                  color: MitablColors.primary
                                      .withValues(alpha: 0.40),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Heading
                    const Text(
                      'Check your email',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: MitablColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 17,
                            color: MitablColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  "We've sent a password reset link to ",
                            ),
                            if (email.isNotEmpty)
                              TextSpan(
                                text: email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.onSurface,
                                ),
                              ),
                            const TextSpan(
                              text:
                                  '. Please check your inbox and follow the instructions.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Back to Login button (gradient primary)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: MitablColors.primaryGradient,
                          borderRadius: MitablRadius.pillBorder,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  MitablColors.primary.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: MitablRadius.pillBorder,
                            onTap: () {
                              navigatorKey.currentState!
                                  .pushNamedAndRemoveUntil(
                                '/LoginPage',
                                (route) => false,
                              );
                            },
                            child: const Center(
                              child: Text(
                                'Back to Login',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Resend link section
                    Text(
                      "Didn't receive the email?",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Reset link resent to your email'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
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
                          'Resend Link',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Chef's Tip card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: MitablColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Background watermark icon
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(
                              Icons.lightbulb_outline,
                              size: 48,
                              color: MitablColors.onSurface
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.tips_and_updates_outlined,
                                    size: 16,
                                    color: MitablColors.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Chef's Tip",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: MitablColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check your "Spam" or "Promotions" folder if you don\'t see the email in your primary inbox within 2 minutes.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: MitablColors.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
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
        ],
      ),
    );
  }
}
