import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/services/session_store.dart';
import 'package:autonect/view/screens/buyer/new_part_request/steps/part_details_step_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_buyer_repositories.dart';
import '../fakes/fake_image_picker.dart';

/// An `RxList` handed to a child as a BARE OBJECT subscribes to NOTHING.
///
/// `Obx(() => W)` registers a dependency only for an Rx whose `value` getter
/// runs inside its own closure. There is no `.value` on an `RxList` to look
/// for, so the narrow question 'is `.value` read in the closure?' cannot see
/// this: the list is first really read in the child's `build`, a different
/// build outside the tracking zone, and the tray then never repaints.
///
/// Every assertion below is against the STEP-2 SCREEN, never against ImageTray
/// alone — the defect is at the call site, and a tray fed a plain list has
/// always painted correctly.
class _GatedRequests extends FakeRequestsRepository {
  /// Holds the ticket call open so the `uploading` frame can be observed.
  Completer<void>? gate;

  @override
  Future<ApiResult<UploadTicket>> createImageUploadTicket(
      String contentType) async {
    final g = gate;
    if (g != null) await g.future;
    return super.createImageUploadTicket(contentType);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NewRequestController c;
  late FakeImagePickerService picker;
  late _GatedRequests requests;
  late FakeBlobUploader uploader;
  late Directory temp;
  late String pathA, pathB;
  late TextEditingController partName, partNumber, description;

  /// A real 1x1 PNG on disk, written HERE and never inside a `testWidgets`
  /// body: that body runs under a fake clock where a `dart:io` future is never
  /// completed, so the write would hang the test rather than fail it. The same
  /// fake clock leaves each tile's `Image.file` read outstanding for the whole
  /// test, which is why the files outlive it — deleting one mid-read turns
  /// into an exception thrown after the test has already passed.
  Future<String> writeImage(String name) async {
    final f = File('${temp.path}${Platform.pathSeparator}$name');
    await f.writeAsBytes(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
        'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));
    return f.path;
  }

  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('image_tray_reactivity');
    pathA = await writeImage('a.png');
    pathB = await writeImage('b.png');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
    Get.reset();
    Get.put<CatalogController>(
      CatalogController(
        FakeCatalogRepository()
          ..result = const Ok([PartCategory(id: 'cat_brakes', name: 'Brakes')]),
        toast: (_) {}, showBusy: () {}, hideBusy: () {},
      ),
      permanent: true,
    );
    picker = FakeImagePickerService();
    requests = _GatedRequests();
    uploader = FakeBlobUploader();
    c = NewRequestController(
      requests: requests,
      vehicles: FakeVehiclesRepository(),
      uploader: uploader,
      picker: picker,
      tokens: InMemoryTokenStore(),
      toast: (_) {}, showBusy: () {}, hideBusy: () {},
    );
    partName = TextEditingController();
    partNumber = TextEditingController();
    description = TextEditingController();
  });

  tearDown(() {
    // Cancels the 500 ms draft debounce every tray change arms; a timer
    // outliving the tree is a test failure in its own right.
    c.saveNow();
    partName.dispose();
    partNumber.dispose();
    description.dispose();
    Get.reset();
  });

