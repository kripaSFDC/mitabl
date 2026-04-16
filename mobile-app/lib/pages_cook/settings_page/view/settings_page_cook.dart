import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/support_ticket_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsCookPage extends StatefulWidget {
  const SettingsCookPage({super.key, this.routeArguments});

  final RouteArguments? routeArguments;

  static Route route({RouteArguments? routeArguments}) {
    return MaterialPageRoute<void>(
      builder: (_) => SettingsCookPage(routeArguments: routeArguments),
    );
  }

  @override
  State<SettingsCookPage> createState() => _SettingsCookPageState();
}

class _SettingsCookPageState extends State<SettingsCookPage> {
  late final String _notificationsPreferenceKey;
  late final String _emailMarketingPreferenceKey;

  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _replyController;

  bool _supportActionInFlight = false;
  bool _notificationsEnabled = true;
  bool _notificationsUpdating = false;
  bool _emailNotificationsEnabled = true;
  bool _deleteInFlight = false;
  List<Map<String, dynamic>> _userTickets = [];
  bool _loadingTickets = false;
  dynamic _selectedTicketId;
  int _currentTicketPage = 1;
  int _totalTicketPages = 1;
  bool _loadingMoreTickets = false;
  bool _autoOpenedSupportSheet = false;

  @override
  void initState() {
    super.initState();
    // Build role-specific preference key based on route arguments
    final roleId = widget.routeArguments?.id ?? 'cook';
    _notificationsPreferenceKey = 'settings_notifications_enabled_$roleId';
    _emailMarketingPreferenceKey = 'settings_email_marketing_enabled_$roleId';

    _emailController = TextEditingController();
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();
    _replyController = TextEditingController();
    _loadNotificationPreference();
    _loadEmailMarketingPreference();
    _maybeAutoOpenSupportSheet();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPreference = prefs.getBool(_notificationsPreferenceKey);
    if (!mounted || savedPreference == null) return;
    setState(() => _notificationsEnabled = savedPreference);
  }

