import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _client;

  NotificationRemoteDataSourceImpl(this._client);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _client.get('/notifications');
    // Backend returns data: { notifications: [], unread_count: X, pagination: {} }
    final List data = response.data['data']['notifications'];
    return data.map((e) => NotificationModel.fromJson(e)).toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _client.get('/notifications/unread');
    if (response.data['data'] != null && response.data['data']['unread_count'] != null) {
      return response.data['data']['unread_count'] as int;
    }
    return 0;
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client.post('/notifications/$id/read', data: {});
  }

  @override
  Future<void> markAllAsRead() async {
    await _client.post('/notifications/read-all', data: {});
  }
}

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationRemoteDataSourceImpl(client);
});
