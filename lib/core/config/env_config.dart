/// Environment-specific configuration values
class EnvConfig {
  // Firebase configuration is loaded from google-services.json
  
  // Feature flags
  static const bool enableMDXDictionary = true;
  static const bool enableTatoebaSentences = true;
  static const bool enableOfflineMode = true;
  
  // Debug flags
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );
  
  static const bool skipOnboarding = bool.fromEnvironment(
    'SKIP_ONBOARDING',
    defaultValue: false,
  );
}
