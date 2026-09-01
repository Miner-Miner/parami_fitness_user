/// Configuration for the Parami Gym Odoo API.
///
/// Override either value at build/run time when connecting to another Odoo
/// environment, for example:
/// `flutter run --dart-define=API_BASE_URL=https://example.com
///              --dart-define=ODOO_DATABASE=parami_demo`
class ApiConfig {
  const ApiConfig._();

  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://parami.coreaxistechnologies.website',
  );

  static const String defaultDatabase = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: 'parami_demo',
  );

  static String normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
