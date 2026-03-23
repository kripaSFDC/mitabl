import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitabl_user/helper/biometric_service.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/support_ticket_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
import 'package:mitabl_user/widgets/design_tokens.dart';
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
    if (!mounted || savedPreference == null) return;
    setState(() => _notificationsEnabled = savedPreference);
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
          'Biometric authentication is not available on this device.');
      return;
    }
    await BiometricService.instance.setEnabled(enabled);
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);
    _showSnackBar(
        enabled ? 'Biometric lock enabled.' : 'Biometric lock disabled.');
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
    final repository = context.read<SupportTicketRepository>();
    setState(() => _supportActionInFlight = true);
    try {
      final result = await repository.createSupportTicket(
        requesterEmail: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      final message = result['message']?.toString() ??
          'Support ticket created successfully.';
      _showSnackBar(message);
    } catch (error) {
      _showSnackBar('Unable to create ticket: $error');
    } finally {
      if (mounted) setState(() => _supportActionInFlight = false);
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
      if (mounted) setState(() => _supportActionInFlight = false);
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
      if (mounted) setState(() => _supportActionInFlight = false);
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
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: _ticketIdController,
                  decoration:
                      const InputDecoration(labelText: 'Ticket ID'),
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
    if (_deleteInFlight) return;
    final shouldDelete = await showDialog<bool>(
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
    if (!mounted || !shouldDelete) return;
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
                        'miCook Vendor',
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
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: MitablColors.surfaceContainerLow,
                          child: const Icon(Icons.person,
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
                    const Text(
                      'Chef Profile',
                      style: TextStyle(
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: MitablColors.secondaryContainer,
                            borderRadius: MitablRadius.pillBorder,
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: MitablColors.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6DED1),
                            borderRadius: MitablRadius.pillBorder,
                          ),
                          child: const Text(
                            'PRO TIER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: Color(0xFF53443A),
                            ),
                          ),
                        ),
                      ],
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
                          onTap: () {},
                        ),
                        _buildSettingsRow(
                          icon: Icons.security,
                          title: 'Login & Security',
                          subtitle: 'Password and two-factor auth',
                          onTap: () {},
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
                                  color: Color(0xFF4D6548), size: 22),
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
                                  activeColor: MitablColors.primary,
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
                                  color: Color(0xFF4D6548), size: 22),
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
                                activeColor: MitablColors.primary,
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
                          onTap: () {},
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
                      onPressed: () => _showSnackBar('Settings saved.'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MitablColors.primary,
                        foregroundColor: MitablColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor:
                            MitablColors.primary.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(
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
                        backgroundColor: const Color(0xFFFFDAD6),
                        foregroundColor: const Color(0xFF93000A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
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
                  decoration: BoxDecoration(
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
                    color: Color(0xFF89726B), size: 22),
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
                Icon(icon, color: const Color(0xFF89726B), size: 22),
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
