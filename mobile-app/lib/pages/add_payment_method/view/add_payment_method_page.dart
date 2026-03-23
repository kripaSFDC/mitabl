import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/pages/payments/element/visual_credit_card.dart';
import 'package:mitabl_user/repos/payments_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
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
      appBar: const GlassAppBar(title: Text('Add Card')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        child: Column(
          children: [
            // Live card preview
            VisualCreditCard(
              brand: _detectBrand(_cardNumberController.text),
              last4: last4,
              expMonth: expMonth,
              expYear: expYear,
              cardholderName: _nameController.text,
            ),

            const SizedBox(height: 24),

            // Card form
            MitablCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MitablTextField(
                    controller: _cardNumberController,
                    label: 'Card Number',
                    hint: '4242 4242 4242 4242',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                    prefixIcon: const Icon(Icons.credit_card,
                        color: MitablColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MitablTextField(
                          controller: _expiryController,
                          label: 'Expiry',
                          hint: 'MM/YY',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _ExpiryFormatter(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MitablTextField(
                          controller: _cvcController,
                          label: 'CVC',
                          hint: '123',
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MitablTextField(
                    controller: _nameController,
                    label: 'Cardholder Name',
                    hint: 'John Doe',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Default checkbox
            MitablCard(
              child: Row(
                children: [
                  Checkbox(
                    value: _setAsDefault,
                    onChanged: (val) {
                      setState(() => _setAsDefault = val ?? false);
                    },
                    activeColor: MitablColors.primary,
                  ),
                  const Expanded(
                    child: Text(
                      'Set as default payment method',
                      style: TextStyle(
                        fontSize: 14,
                        color: MitablColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Security badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: MitablColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Secured by Stripe',
                  style: TextStyle(
                    fontSize: 12,
                    color: MitablColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save button
            MitablButton(
              label: 'Save Card Securely',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveCard,
              icon: const Icon(Icons.lock, color: MitablColors.onPrimary, size: 18),
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
