import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/models/user_model.dart';
import 'package:major_project/widgets/assign_authority_dialog.dart';

void main() {
  group('AssignAuthorityDialog Widget Tests (TDD)', () {
    final mockStaff = [
      UserModel(
        id: 'auth1',
        name: 'Warden Sharma',
        email: 'warden@college.edu',
        role: 'authority',
        department: 'Hostel Maintenance',
      ),
      UserModel(
        id: 'auth2',
        name: 'Mr. Spark',
        email: 'electrician@college.edu',
        role: 'authority',
        department: 'Electrical Maintenance',
      ),
    ];

    testWidgets('renders dialog with staff list, remark field, and buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignAuthorityDialog(
              complaintId: 'c1',
              complaintTitle: 'Water pipe leaking',
              authorityStaff: mockStaff,
              onAssign: (authId, authName, remark) async => true,
            ),
          ),
        ),
      );

      expect(find.text('Assign Complaint'), findsOneWidget);
      expect(find.text('Water pipe leaking'), findsOneWidget);
      expect(find.text('Select Authority Staff'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Assign'), findsOneWidget);
    });

    testWidgets('selecting staff and entering remark calls onAssign with correct payload', (tester) async {
      String? selectedId;
      String? selectedName;
      String? enteredRemark;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignAuthorityDialog(
              complaintId: 'c1',
              complaintTitle: 'Water pipe leaking',
              authorityStaff: mockStaff,
              onAssign: (authId, authName, remark) async {
                selectedId = authId;
                selectedName = authName;
                enteredRemark = remark;
                return true;
              },
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select Warden Sharma
      await tester.tap(find.text('Warden Sharma (Hostel Maintenance)').last);
      await tester.pumpAndSettle();

      // Enter remark
      await tester.enterText(find.byType(TextField), 'Urgent repair required on 2nd floor');
      await tester.pumpAndSettle();

      // Tap Assign
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();

      expect(selectedId, 'auth1');
      expect(selectedName, 'Warden Sharma');
      expect(enteredRemark, 'Urgent repair required on 2nd floor');
    });

    testWidgets('Assign button is disabled when no authority is selected', (tester) async {
      bool called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignAuthorityDialog(
              complaintId: 'c1',
              complaintTitle: 'Water pipe leaking',
              authorityStaff: mockStaff,
              onAssign: (authId, authName, remark) async {
                called = true;
                return true;
              },
            ),
          ),
        ),
      );

      // Tap Assign without selecting staff
      final assignButtonFinder = find.widgetWithText(ElevatedButton, 'Assign');
      expect(tester.widget<ElevatedButton>(assignButtonFinder).onPressed, isNull);

      expect(called, isFalse);
    });
  });
}
