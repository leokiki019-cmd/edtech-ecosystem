class AppConfig {
  /// API base URL. Defaults to the local dev API; override at build time:
  /// `flutter build web --dart-define=API_BASE_URL=https://your-api.example.com`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );
}
