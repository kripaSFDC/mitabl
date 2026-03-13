import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mitabl_user/helper/update_check_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// A modal dialog shown when a required or optional update is available.
///
/// - [UpdateType.required] → non-dismissible, forces user to update.
/// - [UpdateType.optional] → dismissible via "Later" button.
class UpdateGateWidget extends StatelessWidget {
  const UpdateGateWidget({super.key, required this.result});

  final UpdateResult result;

  static Future<void> showIfNeeded(
    BuildContext context,
    UpdateResult result,
  ) async {
    if (result.type == UpdateType.none) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateGateWidget(result: result),
    );
  }

  String get _storeUrl {
    if (Platform.isIOS) return result.iosUrl ?? '';
    return result.androidUrl ?? '';
  }

  Future<void> _openStore() async {
    final url = _storeUrl;
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRequired = result.type == UpdateType.required;
    return PopScope(
      canPop: !isRequired,
      child: AlertDialog(
        title: Text(isRequired ? 'Update Required' : 'Update Available'),
        content: Text(
          isRequired
              ? 'A required update (${result.latestVersion}) is available. '
                  'Please update to continue using Mitabl.'
              : 'Version ${result.latestVersion} is available with new features '
                  'and improvements.',
        ),
        actions: [
          if (!isRequired)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: _openStore,
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
