/// Compile-time configuration. ApiClient NEVER reads this — baseUrl is a
/// required constructor argument so tests can pass 'http://test.local' instead
/// of hitting the live API. Only main() touches [fromEnvironment].
///
/// Dev build:
///   flutter run --dart-define=AUTONECT_API_BASE_URL=http://10.0.2.2:4000
class ApiConfig {
  const ApiConfig({required this.baseUrl, this.timeout = const Duration(seconds: 20)});

  final String baseUrl;
  final Duration timeout;

  static const ApiConfig fromEnvironment = ApiConfig(
    baseUrl: String.fromEnvironment(
      'AUTONECT_API_BASE_URL',
      defaultValue: 'https://api.autonect.co.uk',
    ),
    timeout: Duration(
      seconds: int.fromEnvironment('AUTONECT_API_TIMEOUT_SEC', defaultValue: 20),
    ),
  );

  /// Health is the one route with no /v1 prefix.
  static String get healthUrl => '${fromEnvironment.baseUrl}/health';
}
