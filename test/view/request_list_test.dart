import 'dart:async';

import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/my_requests_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/view/screens/buyer/request/request_status_tracking.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The list screen is where DoD's four-state rule and the `?status=` 400 both
/// have to hold at once. The filter assertion is the load-bearing one: 'All'
/// MUST reach the repository as a null status, because that bare
/// `z.enum().optional()` rejects a blank value.
PartRequest _req(String id) => PartRequest.fromJson({
  'id': id, 'buyerId': 'usr_buyer', 'regNumber': 'LM19XYZ',
  'categoryId': 'cat_brakes', 'partName': 'Front brake discs', 'status': 'OPEN',
  'offerCount': 3, 'createdAt': '2026-09-01T10:15:00.000Z',
  'updatedAt': '2026-09-01T10:15:00.000Z',
  'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  'vehicle': {'id': 'veh_1', 'regNumber': 'LM19XYZ', 'make': 'BMW',
      'model': '320d', 'year': 2019},
  'images': <Object?>[],
});

Ok<Paged<PartRequest>> _page(List<String> ids, {required int total}) => Ok(
  Paged<PartRequest>([for (final id in ids) _req(id)],
      PageMeta(page: 1, limit: 20, pageSize: ids.length, total: total,
          totalPages: 1, hasNextPage: false, hasPreviousPage: false)),
);

/// A first page that never answers, which is the only honest way to hold the
/// screen in its Loading state.
class _HangingRepository extends FakeRequestsRepository {
  @override
  Future<ApiResult<Paged<PartRequest>>> listMine(
          {int page = 1, int limit = 20, RequestStatus? status}) =>
      Completer<ApiResult<Paged<PartRequest>>>().future;
}

void main() {
  late FakeRequestsRepository repo;

  void register(FakeRequestsRepository r) {
    repo = r;
    // The three injected no-ops let this run with no Fluttertoast platform
    // channel and no modal loading dialog.
    Get.put<MyRequestsController>(MyRequestsController(r,
        toast: (_) {}, showBusy: () {}, hideBusy: () {}));
  }

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> pump(WidgetTester t) async {
    await t.pumpWidget(const GetMaterialApp(home: RequestStatusTrackingPage()));
    await t.pumpAndSettle();
  }

  testWidgets('an unanswered first page renders the shared spinner',
      (t) async {
    register(_HangingRepository());
    await t.pumpWidget(const GetMaterialApp(home: RequestStatusTrackingPage()));
    await t.pump();
    expect(find.byType(DiscreteCircleLoading), findsOneWidget);
  });

  testWidgets('a network failure renders its copy and a retry button',
      (t) async {
    register(FakeRequestsRepository()
      ..listResult = const Err(ApiError.network()));
    await pump(t);
    expect(find.text('No internet connection. Check your network and try again.'),
        findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('an empty page renders the empty state and its CTA, not a blank',
      (t) async {
    register(FakeRequestsRepository()
      ..listQueue.add(_page(const [], total: 0)));
    await pump(t);
    expect(find.text('Request a part'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    // The filter row survives an empty result, so the buyer can get back out.
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('a loaded page renders vehicle, category, status and offers',
      (t) async {
    register(FakeRequestsRepository()
      ..listQueue.add(_page(const ['req_1'], total: 1)));
    await pump(t);
    expect(find.text('BMW'), findsOneWidget);
    expect(find.text('320d'), findsOneWidget);
    expect(find.text('Open'), findsWidgets);
    expect(find.text('3 offers · View'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets("selecting 'All' fetches with a null status", (t) async {
    register(FakeRequestsRepository()
      ..listResult = _page(const ['req_1'], total: 1));
    await pump(t);
    await t.tap(find.text('Closed'));
    await t.pumpAndSettle();
    expect(repo.calls.last, 'listMine:1:20:CLOSED');
    await t.tap(find.text('All'));
    await t.pumpAndSettle();
    expect(repo.calls.last, 'listMine:1:20:null');
  });
}