  tearDownAll(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  /// Tall enough that the whole form is laid out, so `ensureVisible` only ever
  /// has to scroll — an unbuilt tray is not evidence of a missing repaint.
  Future<void> pumpStep2(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PartDetailsStepView(
          controller: c, partName: partName, partNumber: partNumber,
          description: description, onNext: () {},
        ),
      ),
    ));
    await t.pump();
  }

  /// pick(), the ticket and the PUT are an await each, so the tray has to be
  /// given several frames before it can be held to what it painted. The last
  /// pump also runs out the 500 ms draft debounce that every tray change arms
  /// through `onChanged` — a timer still pending when the tree is disposed
  /// fails the test on its own, whatever the assertions said.
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.pump();
    }
    await t.pump(const Duration(milliseconds: 600));
  }

  /// The upload card's own glyph, which is also the control the buyer taps.
  /// Only the finder moved when the tray was rebuilt to the comp — every
  /// assertion below still holds the SCREEN to the same repaints.
  Future<void> tapAdd(WidgetTester t) async {
    final add = find.byIcon(Icons.file_upload_outlined);
    await t.ensureVisible(add);
    await t.pump();
    await t.tap(add);
    await settle(t);
  }

  /// One X per tile, so this counts tiles without depending on decoded pixels.
  int tiles(WidgetTester t) =>
      t.widgetList(find.byIcon(Icons.close_rounded)).length;

  testWidgets('a second photo renders a second tile', (t) async {
    picker.next.add(FakeImagePickerService.image(path: pathA,
        contentType: 'image/png'));
    await pumpStep2(t);

    await tapAdd(t);
    expect(tiles(t), 1);
    // The FIRST add repaints even unsubscribed: `addFromPicker` writes
    // `rejectionMessage.value = null`, and Rx's `firstRebuild` latch lets that
    // no-op write through once. Nothing announces the second one.
    expect(find.text('4 left'), findsOneWidget);

    picker.next
      ..clear()
      ..add(FakeImagePickerService.image(path: pathB,
          contentType: 'image/png'));
    await tapAdd(t);

    expect(tiles(t), 2);
    expect(find.text('3 left'), findsOneWidget);
  });

  testWidgets('removing a photo removes its tile', (t) async {
    picker.next.add(FakeImagePickerService.image(path: pathA,
        contentType: 'image/png'));
    await pumpStep2(t);
    await tapAdd(t);
    expect(tiles(t), 1);

    // `remove` touches no Rx but the list itself — nothing else can repaint it.
    final x = find.byIcon(Icons.close_rounded).first;
    await t.ensureVisible(x);
    await t.pump();
    await t.tap(x);
    await settle(t);

    expect(tiles(t), 0);
    expect(find.text('5 left'), findsOneWidget);
  });

  testWidgets('queued -> uploading -> uploaded repaints the tray', (t) async {
    picker.next.add(FakeImagePickerService.image(path: pathA,
        contentType: 'image/png'));
    requests.gate = Completer<void>();
    await pumpStep2(t);

    await tapAdd(t);
    // Held at `uploading`: the scrim and its spinner are the only thing on this
    // screen that says the photo has not landed yet.
    expect(find.byType(DiscreteCircleLoading), findsOneWidget);

    requests.gate!.complete();
    await settle(t);

    expect(find.byType(DiscreteCircleLoading), findsNothing);
    expect(tiles(t), 1);
  });

  testWidgets('a failed upload offers Retry, and retrying clears it',
      (t) async {
    picker.next.add(FakeImagePickerService.image(path: pathA,
        contentType: 'image/png'));
    // The FIRST PUT only, so the retry below succeeds and the tile has a
    // failed -> uploading -> uploaded transition to paint its way out of.
    uploader.failOnPutNumber = 1;
    await pumpStep2(t);

    await tapAdd(t);
    expect(find.text('Retry'), findsOneWidget);

    // Deliberately NOT the assertion that carries this test: the one rebuild
    // the add is granted lands after the failure has already been written onto
    // the shared PendingImage, so an unsubscribed tray paints 'Retry' too.
    // Everything past this tap is announced by `slots.refresh()` and nothing
    // else, so an unsubscribed tray is stuck on 'Retry' for good — which is
    // the buyer re-uploading a photo that is already in their request.
    final retry = find.text('Retry');
    await t.ensureVisible(retry);
    await t.pump();
    await t.tap(retry);
    await settle(t);

    expect(find.text('Retry'), findsNothing);
    expect(find.byType(DiscreteCircleLoading), findsNothing);
    expect(tiles(t), 1);
  });
}
