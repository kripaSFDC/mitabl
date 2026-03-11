import 'package:flutter_test/flutter_test.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/auth_headers.dart';

void main() {
  group('auth_headers', () {
    test('requireAccessToken trims surrounding whitespace', () {
      final user = UserModel.fromJson({
        'status': 200,
        'isSuccess': true,
        'data': {
          'access_token': '  abc-token  ',
          'token_type': 'Bearer',
          'user': {'id': 1}
        }
      });

      expect(requireAccessToken(user), 'abc-token');
    });

    test('buildBearerHeaders includes normalized authorization header', () {
      final headers = buildBearerHeaders(
        '  abc-token  ',
        includeJsonContentType: true,
      );

      expect(headers['Accept'], 'application/json');
      expect(headers['Authorization'], 'Bearer abc-token');
      expect(headers['Content-Type'], 'application/json');
    });

    test('buildBearerHeaders rejects blank token values', () {
      expect(
        () => buildBearerHeaders('   '),
        throwsA(isA<Exception>()),
      );
    });
  });
}
