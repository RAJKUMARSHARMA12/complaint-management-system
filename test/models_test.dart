import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/models/user_model.dart';
import 'package:major_project/models/category_model.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/models/notification_model.dart';

void main() {
  group('UserModel Serialization', () {
    test('should parse UserModel from backend JSON', () {
      final json = {
        'id': '60d0fe4f5311236168a109ca',
        'name': 'Aarav Mehta',
        'email': 'aarav.mehta@college.edu',
        'role': 'Student',
        'department': 'Computer Science',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '60d0fe4f5311236168a109ca');
      expect(user.name, 'Aarav Mehta');
      expect(user.email, 'aarav.mehta@college.edu');
      expect(user.role, 'Student');
      expect(user.department, 'Computer Science');
    });

    test('should handle _id mapping in UserModel', () {
      final json = {
        '_id': '60d0fe4f5311236168a109cb',
        'name': 'Prof. Sharma',
        'email': 'sharma@college.edu',
        'role': 'Admin',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '60d0fe4f5311236168a109cb');
      expect(user.role, 'Admin');
      expect(user.department, isNull);
    });

    test('should serialize UserModel to JSON', () {
      final user = UserModel(
        id: '123',
        name: 'Test User',
        email: 'test@college.edu',
        role: 'Authority',
        department: 'Hostel Maintenance',
      );

      final json = user.toJson();
      expect(json['id'], '123');
      expect(json['name'], 'Test User');
      expect(json['email'], 'test@college.edu');
      expect(json['role'], 'Authority');
      expect(json['department'], 'Hostel Maintenance');
    });
  });

  group('CategoryModel Serialization', () {
    test('should parse CategoryModel from backend JSON', () {
      final json = {
        '_id': 'cat123',
        'name': 'Hostel & Mess',
        'description': 'Hostel infrastructure and food issues',
        'department': 'Hostel Maintenance',
        'isActive': true,
      };

      final category = CategoryModel.fromJson(json);

      expect(category.id, 'cat123');
      expect(category.name, 'Hostel & Mess');
      expect(category.description, 'Hostel infrastructure and food issues');
      expect(category.department, 'Hostel Maintenance');
      expect(category.isActive, isTrue);
    });

    test('should default isActive to true if omitted', () {
      final json = {
        'id': 'cat456',
        'name': 'Wi-Fi & IT',
        'department': 'Information Technology',
      };

      final category = CategoryModel.fromJson(json);
      expect(category.id, 'cat456');
      expect(category.isActive, isTrue);
      expect(category.description, isNull);
    });
  });

  group('ComplaintModel Serialization', () {
    test('should parse ComplaintModel from backend JSON', () {
      final json = {
        '_id': 'cmp999',
        'complaintId': 'CMP-2026-0001',
        'title': 'Leaking faucet in Block B',
        'description': 'Tap is continuously dripping causing water waste',
        'category': {
          '_id': 'cat123',
          'name': 'Hostel & Mess',
          'department': 'Hostel Maintenance',
        },
        'location': 'Block B, 2nd Floor Washroom',
        'priority': 'Medium',
        'isAnonymous': false,
        'images': ['http://localhost:8080/uploads/tap.jpg'],
        'status': 'Submitted',
        'statusHistory': [
          {
            'status': 'Submitted',
            'remarks': 'Complaint lodged',
            'timestamp': '2026-11-02T10:00:00.000Z',
          }
        ],
        'createdAt': '2026-11-02T10:00:00.000Z',
      };

      final complaint = ComplaintModel.fromJson(json);

      expect(complaint.id, 'cmp999');
      expect(complaint.complaintId, 'CMP-2026-0001');
      expect(complaint.title, 'Leaking faucet in Block B');
      expect(complaint.categoryName, 'Hostel & Mess');
      expect(complaint.location, 'Block B, 2nd Floor Washroom');
      expect(complaint.priority, 'Medium');
      expect(complaint.isAnonymous, isFalse);
      expect(complaint.images.length, 1);
      expect(complaint.status, 'Submitted');
      expect(complaint.statusHistory.length, 1);
    });

    test('should handle string category and feedback', () {
      final json = {
        'id': 'cmp888',
        'complaintId': 'CMP-2026-0002',
        'title': 'Broken desk in LH-101',
        'description': 'Bench is broken',
        'category': 'Academic Infrastructure',
        'priority': 'Low',
        'status': 'Closed',
        'feedback': {
          'rating': 5,
          'comments': 'Fixed promptly, thank you!',
          'submittedAt': '2026-11-02T12:00:00.000Z',
        },
      };

      final complaint = ComplaintModel.fromJson(json);

      expect(complaint.categoryName, 'Academic Infrastructure');
      expect(complaint.feedback, isNotNull);
      expect(complaint.feedback!.rating, 5);
      expect(complaint.feedback!.comments, 'Fixed promptly, thank you!');
    });
  });

  group('NotificationModel Serialization', () {
    test('should parse NotificationModel from backend JSON', () {
      final json = {
        '_id': 'notif123',
        'recipient': 'user123',
        'complaintId': 'CMP-2026-0001',
        'title': 'Status Update',
        'message': 'Your complaint CMP-2026-0001 is now In Progress',
        'type': 'STATUS_CHANGE',
        'read': false,
        'createdAt': '2026-11-02T11:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'notif123');
      expect(notif.recipient, 'user123');
      expect(notif.complaintId, 'CMP-2026-0001');
      expect(notif.title, 'Status Update');
      expect(notif.message, 'Your complaint CMP-2026-0001 is now In Progress');
      expect(notif.type, 'STATUS_CHANGE');
      expect(notif.read, isFalse);
    });
  });
}
