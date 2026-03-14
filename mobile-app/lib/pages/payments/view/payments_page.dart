import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/repos/payments_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class PaymentsPage extends StatefulWidget {
  PaymentsPage({super.key, PaymentsRepository? repository})
      : repository = repository ?? PaymentsRepository();

  final PaymentsRepository repository;

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => PaymentsPage());
  }

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  _ViewStatus _status = _ViewStatus.loading;
  List<Map<String, dynamic>> _history = const [];
  List<Map<String, dynamic>> _cards = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _ViewStatus.loading);
    try {
      final userRepository = context.read<UserRepository>();
      final userModel = userRepository.currentUser ?? await userRepository.getUser();
      final results = await Future.wait([
        widget.repository.fetchPaymentsHistory(userModel: userModel),
        widget.repository.fetchSavedCards(userModel: userModel),
      ]);

      if (!mounted) return;
      setState(() {
        _history = results[0];
        _cards = results[1];
        _status = _ViewStatus.loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _ViewStatus.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('payments')),
      body: switch (_status) {
        _ViewStatus.loading => const CommonProgressWidget(),
        _ViewStatus.error => OfflineErrorWidget(onRetry: _load),
        _ViewStatus.loaded => (_history.isEmpty && _cards.isEmpty)
            ? const NoDataWidget()
            : ListView(
                children: [
                  if (_cards.isNotEmpty) ...[
                    const ListTile(title: Text('Saved cards')),
                    ..._cards.map(
                      (card) => ListTile(
                        title: Text((card['brand'] ?? 'Card').toString()),
                        subtitle: Text((card['last4'] ?? '').toString()),
                      ),
                    ),
                    const Divider(),
                  ],
                  if (_history.isNotEmpty) ...[
                    const ListTile(title: Text('Payment history')),
                    ..._history.map(
                      (payment) => ListTile(
                        title: Text((payment['amount'] ?? 'Payment').toString()),
                        subtitle: Text((payment['status'] ?? '').toString()),
                      ),
                    ),
                  ],
                ],
              ),
      },
    );
  }
}

enum _ViewStatus { loading, error, loaded }
