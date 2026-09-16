import 'package:autonect/controller/supplier/supplier_registration_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/electrician_service.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/domain/growth_model.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/supplier/registration/widgets/category_grid.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `Obx(() => W)` subscribes ONLY to Rx values read SYNCHRONOUSLY inside its own
/// closure. A read from a child's `builder` — [StateView.builder] runs inside
/// StateView.build, a different `performRebuild` with no tracking proxy
/// installed — registers no dependency, so the subtree never repaints.
///
/// That is what made part-category selection look completely dead: tapping a
/// card updated `categoryIds` and nothing on screen changed. These tests pin the
/// SHAPE that fixes it, because the broken version looks correct in review.

class _StubProfileRepository implements ProfileRepository {
  @override
  Future<ApiResult<MeProfile>> me() async => throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> registerSupplierBusiness(
    SupplierBusinessDraft draft,
  ) async => throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> registerElectrician(
    ElectricianRegistrationDraft draft,
  ) async => me();

  @override
  Future<ApiResult<MeProfile>> updateElectricianTier(String tier) async => me();

  // The avatar endpoints are not exercised here; the seam requires them.
  @override
  Future<ApiResult<UploadTicket>> createAvatarUploadTicket(String contentType) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> setAvatar(String avatarKey) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> updateProfile({
    String? name,
    String? location,
    String? contact,
    String? avatarKey,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<List<ElectricianService>>> getElectricianServices() async =>
      const Ok([]);

  @override
  Future<ApiResult<ElectricianService>> createElectricianService({
    required String name,
    required String price,
    required String pricingType,
    String? description,
    BookingServiceType? serviceType,
  }) async => throw UnimplementedError();

  @override
  Future<ApiResult<ElectricianService>> updateElectricianService({
    required String id,
    String? name,
    String? price,
    String? pricingType,
    String? description,
    BookingServiceType? serviceType,
    bool? isActive,
  }) async => throw UnimplementedError();

  @override
  Future<ApiResult<void>> deleteElectricianService(String id) async =>
      const Ok(null);
}

final _categories = [
  PartCategory.fromJson(const {'id': 'c1', 'name': 'Engine'}),
  PartCategory.fromJson(const {'id': 'c2', 'name': 'Brakes'}),
];

/// The CORRECT shape: both Rx reads hoisted into the Obx closure.
Widget _grid(SupplierRegistrationController c) => MaterialApp(
  home: Scaffold(
    body: Obx(() {
      final selected = c.categoryIds.toSet();
      return StateView<List<PartCategory>>(
        state: Data<List<PartCategory>>(_categories),
        onRetry: () {},
        builder: (_, all) => CategoryGrid(
          categories: all,
          selectedIds: selected,
          onToggle: c.toggleCategory,
        ),
      );
    }),
  ),
);

void main() {
  late SupplierRegistrationController c;

  setUp(() {
    c = SupplierRegistrationController(_StubProfileRepository());
    Get.put<SupplierRegistrationController>(c);
  });

  tearDown(Get.reset);

  testWidgets('tapping a category repaints it as selected', (tester) async {
    await tester.pumpWidget(_grid(c));

    // Nothing selected: the card renders on the muted surface.
    expect(c.categoryIds, isEmpty);

    await tester.tap(find.bySemanticsLabel('Engine'));
    await tester.pump();

    expect(c.categoryIds, ['c1'],
        reason: 'the toggle must reach the controller');

    // The part that was broken: the SCREEN reflecting it. A card whose
    // decoration still shows the unselected surface means the Obx never saw
    // the change.
    final selectedCard = tester.widget<Container>(
      find
          .descendant(
            of: find.ancestor(
              of: find.text('Engine'),
              matching: find.byType(InkWell),
            ),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = selectedCard.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull,
        reason: 'a selected card gains an orange border');
  });

  testWidgets('tapping again deselects and repaints', (tester) async {
    await tester.pumpWidget(_grid(c));

    await tester.tap(find.bySemanticsLabel('Engine'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Engine'));
    await tester.pump();

    expect(c.categoryIds, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the selected-count line updates with the selection', (
    tester,
  ) async {
    await tester.pumpWidget(_grid(c));
    expect(find.textContaining('selected'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Engine'));
    await tester.pump();
    expect(find.text('1 category selected'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Brakes'));
    await tester.pump();
    expect(find.text('2 categories selected'), findsOneWidget);
  });

  group('growth model selection', () {
    test('starts on the recommended model, not empty', () {
      // An empty selection would make Proceed look broken until the supplier
      // tapped something they had no reason to change.
      expect(c.growthModel.value, GrowthModel.credits);
      expect(c.growthModel.value.recommended, isTrue);
    });

    test('the choice travels on the draft as a WIRE value', () {
      c.growthModel.value = GrowthModel.commission;
      expect(c.draft.monetizationModel, 'COMMISSION');
      expect(c.draft.toBody()['monetizationModel'], 'COMMISSION');
    });

    test('every model has a wire value the server accepts', () {
      // The server validates against z.enum([...]); a mismatch is a 400 on the
      // whole registration, not just a lost preference.
      const accepted = {'SUBSCRIPTION', 'CREDITS', 'COMMISSION'};
      for (final m in GrowthModel.values) {
        expect(accepted, contains(m.wire));
      }
    });
  });
}
