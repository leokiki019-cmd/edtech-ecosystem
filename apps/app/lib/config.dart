class AppConfig {
  /// API base URL. Defaults to the local dev API; override at build time:
  /// `flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );

  /// When true the app uses the bundled, persistent on-device demo store
  /// instead of calling the API. This makes the APK fully usable without a
  /// hosted backend. Set `--dart-define=OFFLINE_MODE=false` to use the API.
  static const bool offlineMode = bool.fromEnvironment(
    'OFFLINE_MODE',
    defaultValue: true,
  );
}
