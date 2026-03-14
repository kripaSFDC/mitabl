import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
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
  List<Map<String, dynamic>> _orders = const [];

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

  Future<void> _load() async {
    setState(() => _status = _ViewStatus.loading);
    try {
      final userRepository = context.read<UserRepository>();
      final userModel = userRepository.currentUser ?? await userRepository.getUser();
      final records = await _repository.fetchOrdersHistory(userModel: userModel);
      if (!mounted) return;
      setState(() {
        _orders = records;
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
      appBar: AppBar(title: const Text('miorders')),
      body: switch (_status) {
        _ViewStatus.loading => const CommonProgressWidget(),
        _ViewStatus.error => OfflineErrorWidget(onRetry: _load),
        _ViewStatus.loaded => _orders.isEmpty
            ? const NoDataWidget()
            : ListView.separated(
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final title =
                      (order['title'] ?? order['id'] ?? 'Order ${index + 1}').toString();
                  final subtitle =
                      (order['status'] ?? order['date'] ?? 'Details unavailable').toString();
                  return ListTile(title: Text(title), subtitle: Text(subtitle));
                },
              ),
      },
    );
  }
}

enum _ViewStatus { loading, error, loaded }
