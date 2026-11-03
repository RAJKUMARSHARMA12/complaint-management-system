import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/core/network/api_client.dart';
import 'package:major_project/core/storage/secure_storage_service.dart';
import 'package:major_project/providers/notification_provider.dart';

class FakeStorageService implements StorageService {
  String? token = 'fake_token';

  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> deleteAll() async {}
  @override
  Future<void> saveToken(String val) async => token = val;
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> deleteToken() async => token = null;
  @override
  Future<void> saveUserData(Map<String, dynamic> data) async {}
  @override
  Future<Map<String, dynamic>?> getUserData() async => null;
  @override
  Future<void> deleteUserData() async {}
  @override
  Future<void> clearAuth() async => token = null;
}

void main() {
  group('NotificationProvider State & Operations (TDD)', () {
    late ApiClient apiClient;
    late Dio dio;
    late NotificationProvider provider;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:5001/api'));
      apiClient = ApiClient(
        storageService: FakeStorageService(),
        baseUrl: 'http://localhost:5001/api',
        customDio: dio,
      );
      provider = NotificationProvider(apiClient: apiClient);
    });

    test('fetchNotifications fetches notification list and unread count', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/notifications') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'unreadCount': 2,
                      'notifications': [
                        {
                          'id': 'notif1',
                          'title': 'Complaint Assigned',
                          'message': 'Your complaint CMP-0001 has been assigned to Warden Sharma',
                          'type': 'ASSIGNMENT',
                          'isRead': false,
                          'relatedComplaint': {
                            'id': 'cmp123',
                            'complaintId': 'CMP-0001',
                            'title': 'Leaking Tap',
                            'status': 'Assigned',
                          },
                          'createdAt': '2026-11-03T10:00:00.000Z',
                        },
                        {
                          'id': 'notif2',
                          'title': 'New Remark Added',
                          'message': 'Warden posted an update',
                          'type': 'REMARK',
                          'isRead': true,
                          'relatedComplaint': {
                            'id': 'cmp123',
                            'complaintId': 'CMP-0001',
                            'title': 'Leaking Tap',
                            'status': 'Assigned',
                          },
                          'createdAt': '2026-11-03T09:00:00.000Z',
                        },
                      ],
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      expect(provider.notifications, isEmpty);
      expect(provider.unreadCount, 0);

      await provider.fetchNotifications();

      expect(provider.isLoading, isFalse);
      expect(provider.notifications.length, 2);
      expect(provider.unreadCount, 1);
      expect(provider.hasUnread, isTrue);
      expect(provider.notifications[0].title, 'Complaint Assigned');
    });

    test('markAsRead updates target notification isRead state locally and calls API', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/notifications') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'unreadCount': 1,
                      'notifications': [
                        {
                          'id': 'notif1',
                          'title': 'Complaint Assigned',
                          'message': 'Grievance update',
                          'type': 'ASSIGNMENT',
                          'isRead': false,
                          'createdAt': '2026-11-03T10:00:00.000Z',
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/notifications/notif1/read' && options.method == 'PATCH') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'Notification marked as read',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await provider.fetchNotifications();
      expect(provider.unreadCount, 1);
      expect(provider.notifications.first.read, isFalse);

      final success = await provider.markAsRead('notif1');

      expect(success, isTrue);
      expect(provider.unreadCount, 0);
      expect(provider.notifications.first.read, isTrue);
    });

    test('markAllAsRead sets all items as read and clears unread count', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/notifications') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'unreadCount': 2,
                      'notifications': [
                        {
                          'id': 'n1',
                          'title': 'N1',
                          'message': 'M1',
                          'type': 'STATUS_CHANGE',
                          'isRead': false,
                        },
                        {
                          'id': 'n2',
                          'title': 'N2',
                          'message': 'M2',
                          'type': 'STATUS_CHANGE',
                          'isRead': false,
                        },
                      ],
                    },
                  },
                ),
              );
            }
            if (options.path == '/notifications/read-all' && options.method == 'PATCH') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'All notifications marked as read',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      await provider.fetchNotifications();
      expect(provider.unreadCount, 2);

      final success = await provider.markAllAsRead();

      expect(success, isTrue);
      expect(provider.unreadCount, 0);
      expect(provider.notifications.every((n) => n.read), isTrue);
    });
  });
}
