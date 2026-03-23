import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/helper/api_error_parser.dart';
import 'package:mitabl_user/pages/favourites/element/favourite_cook_card.dart';
import 'package:mitabl_user/repos/favourites_repository.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';

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

  Future<void> _unfavourite(Map<String, dynamic> favourite) async {
    final targetId = (favourite['id'] ??
            favourite['restaurant_id'] ??
            favourite['mikitchn_id'] ??
            '')
        .toString();
    if (targetId.isEmpty) return;

    try {
      final userRepository = context.read<UserRepository>();
      final userModel =
          userRepository.currentUser ?? await userRepository.getUser();
      await _repository.toggleFavourite(
        userModel: userModel,
        targetId: targetId,
      );
      if (!mounted) return;
      setState(() {
        _favourites =
            _favourites.where((f) => f != favourite).toList(growable: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favourites')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favourites right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: const GlassAppBar(title: Text('Saved Kitchens')),
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
          _favourites.isEmpty
              ? const NoDataWidget()
              : ListView.builder(
                  padding: const EdgeInsets.all(MitablSpacing.pagePadding),
                  itemCount: _favourites.length + 1, // +1 for CTA at bottom
                  itemBuilder: (context, index) {
                    if (index == _favourites.length) {
                      // "Looking for more?" CTA card
                      return Padding(
                        padding: const EdgeInsets.only(
                          top: MitablSpacing.listItem / 2,
                          bottom: 32,
                        ),
                        child: MitablCard(
                          child: Column(
                            children: [
                              const Text(
                                'Looking for more?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: MitablColors.onSurface,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Discover new kitchens near you',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: MitablColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              MitablButton(
                                label: 'Explore',
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed('/HomePage');
                                },
                                variant: MitablButtonVariant.primary,
                                fullWidth: false,
                                icon: const Icon(Icons.explore,
                                    color: MitablColors.onPrimary, size: 18),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final favourite = _favourites[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                          bottom: MitablSpacing.listItem / 2),
                      child: FavouriteCookCard(
                        favourite: favourite,
                        onUnfavourite: () => _unfavourite(favourite),
                      ),
                    );
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
