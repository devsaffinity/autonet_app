import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/providers_repository.dart';
import 'package:autonect/data/repositories/reviews_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// One provider — `GET /v1/providers/{id}` plus their reviews.
class ProviderDetailController extends ApiController {
  ProviderDetailController(
    this._repo, {
    ReviewsRepository? reviews,
    super.toast,
    super.showBusy,
    super.hideBusy,
  }) : _injectedReviews = reviews;

  final ProvidersRepository _repo;
  final ReviewsRepository? _injectedReviews;

  /// Resolved lazily, like ProfileController's uploader: constructing this
  /// controller must not fail in a test that only cares about the profile.
  ReviewsRepository get _reviews =>
      _injectedReviews ?? Get.find<ReviewsRepository>();

  static ProviderDetailController ensure() =>
      Get.isRegistered<ProviderDetailController>()
      ? Get.find<ProviderDetailController>()
      : Get.put(ProviderDetailController(Get.find<ProvidersRepository>()));

  static const StateSlot _detailRead = StateSlot('providerDetail');
  static const StateSlot _reviewsRead = StateSlot('providerReviews');

  /// The comp shows two testimonials; the rest live behind the full list.
  static const int _reviewPreview = 5;

  final Rx<ViewState<ServiceProvider>> provider =
      Rx<ViewState<ServiceProvider>>(const Loading());

  /// SEPARATE from [provider], and deliberately not a ViewState.
  ///
  /// Testimonials are a bonus section: a provider whose reviews fail to load
  /// still has a profile worth reading, so a failure here must not blank the
  /// screen. Empty and failed both render as 'no testimonials yet', because
  /// to a buyer they are the same thing.
  final RxList<Review> reviews = <Review>[].obs;

  /// BLANKS FIRST, unconditionally — this controller is reused across pushes,
  /// so opening provider B while A's data sits in the Rx would paint A's name
  /// under B's route for a frame. [runRead] then makes the last id win.
  Future<void> load(String id) {
    provider.value = const Loading();
    reviews.clear();
    return Future.wait([_loadProfile(id), _loadReviews(id)]).then((_) {});
  }

  Future<void> _loadProfile(String id) => runRead(
    _detailRead,
    () => _repo.byId(id),
    (r) {
      switch (r) {
        case Err(:final error):
          provider.value = Failed<ServiceProvider>(error);
        case Ok(:final value):
          provider.value = Data<ServiceProvider>(value);
      }
    },
  );

  Future<void> _loadReviews(String id) => runRead(
    _reviewsRead,
    () => _reviews.forTarget(targetId: id, limit: _reviewPreview),
    (r) {
      switch (r) {
        // Swallowed on purpose — see [reviews].
        case Err():
          reviews.clear();
        case Ok(:final value):
          reviews.assignAll(value.items);
      }
    },
  );
}
