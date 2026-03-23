import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';

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
          _errorMessage = 'Failed to get onboarding link (${response.statusCode}).';
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
      appBar: const GlassAppBar(title: Text('Setup Payouts')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: MitablSpacing.pagePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Step indicator ──
            const Text(
              'Step 2 of 3',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MitablColors.onSurfaceVariant,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: MitablRadius.pillBorder,
              child: LinearProgressIndicator(
                value: 0.65,
                color: MitablColors.primary,
                backgroundColor:
                    MitablColors.outlineVariant.withValues(alpha: 0.3),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 24),

            // ── Heading ──
            Text(
              'Get Paid for Your\nCulinary Creations',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: MitablColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect your bank account through Stripe to receive payments',
              style: TextStyle(
                fontSize: 14,
                color: MitablColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // ── Identity Card ──
            MitablCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: MitablColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Verification',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verify your identity to get started',
                          style: TextStyle(
                            fontSize: 13,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MitablChip(
                    label: _stripeCompleted ? 'Done' : 'Pending',
                    selected: _stripeCompleted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MitablSpacing.listItem),

            // ── Bank Details Card ──
            MitablCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: MitablColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bank Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add your bank details for payouts',
                          style: TextStyle(
                            fontSize: 13,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MitablChip(
                    label: _stripeCompleted ? 'Done' : 'Pending',
                    selected: _stripeCompleted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MitablSpacing.listItem),

            // ── Verification Card ──
            MitablCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: MitablColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Verification',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: MitablColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stripe will verify your account to enable payouts',
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
            const SizedBox(height: 32),

            // ── Error message ──
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

            // ── Action Buttons ──
            if (!_stripeCompleted) ...[
              MitablButton(
                label: 'Connect with Stripe',
                variant: MitablButtonVariant.primary,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _connectWithStripe,
              ),
              const SizedBox(height: 12),
              MitablButton(
                label: 'Skip for Now',
                variant: MitablButtonVariant.outline,
                onPressed: () {
                  Navigator.of(context).pushNamed('/KitchenCertification');
                },
              ),
            ] else ...[
              MitablButton(
                label: 'Check Verification Status',
                variant: MitablButtonVariant.outline,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _connectWithStripe,
              ),
              const SizedBox(height: 12),
              MitablButton(
                label: 'Next: Certification',
                variant: MitablButtonVariant.primary,
                onPressed: () {
                  Navigator.of(context).pushNamed('/KitchenCertification');
                },
              ),
            ],
            const SizedBox(height: MitablSpacing.breathe),
          ],
        ),
      ),
    );
  }
}
