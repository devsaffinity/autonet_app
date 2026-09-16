import 'package:autonect/controller/electrician/manage_services_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/models/electrician_service.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../fakes/fake_buyer_repositories.dart';

void main() {
  late FakeProfileRepository repo;
  late ManageServicesController c;
  final List<String> toasts = [];

  setUp(() {
    toasts.clear();
    repo = FakeProfileRepository();
    Get.put<ProfileRepository>(repo);
    c = ManageServicesController(
      repo,
      toast: (msg) => toasts.add(msg),
      showBusy: () {},
      hideBusy: () {},
    );
  });

  tearDown(Get.reset);

  test('loadServices populates services and sets Data state', () async {
    repo.fakeServices.add(
      const ElectricianService(
        id: 'srv-1',
        electricianId: 'u1',
        name: 'ECU Remapping',
        price: '£349',
        pricingType: 'Fixed Price',
        serviceType: BookingServiceType.ecuCoding,
      ),
    );

    await c.loadServices();

    expect(c.services.length, 1);
    expect(c.services.first.name, 'ECU Remapping');
    expect(c.state.value, isA<Data<List<ElectricianService>>>());
  });

  test('loadServices sets Empty state when repository returns empty list', () async {
    repo.fakeServices.clear();

    await c.loadServices();

    expect(c.services, isEmpty);
    expect(c.state.value, isA<Empty<List<ElectricianService>>>());
  });

  test('addService validates empty name and price', () async {
    final ok1 = await c.addService(
      name: '',
      price: '£100',
      pricingType: 'Fixed Price',
    );
    expect(ok1, isFalse);
    expect(toasts.last, contains('service name'));

    final ok2 = await c.addService(
      name: 'Diagnostic',
      price: '',
      pricingType: 'Per Session',
    );
    expect(ok2, isFalse);
    expect(toasts.last, contains('price'));
  });

  test('addService successfully adds new service to inventory', () async {
    final success = await c.addService(
      name: 'Key Programming',
      price: '£150',
      pricingType: 'Fixed Price',
      description: 'Spare key cutting and transponder sync',
    );

    expect(success, isTrue);
    expect(c.services.length, 1);
    expect(c.services.first.name, 'Key Programming');
    expect(c.services.first.price, '£150');
    expect(toasts.last, contains('added to active inventory'));
  });

  test('updateService modifies existing service in inventory', () async {
    await c.addService(
      name: 'Wiring Repair',
      price: '£100/hr',
      pricingType: 'Hourly Rate',
    );

    final serviceId = c.services.first.id;

    final updated = await c.updateService(
      id: serviceId,
      name: 'Custom Wiring Repair',
      price: '£120/hr',
      pricingType: 'Hourly Rate',
      description: 'Loom fixes and fuse testing',
    );

    expect(updated, isTrue);
    expect(c.services.first.name, 'Custom Wiring Repair');
    expect(c.services.first.price, '£120/hr');
    expect(toasts.last, contains('updated successfully'));
  });

  test('deleteService removes service from inventory', () async {
    await c.addService(
      name: 'Old Service',
      price: '£50',
      pricingType: 'Fixed Price',
    );

    final serviceId = c.services.first.id;
    expect(c.services.length, 1);

    final deleted = await c.deleteService(serviceId);

    expect(deleted, isTrue);
    expect(c.services, isEmpty);
    expect(c.state.value, isA<Empty<List<ElectricianService>>>());
    expect(toasts.last, contains('removed from inventory'));
  });
}
