import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/domain/vehicle_catalog.dart';
import 'package:autonect/services/session_store.dart';
import 'package:autonect/view/screens/buyer/new_part_request/steps/vehicle_step_view.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/vehicle_dropdown_field.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_buyer_repositories.dart';
import '../fakes/fake_image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NewRequestController c;
  late TextEditingController reg, make, model, year;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
    Get.reset();
    Get.put<CatalogController>(
      CatalogController(
        FakeCatalogRepository()
          ..result = const Ok([PartCategory(id: 'cat_brakes', name: 'Brakes')]),
        toast: (_) {},
        showBusy: () {},
        hideBusy: () {},
      ),
      permanent: true,
    );
    c = NewRequestController(
      requests: FakeRequestsRepository(),
      vehicles: FakeVehiclesRepository(),
      uploader: FakeBlobUploader(),
      picker: FakeImagePickerService(),
      tokens: InMemoryTokenStore(),
      toast: (_) {},
      showBusy: () {},
      hideBusy: () {},
    );
    reg = TextEditingController();
    make = TextEditingController();
    model = TextEditingController();
    year = TextEditingController();
  });

  tearDown(() {
    c.saveNow();
    reg.dispose();
    make.dispose();
    model.dispose();
    year.dispose();
    Get.reset();
  });

  Widget host(Widget child) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 1200,
            child: child,
          ),
        ),
      );

  Future<void> pumpStep1(WidgetTester t) async {
    await t.pumpWidget(
      host(
        VehicleStepView(
          controller: c,
          reg: reg,
          make: make,
          model: model,
          year: year,
          onNext: () {},
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('step 1 renders Custom Vehicle Specifications and removes mode tabs',
      (t) async {
    await pumpStep1(t);

    // Custom Vehicle Specifications header is present
    expect(find.text('Custom Vehicle Specifications'), findsOneWidget);
    expect(
      find.text(
          'Select or enter your vehicle specifications below to help suppliers match the exact parts.'),
      findsOneWidget,
    );

    // Top mode selector tabs are removed
    expect(find.text('Plate / DVLA Lookup'), findsNothing);
    expect(find.text('Custom Vehicle Entry'), findsNothing);

    // Fields are present
    expect(find.text('Registration number'), findsOneWidget);
    expect(find.text('Make'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('Fuel Type'), findsOneWidget);
    expect(find.text('Colour'), findsOneWidget);

    c.saveNow();
    await t.pump(const Duration(milliseconds: 600));
  });

  testWidgets('selecting a popular make populates model dropdown', (t) async {
    await pumpStep1(t);

    // Tap Make dropdown
    final makeDropdown = find.widgetWithText(VehicleDropdownField, 'Make');
    expect(makeDropdown, findsOneWidget);

    final dropdownBtn = find.descendant(
      of: makeDropdown,
      matching: find.byType(DropdownButton2<String>),
    );
    await t.ensureVisible(dropdownBtn);
    await t.pumpAndSettle();
    await t.tap(dropdownBtn);
    await t.pumpAndSettle();

    // Select "Audi" (top of list)
    await t.tap(find.text('Audi').last);
    await t.pumpAndSettle();

    expect(make.text, 'Audi');
    expect(c.draft.vehicleMake, 'Audi');

    // Model dropdown is now active with Audi models
    final modelDropdown = find.widgetWithText(VehicleDropdownField, 'Model');
    expect(modelDropdown, findsOneWidget);

    final modelBtn = find.descendant(
      of: modelDropdown,
      matching: find.byType(DropdownButton2<String>),
    );
    await t.ensureVisible(modelBtn);
    await t.pumpAndSettle();
    await t.tap(modelBtn);
    await t.pumpAndSettle();

    // "A4" should be an option for Audi
    expect(find.text('A4'), findsWidgets);
    await t.tap(find.text('A4').last);
    await t.pumpAndSettle();

    expect(model.text, 'A4');
    expect(c.draft.vehicleModel, 'A4');

    c.saveNow();
    await t.pump(const Duration(milliseconds: 600));
  });

  testWidgets('selecting Other in Make displays custom make field and allows entry',
      (t) async {
    await pumpStep1(t);

    expect(find.text('Custom Make'), findsNothing);

    // Tap Make dropdown
    final makeDropdown = find.widgetWithText(VehicleDropdownField, 'Make');
    final dropdownBtn = find.descendant(
      of: makeDropdown,
      matching: find.byType(DropdownButton2<String>),
    );
    await t.ensureVisible(dropdownBtn);
    await t.pumpAndSettle();
    await t.tap(dropdownBtn);
    await t.pumpAndSettle();

    // Scroll until 'Other' is visible in the dropdown list
    final otherFinder = find.text(VehicleCatalog.otherOption);
    final scrollable = find.byType(Scrollable).last;
    await t.scrollUntilVisible(otherFinder, 100, scrollable: scrollable);
    await t.pumpAndSettle();

    await t.tap(otherFinder.last);
    await t.pumpAndSettle();

    // Now Custom Make field appears
    expect(find.text('Custom Make'), findsOneWidget);

    // Enter custom make in the custom make text field
    final customMakeField = find.widgetWithText(MyTextField, 'Custom Make');
    expect(customMakeField, findsOneWidget);
    await t.enterText(customMakeField, 'Bentley');
    await t.pump();

    expect(make.text, 'Bentley');
    expect(c.draft.vehicleMake, 'Bentley');

    c.saveNow();
    await t.pump(const Duration(milliseconds: 600));
  });

  testWidgets('selecting Other in Fuel Type displays custom fuel field',
      (t) async {
    await pumpStep1(t);

    expect(find.text('Custom Fuel Type'), findsNothing);

    final fuelDropdown = find.widgetWithText(VehicleDropdownField, 'Fuel Type');
    expect(fuelDropdown, findsOneWidget);

    final fuelBtn = find.descendant(
      of: fuelDropdown,
      matching: find.byType(DropdownButton2<String>),
    );
    await t.ensureVisible(fuelBtn);
    await t.pumpAndSettle();
    await t.tap(fuelBtn);
    await t.pumpAndSettle();

    final otherFinder = find.text(VehicleCatalog.otherOption);
    final scrollable = find.byType(Scrollable).last;
    await t.scrollUntilVisible(otherFinder, 100, scrollable: scrollable);
    await t.pumpAndSettle();

    await t.tap(otherFinder.last);
    await t.pumpAndSettle();

    expect(find.text('Custom Fuel Type'), findsOneWidget);

    c.saveNow();
    await t.pump(const Duration(milliseconds: 600));
  });
}
