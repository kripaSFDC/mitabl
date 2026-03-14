import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/helper/api_error_parser.dart';
import 'package:mitabl_user/repos/favourites_repository.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key, this.repository});

  final FavouritesRepository? repository;

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const FavouritesPage());
  }

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  late final FavouritesRepository _repository;
  late final bool _ownsRepository;

  _ViewStatus _status = _ViewStatus.loading;
  String _errorMessage = 'Unable to fetch favourites';
  List<Map<String, dynamic>> _favourites = const [];
  bool _switchingRole = false;
  bool _attemptedFoodieRecovery = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FavouritesRepository();
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
      final response =
          await userRepository.switchRole(roleId: AppConstants.FOODI);
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

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (!mounted || silent) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Unable to switch profile right now. Please try again.')),
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
      final records = await _repository.fetchFavourites(userModel: userModel);
      if (!mounted) return;
      setState(() {
        _favourites = records;
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
      appBar: AppBar(title: const Text('favourites')),
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
        _ViewStatus.loaded => _favourites.isEmpty
            ? const NoDataWidget()
            : ListView.separated(
                itemCount: _favourites.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final favourite = _favourites[index];
                  final title = (favourite['name'] ??
                          favourite['title'] ??
                          'Favourite ${index + 1}')
                      .toString();
                  final subtitle = (favourite['subtitle'] ??
                          favourite['description'] ??
                          'Saved item')
                      .toString();
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
            const Text('Switch to mifoodi to access this page',
                textAlign: TextAlign.center),
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
