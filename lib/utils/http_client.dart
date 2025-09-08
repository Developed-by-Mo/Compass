import 'package:http/http.dart' as http;

// No OpenDota API key required

class ApiClient {
  static const String _openDotaBaseUrl = 'https://api.opendota.com/api';

  static Uri buildOpenDotaUri(String path, {Map<String, String>? query}) {
    final Map<String, String> finalQuery = {...?query};
    return Uri.parse(
      '$_openDotaBaseUrl/$path',
    ).replace(queryParameters: finalQuery.isEmpty ? null : finalQuery);
  }

  static Future<http.Response> getOpenDota(
    String path, {
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final uri = buildOpenDotaUri(path, query: query);
    return http.get(uri).timeout(timeout);
  }
}
