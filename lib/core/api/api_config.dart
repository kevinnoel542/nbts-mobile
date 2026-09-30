class ApiConfig {
  const ApiConfig._();

  static const previewMode = bool.fromEnvironment(
    'UI_PREVIEW',
    defaultValue: false,
  );

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.161:8003/api/v1',
  );

  static Uri endpoint(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$baseUrl/$normalizedPath');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...queryParameters.map((key, value) => MapEntry(key, '$value')),
      },
    );
  }

  static String publicUrl(String value) {
    final cleaned = value.trim();
    final parsed = Uri.tryParse(cleaned);
    if (parsed != null && parsed.hasScheme) return cleaned;

    final apiUri = Uri.parse(baseUrl);
    final origin = apiUri.replace(path: '/', query: null, fragment: null);
    return origin
        .resolve(cleaned.startsWith('/') ? cleaned : '/$cleaned')
        .toString();
  }
}
