import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/helper/api_error_parser.dart';
import 'package:mitabl_user/pages/payments/element/transaction_row.dart';
import 'package:mitabl_user/pages/payments/element/visual_credit_card.dart';
import 'package:mitabl_user/repos/payments_repository.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key, this.repository});

  final PaymentsRepository? repository;

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const PaymentsPage());
  }

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  late final PaymentsRepository _repository;
  late final bool _ownsRepository;

  _ViewStatus _status = _ViewStatus.loading;
  String _errorMessage = 'Unable to fetch payment history';
  List<Map<String, dynamic>> _history = const [];
  List<Map<String, dynamic>> _cards = const [];
  bool _switchingRole = false;
  bool _attemptedFoodieRecovery = false;

  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PaymentsRepository();
    _ownsRepository = widget.repository == null;
    _load();
  }

  @override
  void dispose() {
    if (_ownsRepository) {
      _repository.dispose();
    }
    super.dispose();
  }

  Future<bool> _switchToMifoodi({bool silent = false}) async {
    if (_switchingRole) return false;

    setState(() => _switchingRole = true);
    final userRepository = context.read<UserRepository>();
    try {
      final response = await userRepository.switchRole(
        roleId: AppConstants.FOODI,
      );
      if (!mounted) return false;

      if (response.statusCode == 200) {
        _attemptedFoodieRecovery = true;
        await _load(forceFoodieRecovery: false);
        return true;
      }

      if (!silent) {
        final message = ApiErrorParser.parseMessage(
          response.body,
          keys: const ['isError', 'message', 'error'],
          fallbackMessage: 'mifoodi profile is not available for this account.',
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (!mounted || silent) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to switch profile right now. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _switchingRole = false);
      }
    }

    return false;
  }

  Future<void> _load({bool forceFoodieRecovery = true}) async {
    setState(() => _status = _ViewStatus.loading);
    try {
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      final results = await Future.wait([
        _repository.fetchPaymentsHistory(userModel: userModel),
        _repository.fetchSavedCards(userModel: userModel),
      ]);

      if (!mounted) return;
      setState(() {
        _history = results[0];
        _cards = results[1];
        _status = _ViewStatus.loaded;
      });
    } on RepositoryHttpException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        context.read<SessionRepository>().notifyUnauthorized();
        return;
      }

      if (error.statusCode == 403) {
        if (forceFoodieRecovery && !_attemptedFoodieRecovery) {
          final recovered = await _switchToMifoodi(silent: true);
          if (recovered || !mounted) {
            return;
          }
        }

        setState(() => _status = _ViewStatus.forbidden);
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _status = _ViewStatus.serverError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _ViewStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(
        title: const Text('Payments'),
        actions: [
          if (_status == _ViewStatus.loaded)
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh,
                  color: MitablColors.onSurface, size: 22),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: switch (_status) {
        _ViewStatus.loading => const CommonProgressWidget(),
        _ViewStatus.error => OfflineErrorWidget(onRetry: _load),
        _ViewStatus.forbidden => _SwitchToMifoodiCta(
          onPressed: _switchToMifoodi,
          isLoading: _switchingRole,
        ),
        _ViewStatus.serverError => _ServerErrorWidget(
          message: _errorMessage,
          onRetry: _load,
        ),
        _ViewStatus.loaded =>
          (_history.isEmpty && _cards.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NoDataWidget(),
                      const SizedBox(height: 16),
                      MitablButton(
                        label: 'Add Your First Card',
                        onPressed: () => _navigateToAddCard(),
                        fullWidth: false,
                        icon: const Icon(Icons.add_card,
                            color: MitablColors.onPrimary, size: 18),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: MitablColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(MitablSpacing.pagePadding),
                    children: [
                      // Cards carousel
                      if (_cards.isNotEmpty) ...[
                        SizedBox(
                          height: 210,
                          child: PageView.builder(
                            itemCount: _cards.length,
                            onPageChanged: (index) {
                              setState(() => _currentCardIndex = index);
                            },
                            itemBuilder: (context, index) {
                              final card = _cards[index];
                              return VisualCreditCard(
                                brand: (card['brand'] ?? 'Card').toString(),
                                last4: (card['last4'] ?? '').toString(),
                                expMonth:
                                    (card['exp_month'] ?? '').toString(),
                                expYear:
                                    (card['exp_year'] ?? '').toString(),
                                cardholderName:
                                    (card['name'] ?? '').toString(),
                              );
                            },
                          ),
                        ),

                        // Page dots
                        if (_cards.length > 1) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _cards.length,
                              (index) => Container(
                                width: index == _currentCardIndex ? 24 : 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: index == _currentCardIndex
                                      ? MitablColors.primary
                                      : MitablColors.outlineVariant,
                                  borderRadius: MitablRadius.pillBorder,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                      ],

                      // Add card button
                      MitablButton(
                        label: 'Add Card',
                        onPressed: () => _navigateToAddCard(),
                        variant: MitablButtonVariant.outline,
                        icon: Icon(Icons.add_card,
                            color: MitablColors.primary, size: 18),
                      ),

                      const SizedBox(height: 24),

                      // Recent Transactions
                      if (_history.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: MitablColors.onSurface,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ),
                        ..._history.map(
                          (transaction) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: MitablSpacing.listItem / 2),
                            child:
                                TransactionRow(transaction: transaction),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      },
    );
  }

  void _navigateToAddCard() {
    Navigator.of(context).pushNamed('/AddPaymentMethod').then((result) {
      if (result == true && mounted) {
        _load();
      }
    });
  }
}

enum _ViewStatus { loading, error, forbidden, serverError, loaded }

class _SwitchToMifoodiCta extends StatelessWidget {
  const _SwitchToMifoodiCta({required this.onPressed, required this.isLoading});

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_horiz,
              size: 48,
              color: MitablColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'Switch to mifoodi to access this page',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: MitablColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            MitablButton(
              label: isLoading ? 'Switching...' : 'Switch to mifoodi',
              onPressed: isLoading ? null : onPressed,
              variant: MitablButtonVariant.primary,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerErrorWidget extends StatelessWidget {
  const _ServerErrorWidget({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: MitablColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: MitablColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            MitablButton(
              label: 'Retry',
              onPressed: onRetry,
              variant: MitablButtonVariant.outline,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
