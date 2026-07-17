class AppConfig {
  static const String appName = 'VMFS USA';
  static const String appTagline = 'Cloud operations on the go';
  static const String appVersion = '1.0.1';
  static const int buildNumber = 2;

  /// Production API base. Override with --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cloud.vmfsusa.com/api/mobile/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 25);
  static const Duration receiveTimeout = Duration(seconds: 35);
}
