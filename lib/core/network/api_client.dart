import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

class ApiClient {
  late final Dio _dio;
  String? _accessToken;

  Dio get dio => _dio;

  ApiClient() {
    debugPrint('🔧 [ApiClient] Initialisation - baseUrl: ${AppConstants.apiBaseUrl}');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('➡️ [ApiClient] REQUEST: ${options.method} ${options.uri}');
          debugPrint('➡️ [ApiClient] Data: ${options.data}');
          // Add auth token if available
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('⬅️ [ApiClient] RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ [ApiClient] ERROR: ${error.type} - ${error.message}');
          debugPrint('❌ [ApiClient] Response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  void setToken(String token) {
    _accessToken = token;
  }

  void clearToken() {
    _accessToken = null;
  }

  Options authorizedOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadMultipart(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    // Log détaillé pour le debug
    _logApiError(error);
    
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException(
        message: 'Délai de connexion dépassé. Vérifiez votre connexion internet.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return NetworkException(
        message: 'Impossible de se connecter au serveur. Vérifiez votre connexion.',
      );
    }

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      if (statusCode == 401) {
        return UnauthorizedException(
          message: data is Map ? (data['message'] ?? 'Session expirée. Veuillez vous reconnecter.') : 'Session expirée',
        );
      }
      
      if (statusCode == 404) {
        final serverMessage = data is Map ? data['message'] : null;
        return ServerException(
          message: serverMessage ?? 'Ressource non trouvée',
          statusCode: statusCode,
        );
      }

      if (statusCode == 422 && data is Map && data['errors'] != null) {
        debugPrint("API Validation Error Data: ${data['errors']}");
        return ValidationException(
          errors: Map<String, List<String>>.from(
            data['errors'].map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            ),
          ),
        );
      }

      return ServerException(
        message: data is Map ? (data['message'] ?? 'Erreur serveur') : 'Erreur serveur',
        statusCode: statusCode,
      );
    }

    return ServerException(message: error.message ?? 'Erreur inconnue');
  }
  
  void _logApiError(DioException error) {
    final baseUrl = error.requestOptions.baseUrl;
    final path = error.requestOptions.path;
    final method = error.requestOptions.method;
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    
    // Safely extract message from response
    String? serverMessage;
    if (data is Map) {
      serverMessage = data['message']?.toString();
    }
    
    debugPrint('═══════════════════════════════════════════════════════════');
    if (statusCode == 404) {
      debugPrint('❌ [API ERROR 404] Endpoint non trouvé');
      debugPrint('   URL complète: $baseUrl$path');
      debugPrint('   Méthode: $method');
      debugPrint('   Message serveur: ${serverMessage ?? 'Non disponible'}');
      debugPrint('   Conseil: Vérifiez que la route existe dans api.php');
    } else if (statusCode == 401) {
      debugPrint('🔐 [API ERROR 401] Non authentifié');
      debugPrint('   URL: $path');
      debugPrint('   Conseil: Vérifiez le token d\'authentification');
    } else if (statusCode == 500) {
      debugPrint('🔥 [API ERROR 500] Erreur serveur interne');
      debugPrint('   URL: $path');
      debugPrint('   Message: ${serverMessage ?? 'N/A'}');
    } else if (error.type == DioExceptionType.connectionError) {
      debugPrint('🌐 [API ERROR] Impossible de se connecter');
      debugPrint('   URL tentée: $baseUrl');
      debugPrint('   Conseil: Vérifiez que le serveur Laravel est démarré (php artisan serve)');
    } else {
      debugPrint('⚠️ [API ERROR] Code: $statusCode');
      debugPrint('   URL: $path');
    }
    debugPrint('═══════════════════════════════════════════════════════════');
  }
}
