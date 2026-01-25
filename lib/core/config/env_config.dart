import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service de configuration d'environnement
/// Gère automatiquement les URLs selon la plateforme et l'environnement
class EnvConfig {
  static String? _overrideBaseUrl;
  static bool _isInitialized = false;
  
  /// Vérifie si la configuration est initialisée
  static bool get isInitialized => _isInitialized;
  
  /// Initialise la configuration depuis le fichier .env approprié
  static Future<void> init({String? environment}) async {
    if (_isInitialized) {
      debugPrint('⚠️ [EnvConfig] Déjà initialisé, ignoré');
      return;
    }
    
    final env = environment ?? 
        const String.fromEnvironment('ENV', defaultValue: 'development');
    
    debugPrint('🔧 [EnvConfig] Initialisation pour environnement: $env');
    
    String envFile;
    switch (env) {
      case 'production':
        envFile = '.env.production';
        break;
      case 'staging':
        envFile = '.env.staging';
        break;
      default:
        envFile = '.env.development';
    }
    
    try {
      await dotenv.load(fileName: envFile);
      debugPrint('✅ [EnvConfig] Chargé: $envFile');
      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ [EnvConfig] $envFile non trouvé: $e');
      try {
        await dotenv.load(fileName: '.env');
        debugPrint('✅ [EnvConfig] Chargé: .env (fallback)');
        _isInitialized = true;
      } catch (e2) {
        debugPrint('⚠️ [EnvConfig] Aucun fichier .env trouvé: $e2');
        debugPrint('⚠️ [EnvConfig] Utilisation des valeurs par défaut');
        _isInitialized = true; // Continuer avec les valeurs par défaut
      }
    }
  }
  
  /// Permet de surcharger l'URL de base manuellement (utile pour les tests)
  static void setOverrideBaseUrl(String? url) {
    _overrideBaseUrl = url;
  }
  
  /// Retourne l'URL de base de l'API
  /// Prend en compte: override manuel > .env > détection automatique plateforme
  static String get baseUrl {
    // 1. Override manuel (priorité maximale)
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    
    // 2. Variable d'environnement .env
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // 3. Détection automatique selon la plateforme
    return _detectPlatformUrl();
  }
  
  /// Détecte automatiquement l'URL selon la plateforme
  static String _detectPlatformUrl() {
    // Web
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    
    // Mobile
    try {
      if (Platform.isAndroid) {
        // Émulateur Android utilise 10.0.2.2 pour accéder au localhost de l'hôte
        return 'http://10.0.2.2:8000';
      } else if (Platform.isIOS) {
        // Simulateur iOS peut utiliser localhost directement
        return 'http://127.0.0.1:8000';
      }
    } catch (e) {
      // Platform non supportée
    }
    
    // Fallback
    return 'http://127.0.0.1:8000';
  }
  
  /// URL de base de l'API (avec /api)
  static String get apiBaseUrl => '$baseUrl/api';
  
  /// URL de base pour les fichiers storage
  static String get storageBaseUrl => '$baseUrl/storage/';
  
  /// Timeout des requêtes API en millisecondes
  static int get apiTimeout {
    final timeout = dotenv.env['API_TIMEOUT'];
    return timeout != null ? int.tryParse(timeout) ?? 15000 : 15000;
  }
  
  /// Nom de l'environnement actuel
  static String get environment => dotenv.env['APP_ENV'] ?? 'development';
  
  /// Mode debug activé
  static bool get isDebugMode {
    final debug = dotenv.env['DEBUG_MODE'];
    return debug?.toLowerCase() == 'true' || environment == 'development';
  }
  
  /// Est en environnement de production
  static bool get isProduction => environment == 'production';
  
  /// Est en environnement de développement
  static bool get isDevelopment => environment == 'development';
  
  /// Affiche la configuration actuelle (pour debug)
  static void printConfig() {
    debugPrint('═══════════════════════════════════════');
    debugPrint('📱 [EnvConfig] Configuration actuelle:');
    debugPrint('   Environment: $environment');
    debugPrint('   Base URL: $baseUrl');
    debugPrint('   API URL: $apiBaseUrl');
    debugPrint('   Timeout: ${apiTimeout}ms');
    debugPrint('   Debug Mode: $isDebugMode');
    debugPrint('═══════════════════════════════════════');
  }
}
