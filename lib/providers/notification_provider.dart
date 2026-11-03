import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient apiClient;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

  NotificationProvider({required this.apiClient});

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnread => _unreadCount > 0;

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await apiClient.get('/notifications');
      final resData = response.data as Map<String, dynamic>;

      List<dynamic> list = [];
      if (resData['data'] is Map) {
        final dataMap = resData['data'] as Map<String, dynamic>;
        if (dataMap['notifications'] is List) {
          list = dataMap['notifications'] as List<dynamic>;
        }
      } else if (resData['notifications'] is List) {
        list = resData['notifications'] as List<dynamic>;
      }

      _notifications = list
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      _unreadCount = _notifications.where((n) => !n.read).length;
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      if (e.response?.data is Map && e.response!.data['message'] != null) {
        _errorMessage = e.response!.data['message'].toString();
      } else {
        _errorMessage = e.message ?? 'Failed to load notifications';
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].read) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      _unreadCount = _notifications.where((n) => !n.read).length;
      notifyListeners();
    }

    try {
      await apiClient.patch('/notifications/$notificationId/read');
      return true;
    } on DioException catch (e) {
      debugPrint('[NotificationProvider] Failed to mark notification as read: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[NotificationProvider] Error marking read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await apiClient.patch('/notifications/read-all');
      return true;
    } on DioException catch (e) {
      debugPrint('[NotificationProvider] Failed to mark all as read: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[NotificationProvider] Error marking all read: $e');
      return false;
    }
  }
}
