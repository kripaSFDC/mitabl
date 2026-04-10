import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/appconstants.dart';
import 'package:mitabl_user/helper/common_progress.dart';
import 'package:mitabl_user/helper/no_data_widget.dart';
import 'package:mitabl_user/helper/offline_error_widget.dart';
import 'package:mitabl_user/helper/api_error_parser.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/pages/miorders/element/order_card.dart';
import 'package:mitabl_user/repos/miorders_repository.dart';
import 'package:mitabl_user/repos/repository_http_exception.dart';
import 'package:mitabl_user/repos/session_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';

class MiOrdersPage extends StatefulWidget {
  const MiOrdersPage({super.key, this.repository});

  final MiOrdersRepository? repository;

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const MiOrdersPage());
  }

  @override
  State<MiOrdersPage> createState() => _MiOrdersPageState();
}

class _MiOrdersPageState extends State<MiOrdersPage>
    with SingleTickerProviderStateMixin {
  late final MiOrdersRepository _repository;
  late final bool _ownsRepository;

  _ViewStatus _status = _ViewStatus.loading;
  String _errorMessage = 'Unable to fetch orders history';
  List<Map<String, dynamic>> _orders = const [];
  bool _switchingRole = false;
  bool _attemptedFoodieRecovery = false;
  bool _isCancellingOrder = false;

  // Segmented control index: 0 = Ongoing, 1 = Past
  int _selectedSegment = 0;

  List<Map<String, dynamic>> get _ongoingOrders =>
      _orders.where((o) {
        final s = '${o['status']}';
        return s == '2' || s == '3' || s == '5';
      }).toList();

  List<Map<String, dynamic>> get _pastOrders =>
      _orders.where((o) {
        final s = '${o['status']}';
        return s == '0' || s == '1' || s == '4';
      }).toList();

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
      backgroundColor: MitablColors.surface,
      body: Column(
        children: [
          // Top app bar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: MitablColors.surface.withValues(alpha: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/ProfileFoodie'),
                      child: const Icon(
                        Icons.menu,
                        color: MitablColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'miFoodi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: MitablColors.primary,
                        fontFamily: 'PlusJakartaSans',
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                // Profile avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFEDD5),
                      width: 2,
                    ),
                  ),
                  child: const ClipOval(
                    child: Center(
                      child: Icon(
                        Icons.person,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: switch (_status) {
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
              _ViewStatus.loaded => _buildLoadedContent(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: MitablColors.onSurface,
                  fontFamily: 'PlusJakartaSans',
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track and manage your culinary journeys',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: MitablColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Segmented control (Ongoing / Past Orders)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MitablColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildSegmentButton('Ongoing', 0),
                const SizedBox(width: 8),
                _buildSegmentButton('Past Orders', 1),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Orders list
        Expanded(
          child: _selectedSegment == 0
              ? _buildOrderList(_ongoingOrders)
              : _buildOrderList(_pastOrders),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(String label, int index) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? MitablColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? MitablColors.primary
                    : MitablColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return const Center(child: NoDataWidget());
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: MitablColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: OrderCard(
              order: order,
              index: index,
              isCancelling: _isCancellingOrder,
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/OrderDetailsFoodie',
                  arguments: RouteArguments(data: order),
                );
              },
              onCancel: () => _cancelOrder(order),
            ),
          );
        },
      ),
    );
  }

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
        shape: const RoundedRectangleBorder(
          borderRadius: MitablRadius.cardBorder,
        ),
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
            child: const Text(
              'Cancel order',
              style: TextStyle(color: MitablColors.error),
            ),
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
