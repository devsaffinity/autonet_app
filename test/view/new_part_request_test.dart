import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/services/session_store.dart';
import 'package:autonect/view/screens/buyer/new_part_request/steps/confirm_step_view.dart';
import 'package:autonect/view/screens/buyer/new_part_request/steps/part_details_step_view.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_buyer_repositories.dart';
import '../fakes/fake_image_picker.dart';

/// Step 2 is where every one of the 13 create fields is actually produced. The
/// dropdown assertions are the point of this file: the screen it replaces
/// offered 'Refurbished' and 'Normal', neither of which exists on the wire, so
/// a buyer who picked either got a 400 after filling the whole form.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NewRequestController c;
  late TextEditingController partName, partNumber, description;

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
    c = NewRequestController(
      requests: FakeRequestsRepository(),
      vehicles: FakeVehiclesRepository(),
      uploader: FakeBlobUploader(),
      picker: FakeImagePickerService(),
      tokens: InMemoryTokenStore(),
      toast: (_) {}, showBusy: () {}, hideBusy: () {},
    );
    partName = TextEditingController();
    partNumber = TextEditingController();
    description = TextEditingController();
  });

  tearDown(() {
    c.saveNow();
    partName.dispose();
    partNumber.dispose();
    description.dispose();
    Get.reset();
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  Future<void> pumpStep2(WidgetTester t) => t.pumpWidget(host(
    PartDetailsStepView(
      controller: c, partName: partName, partNumber: partNumber,
      description: description, onNext: () {},
    ),
  ));

  Future<void> pick<T>(WidgetTester t, String label) async {
    final field = find.byType(DropdownButton2<T>);
    await t.ensureVisible(field);
    await t.pumpAndSettle();
    await t.tap(field);
    await t.pumpAndSettle();
    await t.tap(find.text(label).last);
    await t.pumpAndSettle();
  }

  testWidgets('step 2 renders the category and region controls', (t) async {
    await pumpStep2(t);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Choose a part category'), findsOneWidget);
    expect(find.text('Region'), findsOneWidget);
    // The select RESTS on its hint. Region was a twelve-chip grid when this
    // file was written; what mattered then and still matters is that nothing
    // is preselected — the User table has no region column to read a default
    // from, and a wrong one fans the request at the wrong suppliers.
    expect(find.text('Choose your region'), findsOneWidget);
  });

  testWidgets('the region select offers all twelve regions', (t) async {
    await pumpStep2(t);
    final field = find.byType(DropdownButton2<Region>);
    await t.ensureVisible(field);
    await t.pumpAndSettle();
    await t.tap(field);
    await t.pumpAndSettle();
    for (final r in Region.values) {
      expect(find.text(r.label), findsWidgets, reason: r.label);
    }
  });

  testWidgets('a chosen region reaches the draft as its wire value',
      (t) async {
    await pumpStep2(t);
    await pick<Region>(t, 'South East');
    // Cancels the 500 ms draft debounce the tap armed; a timer outliving the
    // tree is a test failure, and the wizard really does arm one per keystroke.
    c.saveNow();
    expect(c.draft.region?.wire, 'SOUTH_EAST');
  });

  testWidgets("'Either' and 'Standard' reach the draft as EITHER and STANDARD",
      (t) async {
    await pumpStep2(t);
    await pick<RequestUrgency>(t, 'Standard');
    await pick<PartCondition>(t, 'Either');
    c.saveNow();
    expect(c.draft.urgency?.wire, 'STANDARD');
    expect(c.draft.condition?.wire, 'EITHER');
  });

  testWidgets('Next is blocked until every required field is answered',
      (t) async {
    await pumpStep2(t);
    MyButton next() =>
        t.widget<MyButton>(find.widgetWithText(MyButton, 'Next'));

    expect(next().enabled, isFalse);
    // And the bar SAYS why, in the order the fields appear on screen. A
    // disabled CTA on its own cannot be tapped to find that out.
    expect(
      find.text('Still needed: Part Name, Category, Region, Set Urgency, '
          'Condition'),
      findsOneWidget,
    );

    c.draft
      ..partName = 'Front brake discs'
      ..categoryId = 'cat_brakes'
      ..categoryName = 'Brakes'
      ..region = Region.london
      ..urgency = RequestUrgency.standard
      ..condition = PartCondition.either;
    await pumpStep2(t);

    expect(next().enabled, isTrue);
    expect(find.textContaining('Still needed'), findsNothing);
  });

  testWidgets('a step-1 field never blocks step 2', (t) async {
    // The registration belongs to the previous screen. Gating Next on it would
    // strand the buyer here with no field to fix and no way back but the
    // system gesture.
    c.draft
      ..regNumber = ''
      ..partName = 'Front brake discs'
      ..categoryId = 'cat_brakes'
      ..region = Region.london
      ..urgency = RequestUrgency.standard
      ..condition = PartCondition.either;
    await pumpStep2(t);

    expect(c.draft.validate().keys, contains('regNumber'));
    expect(
      t.widget<MyButton>(find.widgetWithText(MyButton, 'Next')).enabled,
      isTrue,
    );
  });

  testWidgets('every required field is marked, and no optional one is',
      (t) async {
    await pumpStep2(t);
    // Part Name, Category, Region, Set Urgency and Condition carry the marker.
    // Part Number, Description and Upload Photo must not: the API accepts a
    // request without any of the three, and an asterisk on an optional field is
    // the same lie as a missing one on a required field.
    expect(find.text(' *'), findsNWidgets(5));
  });

  testWidgets('the submit CTA is disabled while validate() is non-empty',
      (t) async {
    await t.pumpWidget(host(ConfirmStepView(controller: c)));
    expect(c.draft.validate(), isNotEmpty);
    final blocked = t.widget<MyButton>(
        find.widgetWithText(MyButton, 'Send Request'));
    expect(blocked.enabled, isFalse);

    c.draft
      ..regNumber = 'LM19XYZ'
      ..categoryId = 'cat_brakes'
      ..categoryName = 'Brakes'
      ..region = Region.london
      ..partName = 'Front brake discs'
      ..condition = PartCondition.either
      ..urgency = RequestUrgency.standard;
    await t.pumpWidget(host(ConfirmStepView(controller: c)));
    final allowed = t.widget<MyButton>(
        find.widgetWithText(MyButton, 'Send Request'));
    expect(allowed.enabled, isTrue);
  });
}
