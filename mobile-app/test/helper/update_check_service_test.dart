import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitabl_user/helper/update_check_service.dart';

// Pure helper for testing semver logic without needing class internals.
List<int> _parseVer(String v) =>
    v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();

bool _isBelow(List<int> current, List<int> target) {
  for (var i = 0; i < 3; i++) {
    final c = i < current.length ? current[i] : 0;
    final t = i < target.length ? target[i] : 0;
    if (c < t) return true;
    if (c > t) return false;
  }
  return false;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
    });
  });

  group('semver parsing', () {
    test('parses standard versions', () {
      expect(_parseVer('1.2.3'), [1, 2, 3]);
      expect(_parseVer('1.0.0'), [1, 0, 0]);
      expect(_parseVer('10.20.30'), [10, 20, 30]);
    });
  });

  group('semver comparison', () {
    test('is below when patch is lower', () {
      expect(_isBelow(_parseVer('1.0.0'), _parseVer('1.0.1')), isTrue);
    });

    test('is not below when versions are equal', () {
      expect(_isBelow(_parseVer('1.0.0'), _parseVer('1.0.0')), isFalse);
    });

    test('is not below when current is higher', () {
      expect(_isBelow(_parseVer('1.0.1'), _parseVer('1.0.0')), isFalse);
    });

    test('correctly handles major version comparison', () {
      expect(_isBelow(_parseVer('0.9.9'), _parseVer('1.0.0')), isTrue);
    });
  });

  group('UpdateCheckService.check()', () {
    test('returns none on HTTP 500 without throwing', () async {
      final result = await UpdateCheckService.instance.checkForTest(
        mockCurrentVersion: '1.0.0',
        mockClient: MockClient((_) async => http.Response('error', 500)),
      );
      expect(result.type, UpdateType.none);
    });

    test('returns required when current version is below minimum', () async {
      final result = await UpdateCheckService.instance.checkForTest(
        mockCurrentVersion: '1.0.0',
        mockClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'minimum': '99.0.0',
              'latest': '99.0.0',
              'ios_url': 'https://apps.apple.com/mitabl',
              'android_url': 'https://play.google.com/mitabl',
            }),
            200,
          ),
        ),
      );
      expect(result.type, UpdateType.required);
    });

    test('returns optional when above minimum but below latest', () async {
      final result = await UpdateCheckService.instance.checkForTest(
        mockCurrentVersion: '1.0.0',
        mockClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'minimum': '0.0.1',
              'latest': '99.0.0',
              'ios_url': 'https://apps.apple.com/mitabl',
              'android_url': 'https://play.google.com/mitabl',
            }),
            200,
          ),
        ),
      );
      expect(result.type, UpdateType.optional);
      expect(result.latestVersion, '99.0.0');
    });

    test('returns none when already on latest', () async {
      final result = await UpdateCheckService.instance.checkForTest(
        mockCurrentVersion: '1.0.0',
        mockClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'minimum': '0.0.1',
              'latest': '1.0.0',
            }),
            200,
          ),
        ),
      );
      expect(result.type, UpdateType.none);
    });
  });
}
