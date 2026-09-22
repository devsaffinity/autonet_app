import 'package:autonect/controller/buyer/review_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart' show SubmittedReview;
import 'package:autonect/view/screens/buyer/detail/review_page.dart';
import 'package:autonect/view/widget/counted_text_field.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/star_rating_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

void main() {
  late FakeReviewsRepository repo;
  late ReviewController controller;

  setUp(() {
    repo = FakeReviewsRepository();
    controller = ReviewController(
      repo,
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    );
    Get.put<ReviewController>(controller);
  });

  tearDown(Get.reset);

  Widget createSubject({
    SubmittedReview? existingReview,
    bool isReviewed = false,
    VoidCallback? onDone,
  }) =>
      GetMaterialApp(
        home: ReviewPage.forOrder(
          orderId: 'o1',
          supplierName: 'Acme Breakers',
          existingReview: existingReview,
          isReviewed: isReviewed,
          onDone: onDone,
        ),
      );

  testWidgets('initial state allows rating and entering review', (t) async {
    await t.pumpWidget(createSubject());
    await t.pumpAndSettle();

    expect(find.text('Rate your experience'), findsOneWidget);
    expect(find.text('How did Acme Breakers do?'), findsOneWidget);
    expect(find.text('Confirm Review'), findsOneWidget);
    expect(find.text('Review Already Submitted'), findsNothing);

    // Initial rating is 0, so submit is disabled
    final button = t.widget<MyButton>(find.widgetWithText(MyButton, 'Confirm Review'));
    expect(button.enabled, isFalse);

    // Tap 4th star
    await t.tap(find.byIcon(Icons.star_border_rounded).at(3));
    await t.pumpAndSettle();

    final buttonAfterRating = t.widget<MyButton>(find.widgetWithText(MyButton, 'Confirm Review'));
    expect(buttonAfterRating.enabled, isTrue);
  });

  testWidgets(
      'pre-existing review shows Review Already Submitted banner and disables inputs',
      (t) async {
    final existing = SubmittedReview(
      id: 'rev_1',
      authorId: 'buyer_1',
      rating: 4,
      text: 'Good quality bumper, quickly delivered.',
      createdAt: DateTime.utc(2026, 9, 20),
    );

    await t.pumpWidget(createSubject(existingReview: existing));
    await t.pumpAndSettle();

    // Banner and pre-populated content
    expect(find.text('Review Already Submitted'), findsOneWidget);
    expect(find.text('Your review'), findsOneWidget);
    expect(find.text('Good quality bumper, quickly delivered.'), findsOneWidget);

    // "Confirm Review" option is removed, "Back to Order" is shown instead
    expect(find.text('Confirm Review'), findsNothing);
    expect(find.text('Back to Order'), findsOneWidget);

    // Star input is disabled
    final starInput = t.widget<StarRatingInput>(find.byType(StarRatingInput));
    expect(starInput.enabled, isFalse);
    expect(starInput.rating, equals(4));

    // Text field is read-only
    final textField = t.widget<CountedTextField>(find.byType(CountedTextField));
    expect(textField.isReadOnly, isTrue);
  });

  testWidgets(
      'submitting when server returns already reviewed switches to already-reviewed view',
      (t) async {
    repo.createResult = Err(const ApiError(
      code: ApiErrorCode.conflict,
      message: 'You have already reviewed this order',
    ));

    await t.pumpWidget(createSubject());
    await t.pumpAndSettle();

    // Select 5 stars
    await t.tap(find.byIcon(Icons.star_border_rounded).at(4));
    await t.pumpAndSettle();

    // Submit review
    await t.tap(find.text('Confirm Review'));
    await t.pumpAndSettle();

    // Dynamically transitions to already-reviewed state
    expect(find.text('Review Already Submitted'), findsOneWidget);
    expect(find.text('Confirm Review'), findsNothing);
    expect(find.text('Back to Order'), findsOneWidget);

    final starInput = t.widget<StarRatingInput>(find.byType(StarRatingInput));
    expect(starInput.enabled, isFalse);
  });
}
