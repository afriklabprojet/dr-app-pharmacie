import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'DR-PHARMA Pharmacie';
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://10.0.2.2:8000';
  }
  static String get apiBaseUrl => '$baseUrl/api';
  static String get storageBaseUrl => '$baseUrl/storage/';
  
  // Storage Keys

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
