import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service de configuration d'environnement
/// Gère automatiquement les URLs selon la plateforme et l'environnement
class EnvConfig {
  // ============================================================
  // CONFIGURATION
  // ============================================================
  // Pour changer l'environnement, modifier cette valeur :
  // - true  = développement (serveur local)
  // - false = production (serveur distant)
  // - null  = auto-détection basée sur le mode de build Flutter
  static const bool? _forceEnvironment = null;
  
  // URLs de production
  static const String _prodBaseUrl = 'https://api.drpharma.ci';
  
  // IP locale pour appareil physique (remplacer par votre IP si nécessaire)
  static const String localMachineIP = '192.168.1.100';
  
  static bool _isInitialized = false;
  static String? _overrideBaseUrl;
  
  /// Vérifie si la configuration est initialisée
  static bool get isInitialized => _isInitialized;
  
  /// Initialise la configuration
  static Future<void> init({String? environment}) async {
    if (_isInitialized) {
      debugPrint('⚠️ [EnvConfig] Déjà initialisé');
      return;
    }
    _isInitialized = true;
    printConfig();
  }
  
  /// Permet de surcharger l'URL de base manuellement (utile pour les tests)
  static void setOverrideBaseUrl(String? url) {
    _overrideBaseUrl = url;
  }
  
  /// Détecte automatiquement l'environnement ou utilise la valeur forcée
  static bool get isDevelopment {
    if (_forceEnvironment != null) {
      return _forceEnvironment!;
    }
    // Auto-détection : debug = dev, release = prod
    return !kReleaseMode;
  }
  
  /// Est en environnement de production
  static bool get isProduction => !isDevelopment;
  
  /// Nom de l'environnement actuel
  static String get environment => isDevelopment ? 'development' : 'production';
  
  /// Mode debug activé
  static bool get isDebugMode => isDevelopment;
  
  /// Retourne l'URL de base de l'API
  static String get baseUrl {
    // 1. Override manuel (priorité maximale)
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }
    
    // 2. Production
    if (isProduction) {
      return _prodBaseUrl;
    }
    
    // 3. Développement - détection automatique selon la plateforme
    return _detectPlatformUrl();
  }
  
  /// Détecte automatiquement l'URL selon la plateforme (dev uniquement)
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
  static String get apiBaseUrl => '\$baseUrl/api';
  
  /// URL de base pour les fichiers storage
  static String get storageBaseUrl => '\$baseUrl/storage/';
  
  /// Timeout des requêtes API en millisecondes
  static int get apiTimeout => 15000;
  
  /// Affiche la configuration actuelle (pour debug)
  static void printConfig() {
    debugPrint('═══════════════════════════════════════');
    debugPrint('📱 [EnvConfig] Configuration actuelle:');
    debugPrint('   Environment: \$environment');
    debugPrint('   Base URL: \$baseUrl');
    debugPrint('   API URL: \$apiBaseUrl');
    debugPrint('   Timeout: \${apiTimeout}ms');
    debugPrint('   Debug Mode: \$isDebugMode');
    debugPrint('═══════════════════════════════════════');
  }
}
