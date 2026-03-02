import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mitabl_user/helper/api_contract.dart';
import 'package:mitabl_user/repos/user_repository.dart';

class SupportTicketRepository {
  SupportTicketRepository({
    required UserRepository userRepository,
    http.Client? httpClient,
  })  : _userRepository = userRepository,
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null;

  static const String authenticatedChannelHeader =
      'X-Authenticated-Channel';
  static const String fallbackChannelHeader = 'X-Client-Channel';
  static const String mobileAppChannel = 'mobile_app';

  final UserRepository _userRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;

  Future<String?> _accessTokenOrNull() async {
    final currentUser =
        _userRepository.currentUser ?? await _userRepository.getUser();
    final token = currentUser?.data?.accessToken;

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token;
  }

  Future<Map<String, String>> _jsonHeaders({String? ticketToken}) async {
    final token = await _accessTokenOrNull();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      authenticatedChannelHeader: mobileAppChannel,
      fallbackChannelHeader: mobileAppChannel,
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (ticketToken != null && ticketToken.trim().isNotEmpty) {
      headers['X-Ticket-Token'] = ticketToken.trim();
    }

    return headers;
  }

  Future<Map<String, dynamic>> createSupportTicket({
    required String requesterEmail,
    required String subject,
    required String description,
    String? requesterName,
    String? requesterPhone,
    String? category,
    String? priority,
    int? orderId,
    int? mikitchnId,
  }) async {
    final url = ApiContract.uri('/support/ticket');
    final response = await _httpClient.post(
      url,
      headers: await _jsonHeaders(),
      body: jsonEncode({
        'requester_name': requesterName,
        'requester_email': requesterEmail,
        'requester_phone': requesterPhone,
        'subject': subject,
        'description': description,
        'category': category,
        'priority': priority,
        'order_id': orderId,
        'mikitchn_id': mikitchnId,
      }..removeWhere((key, value) => value == null)),
    );

    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> getSupportTicket({
    required int id,
    String? ticketToken,
  }) async {
    final url = ApiContract.uri('/support/ticket/$id');
    final response = await _httpClient.get(
      url,
      headers: await _jsonHeaders(ticketToken: ticketToken),
    );

    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> replyToSupportTicket({
    required int id,
    required String message,
    String? reopenReason,
    String? ticketToken,
  }) async {
    final url = ApiContract.uri('/support/ticket/$id/reply');
    final response = await _httpClient.post(
      url,
      headers: await _jsonHeaders(ticketToken: ticketToken),
      body: jsonEncode({
        'message': message,
        'reopen_reason': reopenReason,
      }..removeWhere((key, value) => value == null)),
    );

    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (!decoded.containsKey('status')) {
      decoded['status'] = response.statusCode;
    }

    return decoded;
  }

  void dispose() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}
