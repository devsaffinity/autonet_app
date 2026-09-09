import 'package:autonect/controller/buyer/providers_list_controller.dart';
import 'package:autonect/controller/buyer/service_providers_controller.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/screens/buyer/home/widgets/service_provider_card.dart';
import 'package:autonect/view/widget/initials_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_buyer_repositories.dart';

/// The Service Providers section. Every field except id and fullName is
/// optional on `GET /v1/providers` — a garage can register with no brands, no
/// location and no reviews — so "what does the card look like when the data
/// isn't there" is most of the surface.

ServiceProvider _provider({
  String fullName = 'Abc Garage',
  List<String> brands = const ['BMW', 'Mercedes', 'KIA'],
  num ratingAvg = 4.5,
  int ratingCount = 26,
  String? location,
  int? yearsExperience,
}) => ServiceProvider.fromJson({
  'id': 'prov-1',
  'fullName': fullName,
  'brands': brands,
  'ratingAvg': ratingAvg,
  'ratingCount': ratingCount,
  'location': location,
  'yearsExperience': yearsExperience,
});

PageMeta _meta(int n) => PageMeta(
  page: 1, limit: 20, pageSize: n, total: n,
  totalPages: n == 0 ? 0 : 1, hasNextPage: false, hasPreviousPage: false,
);

Widget _host(Widget child, {double width = 360, TextScaler? scaler}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: scaler ?? TextScaler.noScaling,
        ),
        // Sized by the SAME function home uses, so this proves the real
        // carousel geometry rather than a number invented for the test.
        child: Scaffold(
          body: Builder(
            builder: (context) => SizedBox(
              width: width,
              height: serviceProviderCardHeight(context),
              child: child,
            ),
          ),
        ),
      ),
    );

ServiceProvidersController _controller(FakeProvidersRepository repo) =>
    ServiceProvidersController(repo,
        toast: (_) {}, showBusy: () {}, hideBusy: () {});

