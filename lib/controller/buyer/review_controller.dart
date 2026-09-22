import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking.dart' show SubmittedReview;
import 'package:autonect/data/models/review.dart';
import 'package:autonect/data/repositories/reviews_repository.dart';
import 'package:autonect/domain/conflict_kind.dart';
import 'package:autonect/domain/failure_copy.dart';
import 'package:autonect/domain/review_context.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// Writing one review, and reading a supplier's.
class ReviewController extends ApiController {
  ReviewController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final ReviewsRepository _repo;

  static ReviewController ensure() => Get.isRegistered<ReviewController>()
      ? Get.find<ReviewController>()
      : Get.put(ReviewController(Get.find<ReviewsRepository>()));

  /// ZERO, not four. A seeded four means a buyer who taps nothing and presses
  /// Submit publishes a rating they never chose, against a real supplier.
  final RxInt rating = 0.obs;

  final Rxn<Review> created = Rxn<Review>();

  /// Indicates if the order/booking has already been reviewed, which disables
  /// submission and displays the existing review / read-only state.
  final RxBool alreadyReviewed = false.obs;
  final Rxn<SubmittedReview> existingReview = Rxn<SubmittedReview>();

  /// The READ side only. [rating] and [created] are the write side and belong
  /// to the review screen, which seeds them as it mounts.
  static const StateSlot _reviewsRead = StateSlot('supplierReviews');

  final Rx<ViewState<ReviewsPage>> supplierReviews =
      Rx<ViewState<ReviewsPage>>(const Loading());

  bool get canSubmit =>
      !alreadyReviewed.value && rating.value >= 1 && rating.value <= 5;

  void markAlreadyReviewed([SubmittedReview? review]) {
    alreadyReviewed.value = true;
    if (review != null) {
      existingReview.value = review;
      rating.value = review.rating;
    }
  }

  @override
  void clearErrors() {
    super.clearErrors();
    alreadyReviewed.value = false;
    existingReview.value = null;
  }

  void setRating(int stars) {
    if (alreadyReviewed.value) return;
    rating.value = stars;
    clearFieldError('rating');
  }

  Future<bool> submit({
    required ReviewContext context,
    required int rating,
    String? text,
  }) {
    if (rating < 1 || rating > 5) {
      clearErrors();
      fieldErrors['rating'] = 'Choose a rating from 1 to 5 stars';
      return Future.value(false);
    }
    return run<Review, bool>(
      null,
      () => _repo.create(context: context, rating: rating, text: text),
      (r) {
        switch (r) {
          case Ok(:final value):
            created.value = value;
            return true;
          case Err(:final error):
            _absorbReview(error);
            return false;
        }
      },
    );
  }

  /// The ENTITY this singleton is pointed at is the SUPPLIER being read, not
  /// the order being reviewed: the write side ([rating], [created]) is scoped
  /// by the review screen, which seeds a zero rating and clears errors as it
  /// mounts, while this read side is re-entered from every offer the buyer
  /// opens.
  @override
  void resetForEntity() => supplierReviews.value = const Loading();

  /// PUBLIC route — the offer-detail Reviews tab reads it before the buyer has
  /// any relationship with the supplier at all.
  ///
  /// [runRead], NOT [run]. Through run this tab had BOTH failure modes at once:
  /// opening supplier B while A's read was in flight was dropped as a re-entry,
  /// which painted a non-retryable 'please wait' panel AND never issued B's
  /// read — so what finally appeared under B's name was A's average, A's star
  /// breakdown and A's review text.
  Future<void> loadReviews(String targetId) {
    // A DIFFERENT supplier's tab must not render the previous supplier's
    // average, star breakdown and review rows while its own read is in flight.
    beginEntity(targetId);
    if (supplierReviews.value is! Data<ReviewsPage>) {
      supplierReviews.value = const Loading();
    }
    return runRead(_reviewsRead, () => _repo.forTarget(targetId: targetId), (
      r,
    ) {
      switch (r) {
        case Err(:final error):
          supplierReviews.value = Failed<ReviewsPage>(error);
        case Ok(:final value):
          supplierReviews.value = value.meta.total == 0
              ? const Empty<ReviewsPage>('No reviews yet')
              : Data<ReviewsPage>(value);
      }
    });
  }

  /// Both review 409s are told apart only by prose, and they need opposite
  /// copy: one says wait, the other says you already did this.
  void _absorbReview(ApiError e) {
    if (e.code != ApiErrorCode.conflict) {
      absorb(e);
      return;
    }
    final kind = classifyConflict(e.message);
    if (kind == ConflictKind.alreadyReviewed) {
      alreadyReviewed.value = true;
      formError.value = 'You have already reviewed this order.';
      return;
    }
    formError.value = switch (kind) {
      ConflictKind.notDeliveredYet =>
        'You can review this order once it has been delivered.',
      _ => userMessageFor(e),
    };
  }
}
