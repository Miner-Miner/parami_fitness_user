/// Location of the remotely managed Parami Gym API configuration.
class ApiConfig {
  const ApiConfig._();

  static const configUrl =
      'https://www.coreaxistechnologies.website/parami-config.json';

  static String normalizeBaseUrl(String value) {
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