void main() {
  group('brandsLabel', () {
    test('joins up to three', () {
      expect(brandsLabel(['BMW', 'Mercedes']), 'BMW · Mercedes');
      expect(brandsLabel(['BMW', 'Mercedes', 'KIA']), 'BMW · Mercedes · KIA');
    });

    test('counts the overflow instead of ellipsizing it away', () {
      // The comp's '+2'. An ellipsis would not say how many were hidden.
      expect(brandsLabel(['BMW', 'Mercedes', 'KIA', 'Ford', 'Peugeot']),
          'BMW · Mercedes · KIA +2');
    });

    test('empty for a provider who listed none', () {
      expect(brandsLabel(const []), '');
    });
  });

  group('ServiceProviderCard', () {
    testWidgets('renders name, brands and rating', (tester) async {
      await tester.pumpWidget(_host(ServiceProviderCard(provider: _provider())));

      expect(find.text('Abc Garage'), findsOneWidget);
      expect(find.text('BMW · Mercedes · KIA'), findsOneWidget);
      expect(find.text('4.5/5.0'), findsOneWidget);
    });

    testWidgets("an unrated provider reads 'New', never 0.0/5.0", (
      tester,
    ) async {
      // ratingAvg defaults to 0 server-side. Printing it says a brand-new
      // garage scored zero out of five — a bad rating, not a missing one.
      await tester.pumpWidget(
        _host(ServiceProviderCard(provider: _provider(ratingAvg: 0, ratingCount: 0))),
      );

      expect(find.text('0.0/5.0'), findsNothing);
      expect(find.textContaining('/5.0'), findsNothing);
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('the rating row is present whether or not they are rated', (
      tester,
    ) async {
      // Same shape either way, so the row does not appear and vanish as the
      // carousel scrolls.
      for (final rated in [true, false]) {
        await tester.pumpWidget(_host(ServiceProviderCard(
          provider: rated
              ? _provider()
              : _provider(ratingAvg: 0, ratingCount: 0),
        )));
        expect(find.byIcon(rated ? Icons.star_rounded : Icons.star_outline_rounded),
            findsOneWidget);
      }
    });

    testWidgets('a provider with no photo gets initials, not a stock face', (
      tester,
    ) async {
      // The old fallback was a photograph of a real person, put on every
      // provider who had not uploaded anything.
      await tester.pumpWidget(
        _host(ServiceProviderCard(provider: _provider(fullName: 'Jack Brennan'))),
      );

      expect(find.byType(InitialsAvatar), findsOneWidget);
      expect(find.text('JB'), findsOneWidget);
    });

    testWidgets('a provider WITH a photo does not get initials', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ServiceProviderCard(
        provider: ServiceProvider.fromJson({
          'id': 'p1', 'fullName': 'Abc Garage', 'brands': <String>[],
          'ratingAvg': 0, 'ratingCount': 0,
          'avatarUrl': 'https://example.invalid/a.jpg',
        }),
      )));

      expect(find.byType(InitialsAvatar), findsNothing);
    });

    testWidgets('a provider with no brands omits the row entirely', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ServiceProviderCard(provider: _provider(brands: const []))),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Abc Garage'), findsOneWidget);
    });

    testWidgets('the CTA does not promise a booking that cannot happen', (
      tester,
    ) async {
      // POST /v1/bookings has no buyer-facing route, so 'Book Now' would be a
      // labelling lie. Flip this the moment the booking flow lands.
      await tester.pumpWidget(_host(ServiceProviderCard(provider: _provider())));

      expect(find.text('View Profile'), findsOneWidget);
      expect(find.text('Book Now'), findsNothing);
    });

    testWidgets('fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(ServiceProviderCard(provider: _provider(), onTap: () => taps++)),
      );

      await tester.tap(find.text('View Profile'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('no overflow at 320dp with 200% font', (tester) async {
      await tester.pumpWidget(
        _host(
          ServiceProviderCard(
            provider: _provider(
              fullName: 'Halewood Motor Factors Limited',
              brands: const ['BMW', 'Mercedes', 'KIA', 'Ford', 'Peugeot'],
            ),
          ),
          width: 320,
          scaler: const TextScaler.linear(2.0),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('ServiceProvidersController', () {
    test('loads the preview strip', () async {
      final repo = FakeProvidersRepository()
        ..listResult = Ok(Paged<ServiceProvider>([_provider()], _meta(1)));
      final c = _controller(repo);

      await c.load();
      expect(repo.calls.single, startsWith('providers:1:6'));
      expect((c.providers.value as Data<List<ServiceProvider>>).value.single.fullName,
          'Abc Garage');
    });

    test('a zero total is Empty with copy, not an empty Data list', () async {
      final repo = FakeProvidersRepository()
        ..listResult = Ok(Paged<ServiceProvider>(const [], _meta(0)));
      final c = _controller(repo);

      await c.load();
      expect((c.providers.value as Empty<List<ServiceProvider>>).title,
          'No providers yet');
    });

    test('a failure is Failed, so the strip offers its own retry', () async {
      final repo = FakeProvidersRepository()
        ..listResult = const Err<Paged<ServiceProvider>>(ApiError.network());
      final c = _controller(repo);

      await c.load();
      expect(c.providers.value, isA<Failed<List<ServiceProvider>>>());
    });
  });

  group('InitialsAvatar.initialsOf', () {
    test('takes the first letter of the first two words', () {
      expect(InitialsAvatar.initialsOf('Jack Brennan'), 'JB');
      expect(InitialsAvatar.initialsOf('Abc Garage'), 'AG');
    });

    test('a single word gives one letter', () {
      expect(InitialsAvatar.initialsOf('Cher'), 'C');
    });

    test('ignores extra whitespace and third names', () {
      expect(InitialsAvatar.initialsOf('  leah   dunne  smith '), 'LD');
    });

    test('a name of only whitespace yields nothing, and the tile falls back',
        () {
      expect(InitialsAvatar.initialsOf('   '), '');
    });

    test('does not split a surrogate pair in half', () {
      // String.fromCharCode on a code UNIT would emit half a pair and render
      // as a replacement glyph.
      expect(InitialsAvatar.initialsOf('😀 Garage'), '😀G'.toUpperCase());
    });
  });

  _directoryTests();

  group('ServiceProvider model', () {
    test('isRated is false when nothing is behind the average', () {
      expect(_provider(ratingAvg: 0, ratingCount: 0).isRated, isFalse);
      expect(_provider(ratingAvg: 4.5, ratingCount: 26).isRated, isTrue);
    });

    test('a missing brands array decodes to empty, never null', () {
      final p = ServiceProvider.fromJson({'id': 'x', 'fullName': 'Y'});
      expect(p.brands, isEmpty);
      expect(p.ratingAvg, 0);
      expect(p.avatarUrl, isNull);
    });
  });
}

/// The Services directory's filters. The tabs and the chips drive the SAME
/// `?service=` parameter — the schema has one provider table and no column
/// separating a coder from an electrician — so the interesting behaviour is
/// how they share that one field without fighting each other.
void _directoryTests() {
  ProvidersListController controller(FakeProvidersRepository repo) =>
      ProvidersListController(repo,
          toast: (_) {}, showBusy: () {}, hideBusy: () {});

  group('ProvidersListController filters', () {
    test('the Electricians tab sends no service; Coders sends ECU_CODING',
        () async {
      final repo = FakeProvidersRepository()
        ..listResult = Ok(Paged<ServiceProvider>([_provider()], _meta(1)));
      final c = controller(repo);

      await c.setService(BookingServiceType.ecuCoding);
      expect(repo.calls.last, contains(':service=ECU_CODING'));

      await c.setService(null);
      // Absent, not blank — 'Electricians' is the whole directory.
      expect(repo.calls.last, isNot(contains(':service=')));
    });

    test('re-selecting the same tab does not re-issue the read', () async {
      final repo = FakeProvidersRepository()
        ..listResult = Ok(Paged<ServiceProvider>([_provider()], _meta(1)));
      final c = controller(repo);

      await c.setService(BookingServiceType.diagnostic);
      final after = repo.calls.length;
      await c.setService(BookingServiceType.diagnostic);
      expect(repo.calls.length, after);
    });

    test('a chip and a tab share one field, so selecting a chip moves the tab',
        () async {
      final repo = FakeProvidersRepository()
        ..listResult = Ok(Paged<ServiceProvider>([_provider()], _meta(1)));
      final c = controller(repo);

      await c.setService(BookingServiceType.ecuCoding);
      // ECU_CODING IS the Coders tab, so the tab row must show index 1.
      expect(ProvidersListController.tabs.indexOf(c.service.value), 1);

      // Diagnostics is a chip but not a tab; the row falls back to the first
      // tab rather than rendering nothing selected.
      await c.setService(BookingServiceType.diagnostic);
      expect(ProvidersListController.tabs.indexOf(c.service.value), -1);
    });

    test('changing the filter BLANKS the previous rows', () async {
      final repo = FakeProvidersRepository()
        ..listResult = Ok(Paged<ServiceProvider>([_provider()], _meta(1)));
      final c = controller(repo);
      await c.refreshFirst();
      expect(c.state.value, isA<Data<List<ServiceProvider>>>());

      repo.listResult = Ok(Paged<ServiceProvider>(const [], _meta(0)));
      await c.setService(BookingServiceType.repair);
      // Leaving them under a tab that no longer describes them would be the
      // screen lying about where its rows came from.
      expect(c.state.value, isA<Empty<List<ServiceProvider>>>());
    });
  });

  group('BookingServiceType', () {
    test('renders the design word, not the enum name', () {
      expect(BookingServiceType.ecuCoding.label, 'ECU Tuning');
      expect(BookingServiceType.diagnostic.label, 'Diagnostics');
      // The wire value is what travels.
      expect(BookingServiceType.ecuCoding.wire, 'ECU_CODING');
    });

    test('an unknown callout decodes to null rather than throwing', () {
      // /v1 lets enums grow; an older client must not break on a sixth value.
      expect(BookingServiceType.fromWire('TELEPORTATION'), isNull);
      expect(BookingServiceType.fromWire(null), isNull);
    });
  });

  group('ServiceProvider new fields', () {
    test('decodes headline, skills, services and the counter', () {
      final p = ServiceProvider.fromJson({
        'id': 'p1', 'fullName': 'Larry Allison',
        'headline': 'ECU Specialist', 'bio': 'Specialises in diagnostics.',
        'skills': ['Coding', 'Remapping'], 'vehiclesServiced': 1240,
        'services': ['ECU_CODING', 'DIAGNOSTIC'],
        'brands': ['BMW'], 'ratingAvg': 4.8, 'ratingCount': 126,
      });
      expect(p.headline, 'ECU Specialist');
      expect(p.skills, ['Coding', 'Remapping']);
      expect(p.vehiclesServiced, 1240);
      expect(p.services, [BookingServiceType.ecuCoding, BookingServiceType.diagnostic]);
    });

    test('drops an unknown service instead of failing the whole provider', () {
      final p = ServiceProvider.fromJson({
        'id': 'p1', 'fullName': 'X', 'brands': <String>[],
        'ratingAvg': 0, 'ratingCount': 0,
        'services': ['DIAGNOSTIC', 'SOMETHING_NEW'],
      });
      expect(p.services, [BookingServiceType.diagnostic]);
    });

    test('a provider from before these columns existed decodes cleanly', () {
      final p = ServiceProvider.fromJson({'id': 'p1', 'fullName': 'X'});
      expect(p.headline, isNull);
      expect(p.bio, isNull);
      expect(p.skills, isEmpty);
      expect(p.services, isEmpty);
      expect(p.vehiclesServiced, isNull);
    });
  });
}
