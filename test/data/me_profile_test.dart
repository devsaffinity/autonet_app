import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// The supplier gate is decided by this decode. Getting it wrong does not throw
/// — it lets an unapproved supplier into a shell where every route 403s, or
/// locks an approved one out.

Map<String, dynamic> _me({Map<String, dynamic>? supplier}) => {
  'id': 'u1',
  'email': 'supplier@example.com',
  'role': 'SUPPLIER',
  'name': 'JIN Motors',
  if (supplier != null) 'supplierProfile': supplier,
};

Map<String, dynamic> _supplier({
  Object? regions = const ['LONDON', 'WALES'],
  Object? brands = const ['Audi'],
  String kycStatus = 'SUBMITTED',
  bool approved = false,
}) => {
  'businessName': 'JIN Motors',
  'address': 'Jinnah Center, Imarat',
  'regionsServed': regions,
  'brands': brands,
  'categories': [
    {'id': 'c1', 'name': 'Engine'},
  ],
  'kycStatus': kycStatus,
  'approved': approved,
};

void main() {
  group('MeProfile.fromJson', () {
    test('a buyer has no supplier profile', () {
      expect(MeProfile.fromJson(_me()).supplierProfile, isNull);
    });

    test('a supplier who never registered a business also has none', () {
      // Distinct from "registered, awaiting approval" - different screens.
      final me = MeProfile.fromJson(_me());
      expect(me.role, 'SUPPLIER');
      expect(me.supplierProfile, isNull);
    });

    test('decodes regions and brands', () {
      final p = MeProfile.fromJson(_me(supplier: _supplier())).supplierProfile!;
      expect(p.regionsServed, [Region.london, Region.wales]);
      expect(p.brands, ['Audi']);
      expect(p.categories.single.name, 'Engine');
    });

    test('an unknown region is dropped, not fatal', () {
      // A server adding a 13th region must not lock every existing supplier out
      // of the app until they update.
      final p = MeProfile.fromJson(
        _me(supplier: _supplier(regions: ['LONDON', 'ATLANTIS'])),
      ).supplierProfile!;
      expect(p.regionsServed, [Region.london]);
    });

    test('missing regions and brands decode to empty, not null', () {
      final p = MeProfile.fromJson(
        _me(supplier: _supplier(regions: null, brands: null)),
      ).supplierProfile!;
      expect(p.regionsServed, isEmpty);
      expect(p.brands, isEmpty);
    });

    test('an unknown kycStatus is null and never reads as approved', () {
      final p = MeProfile.fromJson(
        _me(supplier: _supplier(kycStatus: 'ESCALATED')),
      ).supplierProfile!;
      expect(p.kycStatus, isNull);
      expect(p.canEnterShell, isFalse);
    });
  });

  group('canEnterShell', () {
    test('follows approved, not kycStatus', () {
      // An admin can revoke approved without moving the status, so APPROVED is
      // not a substitute for the flag.
      final revoked = MeProfile.fromJson(
        _me(supplier: _supplier(kycStatus: 'APPROVED', approved: false)),
      ).supplierProfile!;
      expect(revoked.canEnterShell, isFalse);

      final live = MeProfile.fromJson(
        _me(supplier: _supplier(kycStatus: 'APPROVED', approved: true)),
      ).supplierProfile!;
      expect(live.canEnterShell, isTrue);
    });

    test('a submitted-but-unapproved supplier stays out', () {
      final p = MeProfile.fromJson(_me(supplier: _supplier())).supplierProfile!;
      expect(p.kycStatus, KycStatus.submitted);
      expect(p.canEnterShell, isFalse);
    });

    test('a missing approved key is not approved', () {
      final raw = _supplier()..remove('approved');
      final p = MeProfile.fromJson(_me(supplier: raw)).supplierProfile!;
      expect(p.canEnterShell, isFalse);
    });
  });

  group('SupplierBusinessDraft.toBody', () {
    SupplierBusinessDraft draft({
      String name = 'JIN Motors',
      String address = 'Jinnah Center',
      List<Region> regions = const [Region.london],
      List<String> categoryIds = const ['c1'],
      List<String> brands = const [],
      String? specialization,
    }) => SupplierBusinessDraft(
      businessName: name,
      address: address,
      regionsServed: regions,
      categoryIds: categoryIds,
      brands: brands,
      specialization: specialization,
    );

    test('sends regions as WIRE values, not labels', () {
      // 'West Midlands' would 400; the enum is WEST_MIDLANDS on the wire.
      final body = draft(regions: [Region.westMidlands, Region.london]).toBody();
      expect(body['regionsServed'], ['WEST_MIDLANDS', 'LONDON']);
    });

    test('OMITS specialization when null or blank, never sends an empty string',
        () {
      // The server validates it as z.string().min(1).optional(), so '' is a 400
      // where an absent key is simply "not provided".
      expect(draft().toBody().containsKey('specialization'), isFalse);
      expect(
        draft(specialization: '   ').toBody().containsKey('specialization'),
        isFalse,
      );
      expect(draft(specialization: ' Engines ').toBody()['specialization'],
          'Engines');
    });

    test('trims the free-text fields', () {
      final body = draft(name: '  JIN Motors  ', address: '  Jinnah  ').toBody();
      expect(body['businessName'], 'JIN Motors');
      expect(body['address'], 'Jinnah');
    });

    test('always sends brands, even when empty', () {
      // The column is a scalar list: "not sent" and "none selected" must land
      // on the same value.
      expect(draft().toBody()['brands'], isEmpty);
    });

    test('isComplete mirrors what the server requires', () {
      expect(draft().isComplete, isTrue);
      expect(draft(name: '  ').isComplete, isFalse);
      expect(draft(address: '').isComplete, isFalse);
      expect(draft(regions: const []).isComplete, isFalse);
      expect(draft(categoryIds: const []).isComplete, isFalse);
    });
  });
}
