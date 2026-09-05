import 'package:autonect/controller/buyer/accept_offer_controller.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/controller/buyer/request_detail_controller.dart';
import 'package:autonect/controller/buyer/review_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/data/repositories/requests_repository.dart';
import 'package:autonect/services/session_store.dart';
import 'package:autonect/view/screens/buyer/detail/offer_detail.dart';
import 'package:autonect/view/screens/buyer/new_part_request/steps/confirm_step_view.dart';
import 'package:autonect/view/screens/buyer/request/request_detail.dart';
import 'package:autonect/view/screens/buyer/request/request_status_tracking.dart';
import 'package:autonect/view/widget/role_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_buyer_repositories.dart';
import '../fakes/fake_image_picker.dart';

/// `Obx(() => W)` subscribes ONLY to Rx values read SYNCHRONOUSLY inside its own
/// closure. A value read from a child's `builder` — [StateView.builder] runs
/// inside StateView.build, a different build than the closure's — registers no
/// dependency, so that subtree never rebuilds when the value lands.
///
/// Plus the recovery route out of an unconfirmed create, which used to replace
/// the wizard with a bare page that had no back button and no nav bar.

/// The base fake answers `byId` from ONE field, which cannot express 'the read
/// failed, the buyer retried, and the second read succeeded'.
class _QueuedRequests extends FakeRequestsRepository {
  final List<ApiResult<PartRequest>> byIdQueue = [];

  @override
  Future<ApiResult<PartRequest>> byId(String id) async {
    calls.add('byId:$id');
    if (byIdQueue.isNotEmpty) return byIdQueue.removeAt(0);
    return super.byId(id);
  }
}

PartRequest _request({RequestStatus status = RequestStatus.open}) =>
    PartRequest.fromJson({
      'id': 'req_1', 'buyerId': 'usr_buyer', 'regNumber': 'LM19XYZ',
      'categoryId': 'cat_brakes', 'partName': 'Front brake discs',
      'status': status.wire, 'offerCount': 1,
      'createdAt': '2026-09-01T10:15:00.000Z',
      'updatedAt': '2026-09-01T10:15:00.000Z',
      'category': {'id': 'cat_brakes', 'name': 'Brakes'},
      'images': <Object?>[],
    });

Offer _offer() => Offer(
  id: 'off_a',
  requestId: 'req_1',
  supplierId: 'sup_a',
  pricePence: 12999,
  quantity: 1,
  status: OfferStatus.pending,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  supplier: const OfferSupplier(id: 'sup_a', businessName: 'Supplier A'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rx reads inside the Obx tracking zone', () {
    late _QueuedRequests requests;
    late FakeOrdersRepository orders;

    setUp(() {
      Get.testMode = true;
      requests = _QueuedRequests();
      orders = FakeOrdersRepository()..offersResult = Ok([_offer()]);
      Get.put<RequestsRepository>(requests);
      Get.put<OrdersRepository>(orders);
      Get.put(RequestDetailController(requests, orders,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));
      Get.put(AcceptOfferController(orders,
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));
      Get.put(ReviewController(FakeReviewsRepository(),
          toast: (_) {}, showBusy: () {}, hideBusy: () {}));
    });

    tearDown(Get.reset);

    testWidgets('retrying a failed request read makes the offer rows tappable',
        (t) async {
      // A tall surface: the header this retry restores is eight detail rows and
      // two buttons, which on an 800x600 view pushes the offer row out of the
      // ListView's build range entirely — an unbuilt row is not a bug report.
      await t.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => t.binding.setSurfaceSize(null));

      // Retryable, so StateView paints 'Try again' rather than a dead end.
      requests.byIdQueue.add(const Err<PartRequest>(ApiError.network()));
      requests.byIdQueue.add(Ok(_request()));

      await t.pumpWidget(const GetMaterialApp(
          home: BuyerRequestDetailPage(requestId: 'req_1')));
      await t.pumpAndSettle();

      // The row is on screen, but holding a null request: inert.
      expect(find.text('Supplier A'), findsOneWidget);
      await t.tap(find.text('Supplier A'));
      await t.pumpAndSettle();
      expect(find.byType(OfferDetailPage), findsNothing);

      // The retry that used to fix only the header, WITHOUT leaving the screen.
      await t.tap(find.text('Try again'));
      await t.pumpAndSettle();
      expect(find.text('Front brake discs'), findsWidgets);

      await t.tap(find.text('Supplier A'));
      await t.pumpAndSettle();
      expect(find.byType(OfferDetailPage), findsOneWidget);
    });
  });

  group('unconfirmed-create recovery', () {
    late NewRequestController c;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SessionStore.init();
      Get.reset();
      Get.testMode = true;
      // The shell mounts all five tabs at once, so every screen behind the nav
      // bar — profile included — has to find what it reads.
      Get.put<TokenStore>(InMemoryTokenStore());
      Get.put<RequestsRepository>(FakeRequestsRepository());
      Get.put<OrdersRepository>(FakeOrdersRepository()
        ..listResult = const Err(ApiError.network()));
      c = NewRequestController(
        requests: FakeRequestsRepository()
          ..createResult = const Err<PartRequest>(ApiError.timeout()),
        vehicles: FakeVehiclesRepository(),
        uploader: FakeBlobUploader(),
        picker: FakeImagePickerService(),
        tokens: InMemoryTokenStore(),
        toast: (_) {}, showBusy: () {}, hideBusy: () {},
      );
      c.draft
        ..regNumber = 'LM19XYZ'
        ..categoryId = 'cat_brakes'
        ..categoryName = 'Brakes'
        ..region = Region.london
        ..partName = 'Front brake discs'
        ..condition = PartCondition.either
        ..urgency = RequestUrgency.standard;
    });

    tearDown(() {
      c.saveNow();
      Get.reset();
    });

    testWidgets("'Check My Requests' lands inside the shell, nav bar and all",
        (t) async {
      await t.pumpWidget(GetMaterialApp(
          home: Scaffold(body: ConfirmStepView(controller: c))));
      await t.tap(find.text('Send Request'));
      await t.pumpAndSettle();

      await t.ensureVisible(find.text('Check My Requests'));
      await t.pumpAndSettle();
      await t.tap(find.text('Check My Requests'));
      await t.pumpAndSettle();

      expect(find.byType(RequestStatusTrackingPage), findsOneWidget);
      // The whole point: a visible way back off the recovery screen.
      expect(find.byType(RoleNavBar), findsOneWidget);
    });
  });
}
