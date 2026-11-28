/// Thrown when required application configuration is missing or blank.
/// Only the key name is reported, never any value.
class ConfigurationException implements Exception {
  final String key;

  const ConfigurationException(this.key);

  @override
  String toString() =>
      'ConfigurationException: required configuration "$key" is missing or empty. Check your .env file.';
}

/// Validated application configuration, loaded once at startup.
class AppConfig {
  final String googleApiKey;
  final String mapTilerApiKey;

  const AppConfig({
    required this.googleApiKey,
    required this.mapTilerApiKey,
  });

  /// Validates values from a loaded environment map (e.g. `dotenv.env`).
  factory AppConfig.fromEnvironment(Map<String, String> env) {
    return AppConfig(
      googleApiKey: _require(env, 'gApiKey'),
      mapTilerApiKey: _require(env, 'mApiKey'),
    );
  }

  static AppConfig? _instance;

  /// The validated configuration. Call [initialize] first.
  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
          'AppConfig.initialize must be called before AppConfig.instance is used.');
    }
    return config;
  }

  static void initialize(Map<String, String> env) {
    _instance = AppConfig.fromEnvironment(env);
  }

  static String _require(Map<String, String> env, String key) {
    final value = env[key];
    if (value == null || value.trim().isEmpty) {
      throw ConfigurationException(key);
    }
    return value;
  }
}
