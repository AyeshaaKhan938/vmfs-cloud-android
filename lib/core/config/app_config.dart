class AppConfig {
  static const String appName = 'VMFS USA';
  static const String appTagline = 'Cloud operations on the go';
  static const String appVersion = '2.0.0';
  static const int buildNumber = 10;

  /// Production API base. Override with --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cloud.vmfsusa.com/api/mobile/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 25);
}
