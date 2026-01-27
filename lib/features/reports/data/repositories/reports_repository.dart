import 'package:dio/dio.dart';
import '../../../../core/config/env_config.dart';

/// Repository pour les rapports et analytics
class ReportsRepository {
  final Dio _dio;
  
  ReportsRepository({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: EnvConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Get dashboard overview
  Future<Map<String, dynamic>> getOverview({String period = 'week'}) async {
    try {
      final response = await _dio.get(
        '/pharmacy/reports/overview',
        queryParameters: {'period': period},
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Erreur lors du chargement');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get sales report
  Future<Map<String, dynamic>> getSalesReport({String period = 'week'}) async {
    try {
      final response = await _dio.get(
        '/pharmacy/reports/sales',
        queryParameters: {'period': period},
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Erreur lors du chargement');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get orders report
  Future<Map<String, dynamic>> getOrdersReport({String period = 'week'}) async {
    try {
      final response = await _dio.get(
        '/pharmacy/reports/orders',
        queryParameters: {'period': period},
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Erreur lors du chargement');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get inventory report
  Future<Map<String, dynamic>> getInventoryReport() async {
    try {
      final response = await _dio.get('/pharmacy/reports/inventory');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Erreur lors du chargement');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get stock alerts
  Future<Map<String, dynamic>> getStockAlerts() async {
    try {
      final response = await _dio.get('/pharmacy/reports/stock-alerts');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Erreur lors du chargement');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Export report
  Future<Map<String, dynamic>> exportReport({
    required String type,
    String format = 'json',
    String period = 'month',
  }) async {
    try {
      final response = await _dio.get(
        '/pharmacy/reports/export',
        queryParameters: {
          'type': type,
          'format': format,
          'period': period,
        },
      );
      
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception(response.data['message'] ?? 'Erreur lors de l\'export');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      return Exception('Session expirée. Veuillez vous reconnecter.');
    } else if (e.response?.statusCode == 403) {
      return Exception('Accès non autorisé.');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('Connexion timeout. Vérifiez votre connexion internet.');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('Impossible de se connecter au serveur.');
    }
    return Exception(e.response?.data?['message'] ?? 'Une erreur est survenue');
  }
}
