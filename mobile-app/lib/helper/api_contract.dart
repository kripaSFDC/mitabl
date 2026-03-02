import 'package:global_configuration/global_configuration.dart';

class ApiContract {
  static const Duration requestTimeout = Duration(seconds: 15);

  static Uri uri(String path, {Map<String, dynamic>? queryParameters}) {
    final rawBaseUrl =
        GlobalConfiguration().getValue<String>('api_base_url').trim();
    final baseUri = Uri.parse(rawBaseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final resolvedPath =
        '${baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/'}$normalizedPath';

    final normalizedQuery = <String, String>{};
    queryParameters?.forEach((key, value) {
      if (value == null) return;
      final serialized = value.toString().trim();
      if (serialized.isEmpty) return;
      normalizedQuery[key] = serialized;
    });

    return baseUri.replace(
      path: resolvedPath,
      queryParameters: normalizedQuery.isEmpty ? null : normalizedQuery,
    );
  }

  static String webUrl(String path) {
    final rawBaseUrl =
        GlobalConfiguration().getValue<String>('base_url').trim();
    final baseUri = Uri.parse(rawBaseUrl);
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final resolvedPath =
        '${baseUri.path.endsWith('/') ? baseUri.path : '${baseUri.path}/'}$normalizedPath';

    return baseUri.replace(path: resolvedPath).toString();
  }
}
