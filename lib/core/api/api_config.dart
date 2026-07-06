/// Environment-based API configuration.
/// Override at build time with: --dart-define=BASE_URL=https://your-server.com
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    // defaultValue: 'https://subscription-manager-api-btqu.onrender.com',
    defaultValue: 'http://127.0.0.1:5232',
  );
}
