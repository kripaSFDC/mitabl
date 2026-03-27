import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/pages/payments/element/visual_credit_card.dart';
import 'package:mitabl_user/repos/payments_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class AddPaymentMethodPage extends StatefulWidget {
  const AddPaymentMethodPage({super.key});

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => const AddPaymentMethodPage(),
    );
  }

  @override
  State<AddPaymentMethodPage> createState() => _AddPaymentMethodPageState();
}

class _AddPaymentMethodPageState extends State<AddPaymentMethodPage> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _nameController = TextEditingController();
  bool _setAsDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onFieldChanged);
    _expiryController.addListener(_onFieldChanged);
    _cvcController.addListener(_onFieldChanged);
    _nameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last4 = _cardNumberController.text.length >= 4
        ? _cardNumberController.text
            .replaceAll(' ', '')
            .substring(
              _cardNumberController.text.replaceAll(' ', '').length >= 4
                  ? _cardNumberController.text.replaceAll(' ', '').length - 4
                  : 0,
            )
        : '';
    final expiryParts = _expiryController.text.split('/');
    final expMonth = expiryParts.isNotEmpty ? expiryParts[0].trim() : '';
    final expYear = expiryParts.length > 1 ? expiryParts[1].trim() : '';

    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: const GlassAppBar(title: Text('miFoodi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        child: Column(
          children: [
            // ── Header Section: Editorial Authority ──
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  Text(
                    'Add New Card',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: MitablColors.onSurface,
                      fontFamily: 'Nunito',
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Securely save your payment details for a faster checkout experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // ── Card form area ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MitablColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: MitablColors.onSurface.withValues(alpha: 0.04),
                    blurRadius: 48,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Secure Badge ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: MitablColors.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: MitablRadius.pillBorder,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 14,
                          color: const Color(0xFF506140),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'BANK-LEVEL SECURITY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            color: Color(0xFF3B4C2C),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Visual Card Preview (tilted) ──
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Shadow layer
                      Positioned(
                        top: 8,
                        left: 8,
                        right: -8,
                        bottom: -8,
                        child: Transform.rotate(
                          angle: 0.035,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFB9CDA4).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      // Card
                      Transform.rotate(
                        angle: -0.017,
                        child: VisualCreditCard(
                          brand: _detectBrand(_cardNumberController.text),
                          last4: last4,
                          expMonth: expMonth,
                          expYear: expYear,
                          cardholderName: _nameController.text,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Card Number ──
                  MitablTextField(
                    controller: _cardNumberController,
                    label: 'Card Number',
                    hint: '0000 0000 0000 0000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                    suffixIcon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.credit_card,
                          color: Color(0xFF64748B)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Expiry + CVC row ──
                  Row(
                    children: [
                      Expanded(
                        child: MitablTextField(
                          controller: _expiryController,
                          label: 'Expiry Date',
                          hint: 'MM / YY',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _ExpiryFormatter(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MitablTextField(
                          controller: _cvcController,
                          label: 'CVC / CVV',
                          hint: '\u2022\u2022\u2022',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.help_outline,
                                color: Color(0xFF64748B), size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Cardholder Name ──
                  MitablTextField(
                    controller: _nameController,
                    label: 'Cardholder Name',
                    hint: 'e.g. Julian Casablancas',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.done,
                  ),

                  const SizedBox(height: 20),

                  // ── Set as default checkbox ──
                  GestureDetector(
                    onTap: () {
                      setState(() => _setAsDefault = !_setAsDefault);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _setAsDefault
                                ? const Color(0xFF506140)
                                : MitablColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                            border: _setAsDefault
                                ? null
                                : Border.all(
                                    color: MitablColors.outlineVariant,
                                    width: 2,
                                  ),
                          ),
                          child: _setAsDefault
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Set as default payment method',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── CTA Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _isSaving
                            ? null
                            : MitablColors.primaryGradient,
                        color: _isSaving
                            ? MitablColors.tertiaryFixedDim
                            : null,
                        borderRadius: MitablRadius.pillBorder,
                        boxShadow: _isSaving
                            ? null
                            : [
                                BoxShadow(
                                  color: MitablColors.primary
                                      .withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: MitablRadius.pillBorder,
                          onTap: _isSaving ? null : _saveCard,
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: MitablColors.onPrimary,
                                    ),
                                  )
                                : const Text(
                                    'Save Card Securely',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: MitablColors.onPrimary,
                                      fontFamily: 'Nunito',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Trust Signals (bottom) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 14,
                  color: MitablColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'ENCRYPTED CONNECTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: MitablColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _detectBrand(String number) {
    final digits = number.replaceAll(' ', '');
    if (digits.startsWith('4')) return 'Visa';
    if (digits.startsWith('5')) return 'Mastercard';
    if (digits.startsWith('34') || digits.startsWith('37')) return 'Amex';
    return 'Card';
  }

  Future<void> _saveCard() async {
    setState(() => _isSaving = true);
    try {
      final repository = PaymentsRepository();
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();

      // Create a checkout session (Stripe hosted)
      final url = await repository.createCardCheckoutSession(
        userModel: userModel,
      );

      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      repository.dispose();

      if (!mounted) return;

      if (launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Complete the secure Stripe card setup, then return here.',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the secure card setup link.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start secure card setup right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Formats card numbers with spaces every 4 digits.
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats expiry as MM/YY.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) {
      return TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    final formatted = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
