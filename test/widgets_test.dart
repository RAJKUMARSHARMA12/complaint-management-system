import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/widgets/complaint_card.dart';
import 'package:major_project/widgets/priority_badge.dart';
import 'package:major_project/widgets/status_chip.dart';

void main() {
  group('StatusChip Tests', () {
    testWidgets('renders all 5 complaint statuses with expected labels', (tester) async {
      const statuses = ['Submitted', 'Assigned', 'In Progress', 'Resolved', 'Closed'];

      for (final status in statuses) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatusChip(status: status),
            ),
          ),
        );

        expect(find.text(status), findsOneWidget);
        expect(find.byKey(Key('status_chip_$status')), findsOneWidget);
      }
    });

    testWidgets('defaults gracefully on unknown status', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusChip(status: 'UnknownStatus'),
          ),
        ),
      );

      expect(find.text('UnknownStatus'), findsOneWidget);
    });
  });

  group('PriorityBadge Tests', () {
    testWidgets('renders Low, Medium, High, and Urgent priorities', (tester) async {
      const priorities = ['Low', 'Medium', 'High', 'Urgent'];

      for (final priority in priorities) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PriorityBadge(priority: priority),
            ),
          ),
        );

        expect(find.text(priority), findsOneWidget);
        expect(find.byKey(Key('priority_badge_$priority')), findsOneWidget);
      }
    });
  });

  group('ComplaintCard Tests', () {
    final testComplaint = ComplaintModel(
      id: 'comp_123',
      complaintId: 'CMP-2026-0001',
      title: 'Water Leak in Restroom',
      description: 'Major water leakage on the second floor.',
      categoryId: 'cat_1',
      categoryName: 'Hostel Maintenance',
      location: 'Block A, 2nd Floor',
      priority: 'Urgent',
      status: 'Assigned',
      images: ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg'],
      createdAt: DateTime(2026, 11, 2, 10, 30),
    );

    testWidgets('renders complaint details and attachments accurately', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplaintCard(
              complaint: testComplaint,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('CMP-2026-0001'), findsOneWidget);
      expect(find.text('Water Leak in Restroom'), findsOneWidget);
      expect(find.text('Hostel Maintenance'), findsOneWidget);
      expect(find.text('Block A, 2nd Floor'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('2 images'), findsOneWidget);

      await tester.tap(find.byType(ComplaintCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
