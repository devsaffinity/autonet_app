import 'package:autonect/controller/buyer/catalog_controller.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/services/session_store.dart';
import 'package:autonect/view/screens/buyer/new_part_request/steps/part_details_step_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_buyer_repositories.dart';
import '../fakes/fake_image_picker.dart';

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
          ..result = const Ok([
            PartCategory(id: 'cat_body', name: 'Body & Exterior'),
            PartCategory(id: 'cat_lighting', name: 'Lighting'),
            PartCategory(id: 'cat_suspension', name: 'Suspension & Steering'),
          ]),
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

  testWidgets(
      'PartDetailsStepView guides user on breaker yard parts and warns on consumable wear items',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: PartDetailsStepView(
            controller: c,
            partName: partName,
            partNumber: partNumber,
            description: description,
            onNext: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Breaker yard guidance banner is present
    expect(
      find.textContaining('Autonect connects you with verified breaker yards'),
      findsOneWidget,
    );

    // 2. Realistic hint text is shown in Part Name field
    expect(
      find.text('e.g. Nearside Headlight, Front Door, Suspension Strut'),
      findsOneWidget,
    );

    // 3. Notice is NOT shown initially
    expect(
      find.textContaining('Notice: Breaker yards typically supply reclaimed OEM parts'),
      findsNothing,
    );

    // 4. Enter a realistic breaker yard part: no warning shown
    await tester.enterText(
      find.widgetWithText(TextFormField, 'e.g. Nearside Headlight, Front Door, Suspension Strut'),
      'Nearside Headlight assembly',
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Notice: Breaker yards typically supply reclaimed OEM parts'),
      findsNothing,
    );

    // 5. Enter a consumable wear item ("brake pads")
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nearside Headlight assembly'),
      'Front brake pads',
    );
    await tester.pumpAndSettle();

    // Notice appears!
    expect(
      find.textContaining('Notice: Breaker yards typically supply reclaimed OEM parts'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 600));
  });
}
