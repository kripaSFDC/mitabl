import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mitabl_user/model/user_model.dart';
import 'package:mitabl_user/repos/support_ticket_repository.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository({UserModel? user}) : _user = user;

  final UserModel? _user;

  @override
  UserModel? get currentUser => _user;

  @override
  Future<UserModel?> getUser() async => _user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GlobalConfiguration().loadFromMap({
      'api_base_url': 'https://api.example.com/api/',
    });
  });

  group('SupportTicketRepository', () {
    test('createSupportTicket maps payload and required headers', () async {
      late http.Request capturedRequest;

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'status': 200,
            'isSuccess': true,
            'message': 'Contact Message Sent Successfully',
            'data': {'id': 99, 'ticket_number': 'T-99'}
          }),
          200,
        );
      });

      final userRepository = _FakeUserRepository(
        user: UserModel.fromJson({
          'status': 200,
          'isSuccess': true,
          'data': {
            'access_token': 'abc-token',
            'token_type': 'Bearer',
            'user': {'id': 1}
          }
        }),
      );

      final repository = SupportTicketRepository(
        userRepository: userRepository,
        httpClient: mockClient,
      );

      final response = await repository.createSupportTicket(
        requesterEmail: 'user@example.com',
        subject: 'Need help',
        description: 'Please review this issue',
      );

      expect(response['status'], 200);
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.toString(),
          'https://api.example.com/api/support/ticket');
      expect(capturedRequest.headers['authorization'], 'Bearer abc-token');
      expect(capturedRequest.headers['x-authenticated-channel'], 'mobile_app');

      final body =
          jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['requester_email'], 'user@example.com');
      expect(body['subject'], 'Need help');
      expect(body['description'], 'Please review this issue');
    });

    test('getSupportTicket maps id in path and attaches channel headers',
        () async {
      late http.Request capturedRequest;

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'status': 200,
            'isSuccess': true,
            'data': {
              'id': 42,
              'status': 'open',
            }
          }),
          200,
        );
      });

      final repository = SupportTicketRepository(
        userRepository: _FakeUserRepository(),
        httpClient: mockClient,
      );

      final response = await repository.getSupportTicket(id: 42);

      expect(response['status'], 200);
      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.url.toString(),
          'https://api.example.com/api/support/ticket/42');
      expect(capturedRequest.headers['x-client-channel'], 'mobile_app');
      expect(capturedRequest.headers.containsKey('authorization'), isFalse);
    });

    test('replyToSupportTicket posts message and ticket token header',
        () async {
      late http.Request capturedRequest;

      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'status': 200,
            'isSuccess': true,
            'message': 'Reply added.',
            'data': {'reply_id': 5}
          }),
          200,
        );
      });

      final repository = SupportTicketRepository(
        userRepository: _FakeUserRepository(),
        httpClient: mockClient,
      );

      final response = await repository.replyToSupportTicket(
        id: 55,
        message: 'Any updates?',
        ticketToken: 'ticket-token',
      );

      expect(response['status'], 200);
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.toString(),
          'https://api.example.com/api/support/ticket/55/reply');
      expect(capturedRequest.headers['x-ticket-token'], 'ticket-token');

      final body =
          jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['message'], 'Any updates?');
    });
  });
}
