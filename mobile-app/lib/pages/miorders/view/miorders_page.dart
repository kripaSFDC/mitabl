import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/helper/api_error_parser.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class MiOrdersPage extends StatefulWidget {
  const MiOrdersPage({super.key, this.repository});

  final MiOrdersRepository? repository;

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const MiOrdersPage());
  }

  @override
  State<MiOrdersPage> createState() => _MiOrdersPageState();
}

class _MiOrdersPageState extends State<MiOrdersPage> {
  late final MiOrdersRepository _repository;
  late final bool _ownsRepository;

  _ViewStatus _status = _ViewStatus.loading;
  String _errorMessage = 'Unable to fetch orders history';
  List<Map<String, dynamic>> _orders = const [];
  bool _switchingRole = false;
  bool _attemptedFoodieRecovery = false;
  bool _isCancellingOrder = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MiOrdersRepository();
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
      final records = await _repository.fetchOrdersHistory(
        userModel: userModel,
      );
      if (!mounted) return;
      setState(() {
        _orders = records;
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
      appBar: AppBar(title: const Text('miorders')),
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
          _orders.isEmpty
              ? const NoDataWidget()
              : ListView.separated(
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final title = _orderTitle(order, index);
                    final subtitle = _orderSubtitle(order);
                    final statusLabel = _statusLabel(order['status']);
                    final canCancel = _canCancel(order);
                    return ListTile(
                      title: Text(title),
                      subtitle: Text(subtitle),
                      trailing: canCancel
                          ? TextButton(
                              onPressed: _isCancellingOrder
                                  ? null
                                  : () => _cancelOrder(order),
                              child: Text(
                                _isCancellingOrder ? 'Cancelling...' : 'Cancel',
                              ),
                            )
                          : Text(statusLabel),
                    );
                  },
                ),
      },
    );
  }

  String _orderTitle(Map<String, dynamic> order, int index) {
    final dynamic kitchen = order['mikitchn'];
    final kitchenName = kitchen is Map<String, dynamic>
        ? (kitchen['name']?.toString() ?? '')
        : '';
    final orderCode =
        order['order_type_id']?.toString() ??
        order['order_id']?.toString() ??
        'Order ${index + 1}';

    if (kitchenName.isEmpty) {
      return orderCode;
    }

    return '$orderCode • $kitchenName';
  }

  String _orderSubtitle(Map<String, dynamic> order) {
    final serviceType = (order['dine_in']?.toString() == '1')
        ? 'Dine-in'
        : 'Take-away';
    final date = order['date']?.toString() ?? '';
    final timeFrom = order['time_from']?.toString() ?? '';
    final timeTo = order['time_to']?.toString() ?? '';
    final totalPrice = order['total_price']?.toString() ?? '';

    final parts = <String>[
      serviceType,
      if (date.isNotEmpty) date,
      if (timeFrom.isNotEmpty && timeTo.isNotEmpty) '$timeFrom - $timeTo',
      if (totalPrice.isNotEmpty) '\$$totalPrice',
      _statusLabel(order['status']),
    ];

    return parts.join(' • ');
  }

  String _statusLabel(dynamic status) {
    switch ('$status') {
      case '0':
      case '4':
        return 'Cancelled';
      case '1':
        return 'Completed';
      case '2':
        return 'Requested';
      case '3':
        return 'Confirmed';
      case '5':
        return 'In progress';
      default:
        return 'Unknown';
    }
  }

  bool _canCancel(Map<String, dynamic> order) => '${order['status']}' == '2';

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final comment = await _showCancelDialog();
    if (!mounted || comment == null || comment.trim().isEmpty) {
      return;
    }

    setState(() => _isCancellingOrder = true);
    try {
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      await _repository.cancelOrder(
        userModel: userModel,
        orderId: order['order_id'] ?? order['id'] ?? '',
        cancelComment: comment,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully.')),
      );
      await _load(forceFoodieRecovery: false);
    } on RepositoryHttpException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to cancel this order right now.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancellingOrder = false);
      }
    }
  }

  Future<String?> _showCancelDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a short cancellation reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
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
            const Text(
              'Switch to mifoodi to access this page',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              child: Text(isLoading ? 'Switching...' : 'Switch to mifoodi'),
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
