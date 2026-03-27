import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';

class SetupPayoutsPage extends StatefulWidget {
  const SetupPayoutsPage({super.key});

  static Route<void> route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => const SetupPayoutsPage(),
    );
  }

  @override
  State<SetupPayoutsPage> createState() => _SetupPayoutsPageState();
}

class _SetupPayoutsPageState extends State<SetupPayoutsPage> {
  bool _isLoading = false;
  bool _stripeCompleted = false;
  String? _errorMessage;

  Future<void> _connectWithStripe() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userRepository = context.read<UserRepository>();
      final headers = await userRepository.authorizedHeaders();
      final uri = ApiContract.uri('vendor/onboarding-link');
      final response = await http.get(uri, headers: headers);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final url = body['data']?['url'] as String? ??
            body['url'] as String? ??
            '';

        if (url.isNotEmpty) {
          final launched = await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
          if (!mounted) return;
          if (launched) {
            setState(() {
              _stripeCompleted = true;
            });
          } else {
            setState(() {
              _errorMessage = 'Could not open the Stripe onboarding page.';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'No onboarding URL received from server.';
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to get onboarding link (${response.statusCode}).';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushNamedAndRemoveUntil('/HomePage', (r) => false);
                      }
                    },
                    icon: const Icon(Icons.arrow_back,
                        color: MitablColors.primary),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Vendor Hub',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: MitablColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1F5F9),
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Hero section
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: MitablColors.secondaryContainer,
                      borderRadius: MitablRadius.pillBorder,
                    ),
                    child: const Text(
                      'ACTION REQUIRED',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: MitablColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: MitablColors.onSurface,
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(text: 'Get paid for your\n'),
                        TextSpan(
                          text: 'Culinary Creations',
                          style: TextStyle(color: MitablColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We use Stripe to ensure your earnings are transferred safely and quickly. Set up your secure payout method in under 5 minutes.',
                    style: TextStyle(
                      fontSize: 16,
                      color: MitablColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Progress Stepper
                  _ProgressStepper(currentStep: _stripeCompleted ? 2 : 1),
                  const SizedBox(height: 40),

                  // Step cards
                  Row(
                    children: [
                      Expanded(
                          child: _StepCard(
                        icon: Icons.person_outline,
                        title: 'Identity',
                        description:
                            'A quick scan of your ID to confirm your business details.',
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StepCard(
                        icon: Icons.account_balance_outlined,
                        title: 'Bank Details',
                        description:
                            'Securely link the account where you\'ll receive your weekly earnings.',
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StepCard(
                        icon: Icons.verified_user_outlined,
                        title: 'Verification',
                        description:
                            'Stripe finalizes the check and your account is ready for payouts.',
                      )),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MitablColors.error.withValues(alpha: 0.08),
                        borderRadius: MitablRadius.cardBorder,
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: MitablColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // CTA container
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: MitablColors.onSurface
                              .withValues(alpha: 0.04),
                          blurRadius: 48,
                          offset: const Offset(0, 12),
                        ),
                      ],
                      border: Border(
                        top: BorderSide(
                          color: MitablColors.primary,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Stripe text label
                        const Text(
                          'stripe',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF635BFF),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Click below to be redirected to Stripe\'s secure portal to complete your onboarding.',
                          style: TextStyle(
                            fontSize: 14,
                            color: MitablColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        if (!_stripeCompleted) ...[
                          // Connect with Stripe button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: MitablColors.primaryGradient,
                                borderRadius: MitablRadius.pillBorder,
                                boxShadow: [
                                  BoxShadow(
                                    color: MitablColors.primary
                                        .withValues(alpha: 0.20),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: MitablRadius.pillBorder,
                                  onTap:
                                      _isLoading ? null : _connectWithStripe,
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child:
                                                CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Text(
                                                'Connect with Stripe',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: MitablColors
                                                      .onPrimary,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Icon(
                                                Icons.arrow_forward,
                                                color:
                                                    MitablColors.onPrimary,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Next step
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: MitablColors.primaryGradient,
                                borderRadius: MitablRadius.pillBorder,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: MitablRadius.pillBorder,
                                  onTap: () {
                                    Navigator.of(context)
                                        .pushNamed('/KitchenCertification');
                                  },
                                  child: const Center(
                                    child: Text(
                                      'Next: Certification',
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
                        ],
                        const SizedBox(height: 24),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                            children: const [
                              TextSpan(
                                  text:
                                      'By clicking connect, you agree to our '),
                              TextSpan(
                                text: 'Vendor Terms',
                                style: TextStyle(
                                    decoration: TextDecoration.underline),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Stripe Services Agreement',
                                style: TextStyle(
                                    decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Skip for now (when not completed)
                  if (!_stripeCompleted) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamed('/KitchenCertification');
                        },
                        child: const Text(
                          'Skip for Now',
                          style: TextStyle(
                            color: MitablColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStepper extends StatelessWidget {
  const _ProgressStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = ['Connect', 'Identity', 'Bank Info', 'Verify'];
    return SizedBox(
      height: 60,
      child: Stack(
        children: [
          // Background line
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              color: const Color(0xFFF1F5F9),
            ),
          ),
          // Active progress line
          Positioned(
            top: 20,
            left: 0,
            child: Container(
              height: 4,
              width: MediaQuery.of(context).size.width *
                  0.25 *
                  currentStep /
                  steps.length,
              color: MitablColors.primary,
            ),
          ),
          // Step dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (i) {
              final isActive = i < currentStep;
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? MitablColors.primary
                          : const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? MitablColors.primary
                          : MitablColors.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: MitablColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MitablColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MitablColors.primary, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: MitablColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: MitablColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
