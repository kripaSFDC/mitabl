import 'package:mitabl_user/model/user_model.dart';

String requireAccessToken(UserModel? userModel) {
  final token = userModel?.data?.accessToken?.trim();
  if (token == null || token.isEmpty) {
    throw Exception('Authentication token unavailable. Please login again.');
  }

  return token;
}

Map<String, String> buildBearerHeaders(
  String accessToken, {
  bool includeJsonContentType = false,
  Map<String, String> additionalHeaders = const {},
}) {
  final normalizedToken = accessToken.trim();
  if (normalizedToken.isEmpty) {
    throw Exception('Authentication token unavailable. Please login again.');
  }

  final headers = <String, String>{
    'Accept': 'application/json',
    'Authorization': 'Bearer $normalizedToken',
    ...additionalHeaders,
  };

  if (includeJsonContentType) {
    headers['Content-Type'] = 'application/json';
  }

  return headers;
}

Map<String, String> authorizedHeadersForUser(
  UserModel? userModel, {
  bool includeJsonContentType = false,
  Map<String, String> additionalHeaders = const {},
}) {
  return buildBearerHeaders(
    requireAccessToken(userModel),
    includeJsonContentType: includeJsonContentType,
    additionalHeaders: additionalHeaders,
  );
}
