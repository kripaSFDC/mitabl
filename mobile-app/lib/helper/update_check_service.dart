import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/helper/app_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateType { none, optional, required }

class UpdateResult {
  const UpdateResult({
    required this.type,
    this.latestVersion,
    this.iosUrl,
    this.androidUrl,
  });

  const UpdateResult.none()
      : type = UpdateType.none,
        latestVersion = null,
        iosUrl = null,
        androidUrl = null;

  final UpdateType type;
  final String? latestVersion;
  final String? iosUrl;
  final String? androidUrl;
}

/// Checks whether the running app version meets the backend's minimum version
/// requirement.
///
/// The backend should expose `GET /app/version` returning:
/// ```json
/// {
///   "minimum": "1.0.0",
///   "latest":  "1.2.0",
///   "ios_url": "https://apps.apple.com/...",
///   "android_url": "https://play.google.com/..."
/// }
/// ```
class UpdateCheckService {
  UpdateCheckService._();

  static final UpdateCheckService instance = UpdateCheckService._();

  /// Returns an [UpdateResult] describing whether/what update is available.
  /// Never throws — returns [UpdateResult.none] on any error so the app
  /// continues normally when the endpoint is unavailable.
  Future<UpdateResult> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _parseVersion(info.version);

      final response = await http
          .get(ApiContract.uri('app/version'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return const UpdateResult.none();

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final minimum = _parseVersion(body['minimum'] as String? ?? '0.0.0');
      final latest = _parseVersion(body['latest'] as String? ?? '0.0.0');

      if (_isBelow(current, minimum)) {
        return UpdateResult(
          type: UpdateType.required,
          latestVersion: body['latest'] as String?,
          iosUrl: body['ios_url'] as String?,
          androidUrl: body['android_url'] as String?,
        );
      }

      if (_isBelow(current, latest)) {
        return UpdateResult(
          type: UpdateType.optional,
          latestVersion: body['latest'] as String?,
          iosUrl: body['ios_url'] as String?,
          androidUrl: body['android_url'] as String?,
        );
      }

      return const UpdateResult.none();
    } catch (e) {
      AppLogger.warn('UpdateCheckService: check failed silently — $e');
      return const UpdateResult.none();
    }
  }

  List<int> _parseVersion(String v) {
    return v
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
  }

  bool _isBelow(List<int> current, List<int> target) {
    for (var i = 0; i < 3; i++) {
      final c = i < current.length ? current[i] : 0;
      final t = i < target.length ? target[i] : 0;
      if (c < t) return true;
      if (c > t) return false;
    }
    return false;
  }

  /// Test-only: accepts a mock [http.Client] and a pre-set version string to
  /// bypass the [PackageInfo] platform plugin.
  Future<UpdateResult> checkForTest({
    required String mockCurrentVersion,
    required http.Client mockClient,
  }) async {
    try {
      final current = _parseVersion(mockCurrentVersion);
      final response = await mockClient
          .get(ApiContract.uri('app/version'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return const UpdateResult.none();

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final minimum = _parseVersion(body['minimum'] as String? ?? '0.0.0');
      final latest = _parseVersion(body['latest'] as String? ?? '0.0.0');

      if (_isBelow(current, minimum)) {
        return UpdateResult(
          type: UpdateType.required,
          latestVersion: body['latest'] as String?,
          iosUrl: body['ios_url'] as String?,
          androidUrl: body['android_url'] as String?,
        );
      }

      if (_isBelow(current, latest)) {
        return UpdateResult(
          type: UpdateType.optional,
          latestVersion: body['latest'] as String?,
          iosUrl: body['ios_url'] as String?,
          androidUrl: body['android_url'] as String?,
        );
      }

      return const UpdateResult.none();
    } catch (_) {
      return const UpdateResult.none();
    }
  }
}
