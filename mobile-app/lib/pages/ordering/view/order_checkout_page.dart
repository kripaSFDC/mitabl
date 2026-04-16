import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/model/ordering_models.dart';
import 'package:mitabl_user/pages/common/view/stripe_payment_method_page.dart';
import 'package:mitabl_user/pages/ordering/order_route_data.dart';
import 'package:mitabl_user/pages/ordering/order_session.dart';
import 'package:mitabl_user/repos/payments_repository.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderCheckoutPage extends StatefulWidget {
  const OrderCheckoutPage({super.key, required this.session});

  final OrderSessionController session;

  static Route route({required RouteArguments routeArguments}) {
    final routeData = routeArguments.data;
    if (routeData is! OrderRouteData || routeData.session == null) {
      return MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: SafeArea(
            child: Text('Missing route arguments for /OrderCheckout'),
          ),
        ),
      );
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/OrderCheckout'),
      builder: (_) => OrderCheckoutPage(session: routeData.session!),
    );
  }

  @override
  State<OrderCheckoutPage> createState() => _OrderCheckoutPageState();
}

class _OrderCheckoutPageState extends State<OrderCheckoutPage> {
  final PaymentsRepository _paymentsRepository = PaymentsRepository();
  final TextEditingController _oneTimePaymentMethodController =
      TextEditingController();

  bool _loadingCards = true;
  bool _addingCard = false;
  String? _paymentError;
  List<Map<String, dynamic>> _savedCards = const <Map<String, dynamic>>[];

