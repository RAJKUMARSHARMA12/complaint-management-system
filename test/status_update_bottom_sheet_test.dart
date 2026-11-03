import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/models/complaint_model.dart';
import 'package:major_project/widgets/status_update_bottom_sheet.dart';

void main() {
  group('StatusUpdateBottomSheet Widget Tests (TDD)', () {
    testWidgets('shows validation error when remark is empty', (tester) async {
      bool updated = false;

      final complaint = ComplaintModel(
        id: 'cmp1',
        complaintId: 'CMP-0001',
        title: 'Broken Light in Hostel',
        description: 'Light in Corridor is flickering',
        categoryName: 'Hostel Maintenance',
        priority: 'High',
        status: 'Assigned',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => StatusUpdateBottomSheet(
                      complaint: complaint,
                      allowedTransitions: const ['In Progress'],
                      onUpdateStatus: (status, remark) async {
                        updated = true;
                        return true;
                      },
                    ),
                  );
                },
                child: const Text('Open BottomSheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open BottomSheet'));
      await tester.pumpAndSettle();

      expect(find.text('Update Ticket Status'), findsOneWidget);
      expect(find.text('CMP-0001'), findsOneWidget);
      expect(find.byKey(const Key('transition_chip_In Progress')), findsOneWidget);

      // Scroll and tap submit
      await tester.ensureVisible(find.byKey(const Key('submit_status_button')));
      await tester.tap(find.byKey(const Key('submit_status_button')));
      await tester.pumpAndSettle();

      expect(find.text('An action remark is required.'), findsOneWidget);
      expect(updated, isFalse);
    });

    testWidgets('enforces 5 characters minimum when next status is Resolved', (tester) async {
      final complaint = ComplaintModel(
        id: 'cmp1',
        complaintId: 'CMP-0001',
        title: 'Broken Light',
        description: 'Light in corridor',
        categoryName: 'Hostel Maintenance',
        priority: 'High',
        status: 'In Progress',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => StatusUpdateBottomSheet(
                      complaint: complaint,
                      allowedTransitions: const ['Resolved'],
                      onUpdateStatus: (status, remark) async => true,
                    ),
                  );
                },
                child: const Text('Open BottomSheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open BottomSheet'));
      await tester.pumpAndSettle();

      // Enter short remark (<5 chars)
      await tester.enterText(find.byKey(const Key('status_remark_field')), 'Done');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('submit_status_button')));
      await tester.tap(find.byKey(const Key('submit_status_button')));
      await tester.pumpAndSettle();

      expect(find.text('Action remark must be at least 5 characters when resolving.'), findsOneWidget);
    });

    testWidgets('submits next status and remark successfully and closes bottom sheet', (tester) async {
      String? updatedStatus;
      String? updatedRemark;

      final complaint = ComplaintModel(
        id: 'cmp1',
        complaintId: 'CMP-0001',
        title: 'Broken Light',
        description: 'Corridor light',
        categoryName: 'Hostel Maintenance',
        priority: 'High',
        status: 'Assigned',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => StatusUpdateBottomSheet(
                      complaint: complaint,
                      allowedTransitions: const ['In Progress'],
                      onUpdateStatus: (status, remark) async {
                        updatedStatus = status;
                        updatedRemark = remark;
                        return true;
                      },
                    ),
                  );
                },
                child: const Text('Open BottomSheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open BottomSheet'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('status_remark_field')),
        'Electrician assigned and spare bulb dispatched.',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('submit_status_button')));
      await tester.tap(find.byKey(const Key('submit_status_button')));
      await tester.pumpAndSettle();

      expect(updatedStatus, 'In Progress');
      expect(updatedRemark, 'Electrician assigned and spare bulb dispatched.');
      // BottomSheet is dismissed
      expect(find.text('Update Ticket Status'), findsNothing);
    });
  });
}