  Future<void> _persistNotificationPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPreferenceKey, enabled);
  }

  Future<void> _loadEmailMarketingPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPreference = prefs.getBool(_emailMarketingPreferenceKey);
    if (!mounted || savedPreference == null) return;
    setState(() => _emailNotificationsEnabled = savedPreference);
  }

  Future<void> _persistEmailMarketingPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailMarketingPreferenceKey, enabled);
  }

  bool _shouldAutoOpenSupportSheet() {
    final data = widget.routeArguments?.data;
    if (data is! Map<String, dynamic>) {
      return false;
    }

    final openSupport = data['openSupport'];
    if (openSupport is bool) {
      return openSupport;
    }

    if (openSupport is num) {
      return openSupport != 0;
    }

    if (openSupport is String) {
      final normalized = openSupport.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    return false;
  }

  void _maybeAutoOpenSupportSheet() {
    if (!_shouldAutoOpenSupportSheet()) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _autoOpenedSupportSheet) {
        return;
      }

      _autoOpenedSupportSheet = true;
      _openSupportSheet();
    });
  }

  Future<void> _launchExternalPage(String path) async {
    final url = Uri.parse(ApiContract.webUrl(path));
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showSnackBar('Unable to open ${url.toString()}');
      }
    } catch (_) {
      _showSnackBar('Unable to open ${url.toString()}');
    }
  }

  Future<void> _showLanguageDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Language'),
          content: const Text(
            'English (United States) is currently the active app language. Additional languages are not available yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLoginSecurityDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Login & Security'),
          content: const Text(
            'Password reset is available from the login screen. Biometric lock can be managed from your profile settings on supported devices.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onNotificationChanged(bool enabled) async {
    if (_notificationsUpdating) return;
    final previous = _notificationsEnabled;
    setState(() {
      _notificationsEnabled = enabled;
      _notificationsUpdating = true;
    });
    try {
      await _persistNotificationPreference(enabled);
      if (!mounted) return;
      final repository = context.read<UserRepository>();
      final response =
          await repository.updateNotificationPreference(enabled: enabled);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body;
        String serverMessage = 'Failed to update notification preference.';
        if (body.isNotEmpty) {
          try {
            final decoded = jsonDecode(body) as Map<String, dynamic>;
            final message = decoded['message']?.toString();
            if (message != null && message.isNotEmpty) {
              serverMessage = message;
            }
          } on FormatException {
            // Leave fallback message.
          }
        }
        await _persistNotificationPreference(previous);
        if (mounted) setState(() => _notificationsEnabled = previous);
        _showSnackBar(serverMessage);
      } else {
        _showSnackBar(enabled
            ? 'Notifications enabled successfully.'
            : 'Notifications disabled successfully.');
      }
    } catch (error) {
      await _persistNotificationPreference(previous);
      if (mounted) setState(() => _notificationsEnabled = previous);
      _showSnackBar('Unable to update notification setting: $error');
    } finally {
      if (mounted) setState(() => _notificationsUpdating = false);
    }
  }

  Future<void> _submitSupportTicket() async {
    if (_supportActionInFlight) return;

    final email = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email.');
      return;
    }
    // Email validation using regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }
    if (subject.isEmpty) {
      _showSnackBar('Please enter a subject.');
      return;
    }
    if (subject.length < 3) {
      _showSnackBar('Subject must be at least 3 characters.');
      return;
    }
    if (description.isEmpty) {
      _showSnackBar('Please enter a description.');
      return;
    }
    if (description.length < 5) {
      _showSnackBar('Description must be at least 5 characters.');
      return;
    }

    final repository = context.read<SupportTicketRepository>();
    setState(() => _supportActionInFlight = true);
    try {
      final result = await repository.createSupportTicket(
        requesterEmail: email,
        subject: subject,
        description: description,
      );

      if (!mounted) return;

      // Check if response was successful
      final status = result['status'];
      final statusCode =
          (status is int) ? status : int.tryParse(status.toString()) ?? 0;
      final isSuccess = result['isSuccess'] == true ||
          (statusCode >= 200 && statusCode < 300);

      if (!isSuccess) {
        final errorMsg = result['message'] ??
            result['isError'] ??
            result['error'] ??
            'Failed to create ticket';
        _showSnackBar('Error: $errorMsg');
        return;
      }

      final data = result['data'];
      final dataMap = data is Map<String, dynamic> ? data : null;
      final ticketId = dataMap?['id'] ?? result['id'];
      final ticketNumber = dataMap?['ticket_number'] ?? result['ticket_number'];

      // Clear the form
      _emailController.clear();
      _subjectController.clear();
      _descriptionController.clear();

      // Show success dialog with ticket number
      if (ticketNumber != null) {
        _showSnackBar(
            'Support ticket #$ticketNumber created successfully. Ticket ID: $ticketId');
      } else {
        _showSnackBar('Support ticket created successfully.');
      }

      // Reload tickets list
      await _loadUserTickets();
    } catch (error) {
      _showSnackBar('Unable to create ticket: $error');
    } finally {
      if (mounted) setState(() => _supportActionInFlight = false);
    }
  }

  Future<void> _loadUserTickets({int page = 1, bool append = false}) async {
    final repository = context.read<SupportTicketRepository>();

    if (!append) {
      setState(() {
        _loadingTickets = true;
        _currentTicketPage = 1;
      });
    } else {
      setState(() => _loadingTickets = true);
    }

    try {
      final result = await repository.listSupportTickets(page: page);
      if (!mounted) return;

      // Check for API errors
      final status = result['status'];
      final statusCode =
          (status is int) ? status : int.tryParse(status.toString()) ?? 0;
      final isSuccess = result['isSuccess'] == true ||
          (statusCode >= 200 && statusCode < 300);

      if (!isSuccess) {
        // Silent fail - just update empty list if first page, don't show error snackbar
        if (!append) {
          setState(() => _userTickets = []);
        }
        return;
      }

      // Extract pagination info
      final paginationData = result['pagination'] as Map<String, dynamic>?;
      final totalPages = (paginationData?['last_page'] as num?)?.toInt() ?? 1;

      final data = result['data'];
      final tickets = <Map<String, dynamic>>[];

      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            tickets.add(item);
          }
        }
      } else if (data is Map<String, dynamic>) {
        // In case data is paginated response
        if (data['items'] is List) {
          for (final item in (data['items'] as List)) {
            if (item is Map<String, dynamic>) {
              tickets.add(item);
            }
          }
        } else if (data['data'] is List) {
          for (final item in (data['data'] as List)) {
            if (item is Map<String, dynamic>) {
              tickets.add(item);
            }
          }
        }
      }

      setState(() {
        if (append) {
          _userTickets.addAll(tickets);
        } else {
          _userTickets = tickets;
        }
        _currentTicketPage = page;
        _totalTicketPages = totalPages;
      });
    } catch (error) {
      // Silent fail on network errors
      if (mounted && !append) {
        setState(() => _userTickets = []);
      }
    } finally {
      if (mounted) setState(() => _loadingTickets = false);
    }
  }

  Future<void> _loadMoreTickets() async {
    if (_currentTicketPage >= _totalTicketPages || _loadingMoreTickets) {
      return; // Already loaded all pages or already loading
    }

    setState(() => _loadingMoreTickets = true);
    try {
      await _loadUserTickets(page: _currentTicketPage + 1, append: true);
    } finally {
      if (mounted) setState(() => _loadingMoreTickets = false);
    }
  }

  Future<void> _replyToSupportTicket() async {
    if (_supportActionInFlight) return;

    final selectedTicket = _selectedTicketId;
    final ticketId = selectedTicket is num
        ? selectedTicket.toInt()
        : int.tryParse(selectedTicket?.toString() ?? '');
    if (ticketId == null) {
      _showSnackBar('No ticket selected.');
      return;
    }

    final message = _replyController.text.trim();
    if (message.isEmpty) {
      _showSnackBar('Please enter a reply message.');
      return;
    }
    if (message.length < 2) {
      _showSnackBar('Reply must be at least 2 characters.');
      return;
    }

    final repository = context.read<SupportTicketRepository>();
    setState(() => _supportActionInFlight = true);
    try {
      final result = await repository.replyToSupportTicket(
        id: ticketId,
        message: message,
      );

      if (!mounted) return;

      // Check if reply was successful
      final status = result['status'];
      final statusCode =
          (status is int) ? status : int.tryParse(status.toString()) ?? 0;
      final isSuccess = result['isSuccess'] == true ||
          (statusCode >= 200 && statusCode < 300);

      if (!isSuccess) {
        final errorMsg = result['message'] ??
            result['isError'] ??
            result['error'] ??
            'Failed to send reply';
        _showSnackBar('Error: $errorMsg');
        return;
      }

      _replyController.clear();
      _showSnackBar('Reply sent successfully.');

      // Reload tickets to show the new reply
      await _loadUserTickets();
    } catch (error) {
      _showSnackBar('Unable to send reply: $error');
    } finally {
      if (mounted) setState(() => _supportActionInFlight = false);
    }
  }

  Future<void> _openSupportSheet() async {
    // Reset form state and ticket selection
    _emailController.clear();
    _subjectController.clear();
    _descriptionController.clear();
    _replyController.clear();
    setState(() => _selectedTicketId = null);

    // Load tickets first
    await _loadUserTickets();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: MitablColors.outlineVariant,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Support',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: _selectedTicketId == null
                        ? _buildNewTicketForm(setModalState, context)
                        : _buildTicketDetailsView(setModalState, context),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePreferences() async {
    try {
      await _persistEmailMarketingPreference(_emailNotificationsEnabled);
      if (!mounted) return;
      _showSnackBar('Preferences saved.');
    } catch (error) {
      _showSnackBar('Unable to save preferences: $error');
    }
  }

  Widget _buildNewTicketForm(
    StateSetter setModalState,
    BuildContext modalContext,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Create New Ticket Section
          const Text(
            'Create New Support Ticket',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'your@email.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject',
              hintText: 'Brief description of your issue',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLength: 255,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Provide more details about your issue',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 4,
            maxLength: 2000,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _supportActionInFlight
                  ? null
                  : () async {
                      await _submitSupportTicket();
                      if (!modalContext.mounted) return;
                      setModalState(() {});
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: MitablColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _supportActionInFlight
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Ticket',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // Your Support Tickets Section
          const Text(
            'Your Support Tickets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingTickets)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_userTickets.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: MitablColors.outlineVariant,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No support tickets yet',
                    style: TextStyle(
                      color: MitablColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userTickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ticket = _userTickets[index];
                final ticketId = ticket['id'];

                // Skip rendering if ticket ID is missing
                if (ticketId == null) {
                  return const SizedBox.shrink();
                }

                final ticketNumber =
                    ticket['ticket_number']?.toString() ?? 'N/A';
                final subject =
                    (ticket['subject']?.toString() ?? 'No Subject').trim();
                final status =
                    (ticket['status']?.toString() ?? 'unknown').toLowerCase();
                final statusColor = _getStatusColor(status);

                return Card(
                  child: ListTile(
                    onTap: () {
                      setModalState(() => _selectedTicketId = ticketId);
                    },
                    title: Text(
                      '#$ticketNumber - $subject',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Status: $status',
                      style: TextStyle(color: statusColor),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          // Load More Button - show if more pages available
          if (_userTickets.isNotEmpty && _currentTicketPage < _totalTicketPages)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loadingMoreTickets
                      ? null
                      : () async {
                          await _loadMoreTickets();
                          if (!modalContext.mounted) return;
                          setModalState(() {});
                        },
                  child: _loadingMoreTickets
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Load More Tickets'),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTicketDetailsView(
    StateSetter setModalState,
    BuildContext modalContext,
  ) {
    final ticket = _findTicketById(_selectedTicketId);

    if (ticket == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Ticket not found. Please try again.'),
        ),
      );
    }

    final ticketNumber = ticket['ticket_number']?.toString() ?? 'N/A';
    final subject = ticket['subject']?.toString() ?? 'No Subject';
    final description = ticket['description']?.toString() ?? '';
    final status = ticket['status']?.toString() ?? 'unknown';

    // Safely extract messages list with type checking
    final messagesList = ticket['messages'];
    final messages = <Map<String, dynamic>>[];
    if (messagesList is List) {
      for (final msg in messagesList) {
        if (msg is Map<String, dynamic>) {
          messages.add(msg);
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setModalState(() => _selectedTicketId = null);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#$ticketNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Ticket details
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Messages
          if (messages.isNotEmpty) ...[
            const Text(
              'Conversation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final message = messages[index];
                final senderType =
                    (message['sender_type'] as String?)?.toLowerCase() ??
                        'user';
                final messageText =
                    (message['message'] as String?)?.trim() ?? '';
                final createdAtRaw = message['created_at'] as String?;
                final isSupport = senderType != 'user';

                // Format timestamp
                String createdAtFormatted = 'Just now';
                if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
                  try {
                    final createdAt = DateTime.tryParse(createdAtRaw);
                    if (createdAt != null) {
                      final now = DateTime.now();
                      final difference = now.difference(createdAt);

                      if (difference.inMinutes < 1) {
                        createdAtFormatted = 'Just now';
                      } else if (difference.inMinutes < 60) {
                        createdAtFormatted = '${difference.inMinutes}m ago';
                      } else if (difference.inHours < 24) {
                        createdAtFormatted = '${difference.inHours}h ago';
                      } else {
                        createdAtFormatted = createdAtRaw.substring(0, 10);
                      }
                    }
                  } catch (_) {
                    createdAtFormatted = createdAtRaw;
                  }
                }

                if (messageText.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSupport
                        ? MitablColors.surfaceContainerLow
                        : MitablColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSupport ? 'Support Team' : 'You',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        messageText,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        createdAtFormatted,
                        style: const TextStyle(
                          fontSize: 11,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Reply section - only show for open tickets
          if (status.toLowerCase() != 'closed' &&
              status.toLowerCase() != 'resolved') ...[
            const Divider(),
            const SizedBox(height: 12),
            TextField(
              controller: _replyController,
              decoration: InputDecoration(
                labelText: 'Reply',
                hintText: 'Type your response here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _supportActionInFlight
                    ? null
                    : () async {
                        await _replyToSupportTicket();
                        if (!modalContext.mounted) return;
                        setModalState(() {});
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MitablColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _supportActionInFlight
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Send Reply',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Map<String, dynamic>? _findTicketById(dynamic ticketId) {
    final normalizedTarget = ticketId?.toString();
    for (final ticket in _userTickets) {
      if (ticket['id']?.toString() == normalizedTarget) {
        return ticket;
      }
    }
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF2196F3);
      case 'in_progress':
        return const Color(0xFFFFA500);
      case 'pending_user':
        return const Color(0xFFFF9800);
      case 'resolved':
        return const Color(0xFF4CAF50);
      case 'closed':
        return const Color(0xFF999999);
      default:
        return MitablColors.onSurfaceVariant;
    }
  }

  Future<void> _onDeleteAccountTapped() async {
    if (_deleteInFlight) return;
    final password = await showDialog<String>(
          context: context,
          builder: (dialogContext) => _DeleteAccountDialog(),
        );
    if (!mounted || password == null || password.isEmpty) return;
    setState(() => _deleteInFlight = true);
    try {
      final repository = context.read<UserRepository>();
      final response = await repository.deleteAccount(password: password);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _persistNotificationPreference(true);
        _showSnackBar('Account deleted successfully.');
        if (mounted) {
          await context.read<AuthenticationRepository>().logOut();
        }
        return;
      }
      if (response.statusCode == 403) {
        _showSnackBar('Incorrect password. Please try again.');
        return;
      }
      if (response.statusCode == 409) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Active Orders'),
              content: const Text(
                'You have active orders. Please cancel or complete them before deleting your account.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
      if (response.statusCode == 429) {
        _showSnackBar('Too many attempts. Please try again later.');
        return;
      }
      String message = 'Unable to delete account. Please try again.';
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final parsed = decoded['message']?.toString();
          if (parsed != null && parsed.isNotEmpty) message = parsed;
        } on FormatException {
          // Keep fallback message.
        }
      }
      _showSnackBar(message);
    } catch (error) {
      _showSnackBar('Unable to delete account: $error');
    } finally {
      if (mounted) setState(() => _deleteInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Top App Bar ──
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 16,
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
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.menu,
                              color: MitablColors.primary, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: MitablColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MitablColors.surfaceContainerLow,
                      border: Border.all(
                        color: MitablColors.primary.withValues(alpha: 0.1),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.person,
                        size: 20, color: MitablColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

          // ── Profile Bento Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: MitablColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    // Avatar with edit button
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 48,
                          backgroundColor: MitablColors.surfaceContainerLow,
                          child: Icon(Icons.person,
                              size: 48, color: MitablColors.onSurfaceVariant),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: MitablColors.primary,
                            ),
                            child: const Icon(Icons.edit,
                                size: 14, color: MitablColors.onPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.routeArguments?.id == 'foodie'
                          ? 'Foodie Profile'
                          : 'Chef Profile',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: MitablColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'The Culinary Atelier',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: MitablColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Account Preferences ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Preferences',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildSettingsRow(
                          icon: Icons.person,
                          title: 'Personal Information',
                          subtitle: 'Name, email, and phone number',
                          onTap: () {
                            final routeId = widget.routeArguments?.id;
                            if (routeId == 'foodie') {
                              navigatorKey.currentState!
                                  .pushNamed('/EditProfileFoodie');
                              return;
                            }
                            navigatorKey.currentState!
                                .pushNamed('/ProfileCook');
                          },
                        ),
                        _buildSettingsRow(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: 'English (United States)',
                          onTap: _showLanguageDialog,
                        ),
                        _buildSettingsRow(
                          icon: Icons.security,
                          title: 'Login & Security',
                          subtitle: 'Password and two-factor auth',
                          onTap: _showLoginSecurityDialog,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Notifications ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        // Push Notifications toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: MitablColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_active,
                                  color: Color(0xFF506140), size: 22),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Push Notifications',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                              ),
                              IgnorePointer(
                                ignoring: _notificationsUpdating,
                                child: Switch(
                                  value: _notificationsEnabled,
                                  activeThumbColor: MitablColors.primary,
                                  onChanged: _onNotificationChanged,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Email Marketing toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: MitablColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mail_outline,
                                  color: Color(0xFF506140), size: 22),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Email Marketing',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: MitablColors.onSurface,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _emailNotificationsEnabled,
                                activeThumbColor: MitablColors.primary,
                                onChanged: (v) => setState(
                                    () => _emailNotificationsEnabled = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Support ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Support',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: MitablColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: MitablColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildSupportRow(
                          icon: Icons.help_center,
                          title: 'Help Center',
                          onTap: _openSupportSheet,
                        ),
                        _buildSupportRow(
                          icon: Icons.chat_bubble_outline,
                          title: 'Contact Support',
                          onTap: _openSupportSheet,
                        ),
                        _buildSupportRow(
                          icon: Icons.policy_outlined,
                          title: 'Privacy Policy',
                          onTap: () => _launchExternalPage('privacy-policy'),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── Action Buttons ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Save All Changes
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MitablColors.primary,
                        foregroundColor: MitablColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor:
                            MitablColors.primary.withValues(alpha: 0.2),
                        shape: const RoundedRectangleBorder(
                          borderRadius: MitablRadius.pillBorder,
                        ),
                      ),
                      child: const Text(
                        'Save All Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthenticationRepository>().logOut();
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE2E2),
                        foregroundColor: const Color(0xFF991B1B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: MitablRadius.pillBorder,
                        ),
                      ),
                    ),
                  ),
                  // Delete Account (hidden in support)
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _deleteInFlight ? null : _onDeleteAccountTapped,
                    child: _deleteInFlight
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: MitablColors.error,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: MitablColors.surfaceContainerLowest,
                  ),
                  child: Icon(icon, color: MitablColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: MitablColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: MitablColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF64748B), size: 22),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 76, endIndent: 20, thickness: 0.5),
      ],
    );
  }

  Widget _buildSupportRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF64748B), size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: MitablColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            thickness: 0.5,
            color: MitablColors.outlineVariant.withValues(alpha: 0.1),
          ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final isNonEmpty = _controller.text.isNotEmpty;
      if (isNonEmpty != _enabled) setState(() => _enabled = isNonEmpty);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This action permanently deletes your account and cannot be undone.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter your password to confirm',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _enabled
              ? () => Navigator.of(context).pop(_controller.text)
              : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
