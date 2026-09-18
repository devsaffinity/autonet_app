import 'package:autonect/controller/supplier/supplier_leads_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/supplier_lead.dart';
import 'package:autonect/data/repositories/supplier_repository.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_lead_card.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_leads.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeSupplierRepo implements SupplierRepository {
  bool returnEmpty = false;
  bool returnError = false;

  @override
  Future<ApiResult<Paged<SupplierLead>>> feed({
    int page = 1,
    int limit = 20,
    String? partName,
    Region? region,
    PartCondition? condition,
    RequestUrgency? urgency,
    String? make,
    String? model,
    int? minOffers,
    int? maxOffers,
    String? sort,
  }) async {
    if (returnError) {
      return const Err(ApiError(code: ApiErrorCode.internal, statusCode: 500, message: 'Server down'));
    }
    return Ok(
      Paged(
        returnEmpty
            ? []
            : [
                SupplierLead(
                  id: 'lead_1',
                  partName: 'Dual-Clutch Transmission Assembly',
                  offerCount: 3,
                  createdAt: DateTime.now(),
                  vehicleMake: 'BMW',
                  vehicleYear: 2021,
                  region: Region.london,
                  urgency: RequestUrgency.urgent,
                ),
              ],
        PageMeta(
          page: 1,
          limit: 20,
          pageSize: returnEmpty ? 0 : 1,
          total: returnEmpty ? 0 : 1,
          totalPages: returnEmpty ? 0 : 1,
          hasNextPage: false,
          hasPreviousPage: false,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<SupplierDashboardData>> dashboard() =>
      throw UnimplementedError();

  @override
  Future<ApiResult<SupplierLeadDetail>> leadDetail(String id) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<SupplierOffer>> createOffer({
    required String requestId,
    required int pricePence,
    required PartCondition condition,
    int? warrantyMonths,
    required DeliveryOption deliveryOption,
    int? deliveryTimeDays,
    required StockStatus stockStatus,
    required int quantity,
    String? notes,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<Paged<SupplierOffer>>> listOffers({
    int page = 1,
    int limit = 20,
    OfferStatus? status,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<SupplierOffer>> editOffer({
    required String offerId,
    int? pricePence,
    PartCondition? condition,
    int? warrantyMonths,
    DeliveryOption? deliveryOption,
    int? deliveryTimeDays,
    StockStatus? stockStatus,
    int? quantity,
    String? notes,
  }) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<SupplierOffer>> withdrawOffer(String offerId) =>
      throw UnimplementedError();
}

void main() {
  late _FakeSupplierRepo repo;

  setUp(() {
    Get.reset();
    repo = _FakeSupplierRepo();
    Get.put<SupplierRepository>(repo);
    Get.put<SupplierLeadsController>(SupplierLeadsController(repo));
  });

  tearDown(() => Get.reset());

  testWidgets('SupplierLeadsPage mounts and renders filter chips and leads matching Figma',
      (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierLeadsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Incoming Leads'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('London'), findsOneWidget);
    expect(find.text('Dual-Clutch Transmission Assembly'), findsOneWidget);
    expect(find.text('2021 BMW'), findsOneWidget);
    expect(find.text('3 Offers'), findsOneWidget);
    expect(find.text('Send Quote'), findsOneWidget);
    expect(find.byType(SupplierLeadCard), findsOneWidget);
  });

  testWidgets('Toggling filters updates active filter state', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierLeadsPage(),
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<SupplierLeadsController>();
    expect(controller.activeFilterLabels, isEmpty);

    // Tap London filter chip
    await tester.tap(find.text('London'));
    await tester.pumpAndSettle();

    expect(controller.activeFilterLabels, contains('London'));
    expect(controller.regionFilter.value, Region.london);

    // Tap All to reset
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(controller.activeFilterLabels, isEmpty);
    expect(controller.regionFilter.value, isNull);
  });

  testWidgets('SupplierLeadsPage displays clean empty state when no leads match',
      (tester) async {
    repo.returnEmpty = true;

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierLeadsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No matching leads'), findsOneWidget);
    expect(find.text('Try adjusting your search or filters.'), findsOneWidget);
  });

  testWidgets('SupplierLeadsPage displays error state with retry on failure',
      (tester) async {
    repo.returnError = true;

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SupplierLeadsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load leads'), findsOneWidget);
    expect(find.text('Server down'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Recover on retry
    repo.returnError = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Dual-Clutch Transmission Assembly'), findsOneWidget);
  });
}
