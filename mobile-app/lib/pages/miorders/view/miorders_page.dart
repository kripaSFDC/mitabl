import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
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

  Future<void> _switchToMifoodi() async {
    if (_switchingRole) return;

    setState(() => _switchingRole = true);
    final userRepository = context.read<UserRepository>();
    try {
      final response = await userRepository.switchRole(roleId: AppConstants.FOODI);
      if (!mounted) return;

      if (response.statusCode == 200) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil('/HomePage', (route) => false);
        return;
      }

      String message = 'mifoodi profile is not available for this account.';
      try {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final serverMessage = payload['isError'] ?? payload['message'];
        if (serverMessage is String && serverMessage.trim().isNotEmpty) {
          message = serverMessage;
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to switch profile right now. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _switchingRole = false);
      }
    }
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
    } on RepositoryHttpException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 401) {
        context.read<SessionRepository>().notifyUnauthorized();
        setState(() => _status = _ViewStatus.error);
        return;
      }

      if (error.statusCode == 403) {
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
        _ViewStatus.loaded => _orders.isEmpty
            ? const NoDataWidget()
            : ListView.separated(
                itemCount: _orders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final title = (order['title'] ?? order['id'] ?? 'Order ${index + 1}').toString();
                  final subtitle =
                      (order['status'] ?? order['date'] ?? 'Details unavailable').toString();
                  return ListTile(title: Text(title), subtitle: Text(subtitle));
                },
              ),
      },
    );
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
            const Text('Switch to mifoodi to access this page', textAlign: TextAlign.center),
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
