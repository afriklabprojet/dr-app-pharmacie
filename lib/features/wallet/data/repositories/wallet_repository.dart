import 'package:dio/dio.dart';
import '../models/wallet_data.dart';

class WalletRepository {
  final Dio _dio;
  final String _endpoint = '/pharmacy/wallet';

  WalletRepository(this._dio);

  Future<WalletData> getWalletData() async {
    try {
      final response = await _dio.get(_endpoint);
      return WalletData.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to fetch wallet data: $e');
    }
  }
}
