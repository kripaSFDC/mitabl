import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/biometric_service.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/support_ticket_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
import 'package:mitabl_user/widgets/glass_app_bar.dart';
import 'package:mitabl_user/widgets/mitabl_button.dart';
import 'package:mitabl_user/widgets/mitabl_card.dart';
import 'package:mitabl_user/widgets/mitabl_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _notificationsPreferenceKey =
      'settings_notifications_enabled_cook';

  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ticketIdController;
  late final TextEditingController _replyController;

  bool _supportActionInFlight = false;
  bool _notificationsEnabled = true;
  bool _notificationsUpdating = false;
  bool _emailNotificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _deleteInFlight = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _subjectController = TextEditingController();
    _descriptionController = TextEditingController();
    _ticketIdController = TextEditingController();
    _replyController = TextEditingController();
    _loadNotificationPreference();
    _loadBiometricPreference();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _ticketIdController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPreference = prefs.getBool(_notificationsPreferenceKey);

    if (!mounted || savedPreference == null) {
      return;
    }

    setState(() {
      _notificationsEnabled = savedPreference;
    });
  }

  Future<void> _persistNotificationPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPreferenceKey, enabled);
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await BiometricService.instance.isEnabled();
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
  }

  Future<void> _onBiometricChanged(bool enabled) async {
    final available = await BiometricService.instance.isAvailable();
    if (!mounted) return;
    if (!available && enabled) {
      _showSnackBar(
        'Biometric authentication is not available on this device.',
      );
      return;
    }

    await BiometricService.instance.setEnabled(enabled);
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
    _showSnackBar(
      enabled ? 'Biometric lock enabled.' : 'Biometric lock disabled.',
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onNotificationChanged(bool enabled) async {
    if (_notificationsUpdating) {
      return;
    }

    final previous = _notificationsEnabled;
    setState(() {
      _notificationsEnabled = enabled;
      _notificationsUpdating = true;
    });

    try {
      await _persistNotificationPreference(enabled);
      if (!mounted) return;
      final repository = context.read<UserRepository>();
      final response = await repository.updateNotificationPreference(
        enabled: enabled,
      );

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
        if (mounted) {
          setState(() => _notificationsEnabled = previous);
        }
        _showSnackBar(serverMessage);
      } else {
        _showSnackBar(
          enabled
              ? 'Notifications enabled successfully.'
              : 'Notifications disabled successfully.',
        );
      }
    } catch (error) {
      await _persistNotificationPreference(previous);
      if (mounted) {
        setState(() => _notificationsEnabled = previous);
      }
      _showSnackBar('Unable to update notification setting: $error');
    } finally {
      if (mounted) {
        setState(() => _notificationsUpdating = false);
      }
    }
  }

  Future<void> _submitSupportTicket() async {
    final repository = context.read<SupportTicketRepository>();
    setState(() => _supportActionInFlight = true);

    try {
      final result = await repository.createSupportTicket(
        requesterEmail: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      final message =
          result['message']?.toString() ??
          'Support ticket created successfully.';
      _showSnackBar(message);
    } catch (error) {
      _showSnackBar('Unable to create ticket: $error');
    } finally {
      if (mounted) {
        setState(() => _supportActionInFlight = false);
      }
    }
  }

  Future<void> _loadSupportTicket() async {
    final ticketId = int.tryParse(_ticketIdController.text.trim());
    if (ticketId == null) {
      _showSnackBar('Enter a valid ticket id.');
      return;
    }

    final repository = context.read<SupportTicketRepository>();
    setState(() => _supportActionInFlight = true);

    try {
      final result = await repository.getSupportTicket(id: ticketId);
      final status = result['data']?['status']?.toString() ?? 'unknown';
      _showSnackBar('Ticket $ticketId status: $status');
    } catch (error) {
      _showSnackBar('Unable to load ticket: $error');
    } finally {
      if (mounted) {
        setState(() => _supportActionInFlight = false);
      }
    }
  }

  Future<void> _replyToSupportTicket() async {
    final ticketId = int.tryParse(_ticketIdController.text.trim());
    if (ticketId == null) {
      _showSnackBar('Enter a valid ticket id first.');
      return;
    }

    final repository = context.read<SupportTicketRepository>();
    setState(() => _supportActionInFlight = true);

    try {
      final result = await repository.replyToSupportTicket(
        id: ticketId,
        message: _replyController.text.trim(),
      );
      final message = result['message']?.toString() ?? 'Reply submitted.';
      _showSnackBar(message);
    } catch (error) {
      _showSnackBar('Unable to send reply: $error');
    } finally {
      if (mounted) {
        setState(() => _supportActionInFlight = false);
      }
    }
  }

  Future<void> _openSupportSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: _ticketIdController,
                  decoration: const InputDecoration(labelText: 'Ticket ID'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _replyController,
                  decoration:
                      const InputDecoration(labelText: 'Reply message'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _supportActionInFlight
                          ? null
                          : _submitSupportTicket,
                      child: const Text('Create Ticket'),
                    ),
                    ElevatedButton(
                      onPressed: _supportActionInFlight
                          ? null
                          : _loadSupportTicket,
                      child: const Text('Get Ticket'),
                    ),
                    ElevatedButton(
                      onPressed: _supportActionInFlight
                          ? null
                          : _replyToSupportTicket,
                      child: const Text('Reply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDeleteAccountTapped() async {
    if (_deleteInFlight) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: const Text(
                'This action permanently deletes your account and cannot be undone. Continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted) return;

    if (!shouldDelete) {
      return;
    }

    setState(() => _deleteInFlight = true);

    try {
      final repository = context.read<UserRepository>();
      final response = await repository.deleteAccount();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _persistNotificationPreference(true);
        _showSnackBar('Account deleted successfully.');
        if (mounted) {
          await context.read<AuthenticationRepository>().logOut();
        }
        return;
      }

      String message = 'Unable to delete account. Please try again.';
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          final parsed = decoded['message']?.toString();
          if (parsed != null && parsed.isNotEmpty) {
            message = parsed;
          }
        } on FormatException {
          // Keep fallback message.
        }
      }
      _showSnackBar(message);
    } catch (error) {
      _showSnackBar('Unable to delete account: $error');
    } finally {
      if (mounted) {
        setState(() => _deleteInFlight = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitablColors.surface,
      appBar: GlassAppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MitablSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header Card ──
            MitablCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: MitablColors.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 28,
                      color: MitablColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chef Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: MitablColors.onSurface,
                            fontFamily: 'Nunito',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'chef@mitabl.com',
                          style: TextStyle(
                            fontSize: 13,
                            color: MitablColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            MitablChip(
                              label: 'ACTIVE',
                              selected: true,
                            ),
                            const SizedBox(width: 8),
                            MitablChip(
                              label: 'PRO TIER',
                              selected: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Account Preferences ──
            const Text(
              'Account Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            MitablCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline,
                        color: MitablColors.onSurfaceVariant),
                    title: const Text('Personal Info'),
                    trailing: const Icon(Icons.chevron_right,
                        color: MitablColors.onSurfaceVariant),
                    onTap: () {
                      final routeId = widget.routeArguments?.id;
                      if (routeId == 'foodie') {
                        navigatorKey.currentState!
                            .pushNamed('/EditProfileFoodie');
                        return;
                      }
                      navigatorKey.currentState!.pushNamed('/ProfileCook');
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.language,
                        color: MitablColors.onSurfaceVariant),
                    title: const Text('Language'),
                    trailing: const Icon(Icons.chevron_right,
                        color: MitablColors.onSurfaceVariant),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.lock_outline,
                        color: MitablColors.onSurfaceVariant),
                    title: const Text('Login & Security'),
                    trailing: const Icon(Icons.chevron_right,
                        color: MitablColors.onSurfaceVariant),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Notifications ──
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            MitablCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined,
                        color: MitablColors.onSurfaceVariant),
                    title: const Text('Push Notifications'),
                    trailing: IgnorePointer(
                      ignoring: _notificationsUpdating,
                      child: Switch(
                        value: _notificationsEnabled,
                        activeTrackColor: MitablColors.accent,
                        onChanged: _onNotificationChanged,
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.email_outlined,
                        color: MitablColors.onSurfaceVariant),
                    title: const Text('Email Notifications'),
                    trailing: Switch(
                      value: _emailNotificationsEnabled,
                      activeTrackColor: MitablColors.accent,
                      onChanged: (v) =>
                          setState(() => _emailNotificationsEnabled = v),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.fingerprint,
                        color: MitablColors.onSurfaceVariant),
                    title: const Text('Biometric Lock'),
                    trailing: Switch(
                      value: _biometricEnabled,
                      activeTrackColor: MitablColors.accent,
                      onChanged: _onBiometricChanged,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MitablSpacing.listItem),

            // ── Support ──
            const Text(
              'Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: MitablColors.onSurface,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
            MitablCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline,
                        color: MitablColors.onSurfaceVariant),
                    title: const Text('Help Center'),
                    trailing: const Icon(Icons.chevron_right,
                        color: MitablColors.onSurfaceVariant),
                    onTap: _openSupportSheet,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline,
                        color: MitablColors.onSurfaceVariant),
                    title: const Text('Contact Us'),
                    trailing: const Icon(Icons.chevron_right,
                        color: MitablColors.onSurfaceVariant),
                    onTap: _openSupportSheet,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined,
                        color: MitablColors.onSurfaceVariant),
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right,
                        color: MitablColors.onSurfaceVariant),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: MitablColors.error),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(color: MitablColors.error),
                    ),
                    trailing: _deleteInFlight
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right,
                            color: MitablColors.error),
                    onTap: _deleteInFlight ? null : _onDeleteAccountTapped,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save All Changes
            MitablButton(
              label: 'Save All Changes',
              variant: MitablButtonVariant.primary,
              onPressed: () {
                _showSnackBar('Settings saved.');
              },
            ),

            const SizedBox(height: 16),

            // Log out
            Center(
              child: TextButton(
                onPressed: () {
                  context
                      .read<AuthenticationRepository>()
                      .logOut();
                },
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MitablColors.error,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
