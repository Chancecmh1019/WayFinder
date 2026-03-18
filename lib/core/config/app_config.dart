/// Application configuration for different environments
enum Environment {
  development,
  staging,
  production,
  testing,
}

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final bool enableLogging;
  final bool enableCrashlytics;
  final bool enableAnalytics;
  
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableLogging,
    required this.enableCrashlytics,
    required this.enableAnalytics,
  });
  
  /// Development configuration
  static const AppConfig development = AppConfig(
    environment: Environment.development,
    apiBaseUrl: 'https://dev-api.wayfinder.com',
    enableLogging: true,
    enableCrashlytics: false,
    enableAnalytics: false,
  );
  
  /// Staging configuration
  static const AppConfig staging = AppConfig(
    environment: Environment.staging,
    apiBaseUrl: 'https://staging-api.wayfinder.com',
    enableLogging: true,
    enableCrashlytics: true,
    enableAnalytics: false,
  );
  
  /// Production configuration
  static const AppConfig production = AppConfig(
    environment: Environment.production,
    apiBaseUrl: 'https://api.wayfinder.com',
    enableLogging: false,
    enableCrashlytics: true,
    enableAnalytics: true,
  );
  
  /// Testing configuration
  static const AppConfig testing = AppConfig(
    environment: Environment.testing,
    apiBaseUrl: 'https://test-api.wayfinder.com',
    enableLogging: true,
    enableCrashlytics: false,
    enableAnalytics: false,
  );
  
  bool get isDevelopment => environment == Environment.development;
  bool get isStaging => environment == Environment.staging;
  bool get isProduction => environment == Environment.production;
  bool get isTesting => environment == Environment.testing;
}
