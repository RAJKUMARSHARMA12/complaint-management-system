import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:major_project/widgets/feedback_dialog.dart';

void main() {
  group('FeedbackDialog Widget Tests (TDD)', () {
    testWidgets('shows validation error if submitted without selecting a rating', (tester) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => FeedbackDialog(
                      complaintId: 'cmp123',
                      onSubmit: (rating, comments) async {
                        submitted = true;
                        return true;
                      },
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Rate Resolution'), findsOneWidget);
      expect(find.byKey(const Key('feedback_submit_button')), findsOneWidget);

      // Attempt to submit without selecting stars
      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Please select a star rating (1 to 5).'), findsOneWidget);
      expect(submitted, isFalse);
    });

    testWidgets('selects rating, inputs comment, and invokes onSubmit callback', (tester) async {
      int? capturedRating;
      String? capturedComment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => FeedbackDialog(
                      complaintId: 'cmp123',
                      onSubmit: (rating, comments) async {
                        capturedRating = rating;
                        capturedComment = comments;
                        return true;
                      },
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap 5 stars
      await tester.tap(find.byKey(const Key('feedback_star_5')));
      await tester.pumpAndSettle();

      expect(find.text('Highly Satisfied'), findsOneWidget);

      // Enter optional comment
      await tester.enterText(
        find.byKey(const Key('feedback_comments_field')),
        'Super fast turnaround, thank you!',
      );
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('feedback_submit_button')));
      await tester.pumpAndSettle();

      expect(capturedRating, 5);
      expect(capturedComment, 'Super fast turnaround, thank you!');
      // Dialog should be dismissed
      expect(find.text('Rate Resolution'), findsNothing);
    });
  });
}
