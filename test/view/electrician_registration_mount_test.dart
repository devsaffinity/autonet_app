import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/controller/electrician/electrician_registration_controller.dart';
import 'package:autonect/controller/electrician/provider_dashboard_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/provider_dashboard.dart';
import 'package:autonect/data/repositories/billing_repository.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/data/repositories/notifications_repository.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/view/screens/electrician/profile/profile.dart';
import 'package:autonect/view/screens/electrician/registration/service_provider_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../fakes/fake_billing.dart';
import '../fakes/fake_buyer_repositories.dart';

/// MOUNTING THE WIZARD AND THE PROVIDER PROFILE.
///
/// Both were rewired from literals to live controllers, and the profile went
/// from Stateless to Stateful with two `Obx` closures — the exact shape that
/// once shipped a grey screen. A controller test never builds a widget.
MeProfile _me({
  bool approved = true,
  String fullName = 'Jack Brennan',
  String? headline = 'ECU Specialist',
  double ratingAvg = 4.6,
  int ratingCount = 12,
}) => MeProfile.fromJson({
  'id': 'u1',
  'email': 'jack@test.local',
  'role': 'ELECTRICIAN',
  'name': 'Jack B',
  'electricianProfile': {
    'fullName': fullName,
    'approved': approved,
    'headline': headline,
    'ratingAvg': ratingAvg,
    'ratingCount': ratingCount,
  },
});

ProviderDashboard _dashboard({int completed = 7, int workPence = 125000}) =>
    ProviderDashboard.fromJson({
      'completedCount': completed,
      'upcomingCount': 1,
      'pendingCount': 0,
      'workCompletedPence': workPence,
      'thisMonthPence': 0,
      'averageJobPence': 20000,
      'unpricedCompletedCount': 0,
      'byServiceType': const [],
      'last7Days': const [],
      'last6Months': const [],
    });

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('registration wizard', () {
    Future<FakeProfileRepository> pump(WidgetTester tester) async {
      final repo = FakeProfileRepository();
      Get.put<ProfileRepository>(repo);
      // The Access Tier step shows server prices (read-only, nothing sold).
      Get.put<BillingRepository>(FakeBillingRepository());
      Get.put(
        ElectricianRegistrationController(
          repo,
          toast: (_) {},
          showBusy: () {},
          hideBusy: () {},
        ),
      );
      await tester.pumpWidget(
        const GetMaterialApp(home: ServiceProviderRegistrationPage()),
      );
      await tester.pump();
      return repo;
    }

    testWidgets('builds without throwing', (tester) async {
      await pump(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Basic Info'), findsWidgets);
    });

    testWidgets('is five steps matching design', (tester) async {
      await pump(tester);

      expect(find.text('Step 1 Of 5'), findsOneWidget);
    });

    testWidgets('typing a name reaches the controller', (tester) async {
      await pump(tester);
      final c = Get.find<ElectricianRegistrationController>();

      await tester.enterText(find.byType(TextField).first, 'Jack Brennan');
      await tester.pump();

      // The fields had NO controllers at all, so everything typed here was
      // discarded on the way to the next step.
      expect(c.fullName.value, 'Jack Brennan');
    });

    testWidgets('no US placeholder text survives', (tester) async {
      await pump(tester);

      // A UK-only product. These were the hints.
      expect(find.text('+1 (555) 000-0000'), findsNothing);
      expect(find.text('e.g. New York, NY'), findsNothing);
      // And the wizard's copy named a product that does not exist.
      expect(find.textContaining('AutoVolt'), findsNothing);
    });
  });

  group('provider profile', () {
    Future<void> pump(
      WidgetTester tester, {
      MeProfile? profile,
      ProviderDashboard? dashboard,
    }) async {
      final profileRepo = FakeProfileRepository()
        ..meResult = Ok(profile ?? _me());
      final bookings = FakeBookingsRepository()
        ..dashboardResult = Ok(dashboard ?? _dashboard());
      Get.put<ProfileRepository>(profileRepo);
      Get.put<BookingsRepository>(bookings);
      // The profile screen now also drives a notifications controller.
      Get.put<NotificationsRepository>(FakeNotificationsRepository());
      Get.put(
        ProfileController(profileRepo, toast: (_) {}),
      );
      Get.put(
        ProviderDashboardController(
          bookings,
          toast: (_) {},
          showBusy: () {},
          hideBusy: () {},
        ),
      );
      await tester.pumpWidget(
        const GetMaterialApp(home: ElectricianProfilePage()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('builds and shows the real provider', (tester) async {
      await pump(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Jack Brennan'), findsOneWidget);
      expect(find.text('ECU Specialist'), findsOneWidget);
      // 'Alex Chen' and 'Electrician / Coder • London' were literals.
      expect(find.text('Alex Chen'), findsNothing);
    });

    testWidgets('the verified badge follows approval', (tester) async {
      await pump(tester, profile: _me(approved: false));

      // It used to read VERIFIED PROVIDER unconditionally — including for a
      // provider still waiting on an admin.
      expect(find.text('AWAITING APPROVAL'), findsOneWidget);
      expect(find.text('VERIFIED PROVIDER'), findsNothing);
    });

    testWidgets('stats come from the server, and acceptance is gone', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('4.6'), findsWidgets); // rating
      expect(find.text('7'), findsOneWidget); // jobs done
      // Nothing records a declined booking as declined, so there was no honest
      // number behind '94% ACCEPTANCE'.
      expect(find.text('94%'), findsNothing);
      expect(find.text('ACCEPTANCE'), findsNothing);
      expect(find.text('128'), findsNothing);
    });

    testWidgets('an unrated provider shows a dash, not a zero', (tester) async {
      await pump(tester, profile: _me(ratingAvg: 0, ratingCount: 0));

      expect(tester.takeException(), isNull);
      // '0.0' reads as a bad rating, which is the opposite of the truth.
      expect(find.text('0.0'), findsNothing);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('earnings are in pounds, from the dashboard', (tester) async {
      await pump(tester);

      expect(find.text('£1,250.00'), findsOneWidget);
      // The tile carried a hardcoded '$1,240' in a GBP-only product.
      expect(find.textContaining(r'$'), findsNothing);
    });
  });
}