  OrderSessionController get session => widget.session;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  @override
  void dispose() {
    _paymentsRepository.dispose();
    _oneTimePaymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCards() async {
    setState(() {
      _loadingCards = true;
      _paymentError = null;
    });

    final userRepository = context.read<UserRepository>();
    try {
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      final cards = await _paymentsRepository.fetchSavedCards(
        userModel: userModel,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _savedCards = cards;
        _loadingCards = false;
      });

      if (cards.isNotEmpty && session.paymentSelection == null) {
        final defaultReference = _cardReference(cards.first);
        if (defaultReference.isNotEmpty) {
          session.selectPayment(
            OrderPaymentSelection.savedCard(defaultReference),
          );
        }
      }
    } on RepositoryHttpException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _paymentError = error.message;
        _loadingCards = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _paymentError = 'Unable to load saved cards right now.';
        _loadingCards = false;
      });
    }
  }

  Future<void> _startAddCardFlow() async {
    setState(() => _addingCard = true);

    final userRepository = context.read<UserRepository>();
    try {
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      final url = await _paymentsRepository.createCardCheckoutSession(
        userModel: userModel,
      );
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            launched
                ? 'Complete the secure Stripe card setup, then return here and refresh.'
                : 'Unable to open the secure card setup link.',
          ),
        ),
      );
    } on RepositoryHttpException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start secure card setup right now.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _addingCard = false);
      }
    }
  }

  Future<void> _collectOneTimePaymentMethod() async {
    final url =
        Uri.parse(ApiContract.webUrl('api/v2/payments/payment-method-entry'))
            .replace(
              queryParameters: const <String, String>{
                'mode': 'one_time',
                'return_url': 'mitabl://payment-method-complete',
              },
            )
            .toString();

    final paymentMethodId = await StripePaymentMethodPage.present(
      context,
      initialUrl: url,
    );

    if (!mounted || paymentMethodId == null || paymentMethodId.trim().isEmpty) {
      return;
    }

    _oneTimePaymentMethodController.text = paymentMethodId.trim();
    session.selectPayment(
      OrderPaymentSelection.oneTime(paymentMethodId.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final kitchen = session.kitchen;
        final serviceLabel = session.serviceType == OrderServiceType.dineIn
            ? 'Dine in'
            : 'Take away';

        return Scaffold(
          appBar: AppBar(title: const Text('Review order')),
          body: kitchen == null
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  onRefresh: _loadSavedCards,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        kitchen.name,
                        style: GoogleFonts.gothicA1(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(kitchen.address),
                      const SizedBox(height: 20),
                      _CheckoutSection(
                        title: 'Order details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Service: $serviceLabel'),
                            const SizedBox(height: 6),
                            Text(
                              'Date: ${DateFormat('EEE, d MMM yyyy').format(session.scheduledDate)}',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Time: ${session.scheduledTime.startLabel} - ${session.scheduledTime.endLabel}',
                            ),
                            if (session.serviceType ==
                                OrderServiceType.dineIn) ...[
                              const SizedBox(height: 6),
                              Text('Guests: ${session.persons}'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CheckoutSection(
                        title: 'Items',
                        child: Column(
                          children: session.cartItems
                              .map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${line.quantity} x ${line.item.name}',
                                        ),
                                      ),
                                      Text(
                                        '\$${line.lineTotal.toStringAsFixed(2)}',
                                        style: GoogleFonts.gothicA1(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CheckoutSection(
                        title: 'Payment',
                        child: _PaymentSection(
                          isLoading: _loadingCards,
                          isAddingCard: _addingCard,
                          errorMessage: _paymentError,
                          savedCards: _savedCards,
                          selectedPayment: session.paymentSelection,
                          oneTimeController: _oneTimePaymentMethodController,
                          onSavedCardSelected: (reference) {
                            _oneTimePaymentMethodController.clear();
                            session.selectPayment(
                              OrderPaymentSelection.savedCard(reference),
                            );
                          },
                          onOneTimePaymentChanged: (value) {
                            final trimmed = value.trim();
                            if (trimmed.isEmpty) {
                              session.clearPaymentSelection();
                              return;
                            }

                            session.selectPayment(
                              OrderPaymentSelection.oneTime(trimmed),
                            );
                          },
                          onAddCardPressed: _startAddCardFlow,
                          onCollectOneTimeCardPressed:
                              _collectOneTimePaymentMethod,
                          onRefreshPressed: _loadSavedCards,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CheckoutSection(
                        title: 'Pricing',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SummaryRow(
                              label: 'Items',
                              value:
                                  '\$${session.itemTotal.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              label: 'Taxes',
                              value: '\$${session.taxTotal.toStringAsFixed(2)}',
                            ),
                            const Divider(height: 24),
                            _SummaryRow(
                              label: 'Estimated total',
                              value:
                                  '\$${session.estimatedTotal.toStringAsFixed(2)}',
                              emphasize: true,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your payment method is attached to the order now and charged when the miCook accepts it.',
                              style: GoogleFonts.gothicA1(
                                fontSize: 12,
                                color: config.AppColors()
                                    .hintTextBackgroundColor(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((session.errorMessage ?? '').isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          _displayError(session.errorMessage!),
                          style: GoogleFonts.gothicA1(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: session.isSubmitting
                            ? null
                            : () => _placeOrder(context),
                        child: session.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Place order'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    final selection = session.paymentSelection;
    if (selection == null || selection.isBlank) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select a saved card or enter a one-time payment method ID.',
          ),
        ),
      );
      return;
    }

    final items = List<CartLineItem>.from(session.cartItems);
    final kitchenName = session.kitchen?.name ?? '';
    final kitchenAddress = session.kitchen?.address ?? '';
    final totalAmount = session.estimatedTotal + 1.50;
    final scheduledDate = session.scheduledDate;
    final timeLabel =
        '${session.scheduledTime.startLabel} - ${session.scheduledTime.endLabel}';
    final isDineIn = session.serviceType == OrderServiceType.dineIn;
    final persons = isDineIn ? session.persons : null;

    try {
      final result = await session.submit();
      if (!context.mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/OrderConfirmation',
        (route) => route.settings.name == '/home' || route.isFirst,
        arguments: RouteArguments(
          data: OrderConfirmationRouteData(
            result: result,
            kitchenName: kitchenName,
            kitchenAddress: kitchenAddress,
            items: items,
            totalAmount: totalAmount,
            scheduledDate: scheduledDate,
            timeLabel: timeLabel,
            isDineIn: isDineIn,
            persons: persons,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _displayError(session.errorMessage ?? 'Unable to place order.'),
          ),
        ),
      );
    }
  }

  String _cardReference(Map<String, dynamic> card) {
    final dynamic localId = card['id'];
    if (localId != null && localId.toString().isNotEmpty) {
      return localId.toString();
    }

    final dynamic stripeId =
        card['stripe_card_id'] ?? card['payment_method_id'];
    return stripeId?.toString() ?? '';
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.isLoading,
    required this.isAddingCard,
    required this.errorMessage,
    required this.savedCards,
    required this.selectedPayment,
    required this.oneTimeController,
    required this.onSavedCardSelected,
    required this.onOneTimePaymentChanged,
    required this.onAddCardPressed,
    required this.onCollectOneTimeCardPressed,
    required this.onRefreshPressed,
  });

  final bool isLoading;
  final bool isAddingCard;
  final String? errorMessage;
  final List<Map<String, dynamic>> savedCards;
  final OrderPaymentSelection? selectedPayment;
  final TextEditingController oneTimeController;
  final ValueChanged<String> onSavedCardSelected;
  final ValueChanged<String> onOneTimePaymentChanged;
  final VoidCallback onAddCardPressed;
  final VoidCallback onCollectOneTimeCardPressed;
  final VoidCallback onRefreshPressed;

  @override
  Widget build(BuildContext context) {
    final selectedSavedCardReference =
        selectedPayment?.mode == CheckoutPaymentMode.savedCard
        ? selectedPayment?.reference
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Choose a saved card, or open secure one-time card entry for a different card.',
                style: GoogleFonts.gothicA1(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: isLoading ? null : onRefreshPressed,
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: isAddingCard ? null : onAddCardPressed,
              icon: const Icon(Icons.add_card_outlined),
              label: Text(isAddingCard ? 'Opening...' : 'Add card'),
            ),
            OutlinedButton.icon(
              onPressed: onCollectOneTimeCardPressed,
              icon: const Icon(Icons.credit_card_outlined),
              label: const Text('Use one-time card'),
            ),
          ],
        ),
        if (isLoading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if ((errorMessage ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: GoogleFonts.gothicA1(
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (savedCards.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...savedCards.map((card) {
            final reference = _referenceFor(card);
            final isSelected = selectedSavedCardReference == reference;
            final brand = (card['brand'] ?? 'Card').toString().toUpperCase();
            final last4 = (card['last4'] ?? '').toString();
            final expiry = _expiryLabel(card);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: reference.isEmpty
                    ? null
                    : () {
                        oneTimeController.clear();
                        onSavedCardSelected(reference);
                      },
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(
                  '$brand ${last4.isEmpty ? '' : '•••• $last4'}'.trim(),
                ),
                subtitle: expiry == null ? null : Text(expiry),
              ),
            );
          }),
        ] else if (!isLoading) ...[
          const SizedBox(height: 16),
          Text(
            'No saved cards yet. Use Add card to open secure Stripe setup.',
            style: GoogleFonts.gothicA1(fontSize: 13),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: oneTimeController,
          onChanged: onOneTimePaymentChanged,
          decoration: const InputDecoration(
            labelText: 'One-time payment_method_id',
            hintText: 'pm_...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This field is optional and mainly useful for existing Stripe testing flows.',
          style: GoogleFonts.gothicA1(
            fontSize: 12,
            color: config.AppColors().hintTextBackgroundColor(1),
          ),
        ),
      ],
    );
  }

  String _referenceFor(Map<String, dynamic> card) {
    final dynamic localId = card['id'];
    if (localId != null && localId.toString().isNotEmpty) {
      return localId.toString();
    }

    final dynamic stripeId =
        card['stripe_card_id'] ?? card['payment_method_id'];
    return stripeId?.toString() ?? '';
  }

  String? _expiryLabel(Map<String, dynamic> card) {
    final expMonth = card['exp_month']?.toString();
    final expYear = card['exp_year']?.toString();
    if ((expMonth ?? '').isEmpty || (expYear ?? '').isEmpty) {
      return null;
    }

    return 'Expires $expMonth/$expYear';
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.AppColors().textFieldBackgroundColor(1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.AppColors().colorDivider(1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.gothicA1(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.gothicA1(
      fontSize: emphasize ? 16 : 14,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

String _displayError(String raw) {
  const marker = 'message: ';
  final markerIndex = raw.indexOf(marker);
  if (markerIndex == -1) {
    return raw;
  }

  final start = markerIndex + marker.length;
  final trimmed = raw.substring(start).trimRight();
  return trimmed.endsWith(')')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}
