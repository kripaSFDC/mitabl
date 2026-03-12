import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mitabl_user/helper/app_navigator.dart';
import 'package:mitabl_user/helper/common_appbar.dart';
import 'package:mitabl_user/helper/route_arguement.dart';
import 'package:mitabl_user/helper/app_config.dart' as config;
import 'package:mitabl_user/repos/authentication_repository.dart';
import 'package:mitabl_user/repos/support_ticket_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

      final message = result['message']?.toString() ??
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
                  decoration: const InputDecoration(labelText: 'Reply message'),
                  maxLines: 2,
                ),
                SizedBox(height: config.AppConfig(context).appHeight(2)),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed:
                          _supportActionInFlight ? null : _submitSupportTicket,
                      child: const Text('Create Ticket'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _supportActionInFlight ? null : _loadSupportTicket,
                      child: const Text('Get Ticket'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _supportActionInFlight ? null : _replyToSupportTicket,
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

    if (!shouldDelete) {
      return;
    }

    setState(() => _deleteInFlight = true);

    try {
      final repository = context.read<UserRepository>();
      final response = await repository.deleteAccount();
      if (response.statusCode >= 200 && response.statusCode < 300) {
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
    return SafeArea(
      child: Scaffold(
        appBar: const CommonAppBar(
          title: 'Settings',
          isFilter: false,
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: EdgeInsets.only(
            left: config.AppConfig(context).appWidth(3),
            right: config.AppConfig(context).appWidth(3),
          ),
          child: Column(
            children: [
              SizedBox(
                height: config.AppConfig(context).appHeight(3),
              ),
              ListTile(
                onTap: () {
                  final routeId = widget.routeArguments?.id;
                  if (routeId == 'foodie') {
                    navigatorKey.currentState!.pushNamed('/EditProfileFoodie');
                    return;
                  }
                  navigatorKey.currentState!.pushNamed('/ProfileCook');
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/img/background.svg',
                            height: config.AppConfig(context).appHeight(4.5),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          widthFactor: 2,
                          child: SvgPicture.asset(
                            'assets/img/edit.svg',
                            height: config.AppConfig(context).appHeight(2),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Edit profile',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  size: config.AppConfig(context).appWidth(6),
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
              ListTile(
                onTap: () {
                  // navigatorKey.currentState!.pushNamed('/SettingsCook');
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/img/notification.svg',
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Notification',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
                trailing: SizedBox(
                  width: config.AppConfig(context).appWidth(18),
                  child: IgnorePointer(
                    ignoring: _notificationsUpdating,
                    child: Switch(
                      value: _notificationsEnabled,
                      inactiveTrackColor: Theme.of(context).primaryColorDark,
                      onChanged: _onNotificationChanged,
                    ),
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  _openSupportSheet();
                },
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/img/delete.svg',
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Help & Support',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward,
                  size: config.AppConfig(context).appWidth(6),
                  color: Theme.of(context).primaryColorDark,
                ),
              ),
              ListTile(
                onTap: _deleteInFlight ? null : _onDeleteAccountTapped,
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/img/delete.svg',
                    ),
                    SizedBox(
                      width: config.AppConfig(context).appWidth(4),
                    ),
                    Text(
                      'Delete Account',
                      style: GoogleFonts.gothicA1(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: config.AppConfig(context).appWidth(4.5),
                          fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: _deleteInFlight
                    ? SizedBox(
                        width: config.AppConfig(context).appWidth(6),
                        height: config.AppConfig(context).appWidth(6),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.arrow_forward,
                        size: config.AppConfig(context).appWidth(6),
                        color: Theme.of(context).primaryColorDark,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
