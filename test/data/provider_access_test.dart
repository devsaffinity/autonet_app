import 'package:autonect/data/models/me_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// The approval gate. An electrician used to enter the shell on a LOCAL
/// SharedPreferences flag written by the wizard itself — finishing the form
/// was self-approval, with no server check anywhere.
Map<String, dynamic> _me({
  String role = 'ELECTRICIAN',
  Map<String, dynamic>? electrician,
  Map<String, dynamic>? supplier,
}) => {
  'id': 'u1', 'email': 'p@example.com', 'role': role,
  if (electrician != null) 'electricianProfile': electrician,
  if (supplier != null) 'supplierProfile': supplier,
};

void main() {
  group('MeProfile provider access', () {
    test('an electrician profile is decoded at all', () {
      // The server has always returned this; the client never read it, which
      // is the whole reason the gate was missing.
      final me = MeProfile.fromJson(_me(electrician: {
        'fullName': 'Jack Brennan', 'approved': true, 'kycStatus': 'APPROVED',
      }));
      expect(me.electricianProfile, isNotNull);
      expect(me.electricianProfile!.fullName, 'Jack Brennan');
      expect(me.hasProviderProfile, isTrue);
      expect(me.providerApproved, isTrue);
    });

    test('registered but unapproved does NOT grant access', () {
      final me = MeProfile.fromJson(_me(electrician: {
        'fullName': 'Pending Motors', 'approved': false, 'kycStatus': 'SUBMITTED',
      }));
      // A row existing is 'onboarded'; approval is a separate admin decision.
      expect(me.hasProviderProfile, isTrue);
      expect(me.providerApproved, isFalse);
      expect(me.providerKycStatus, KycStatus.submitted);
    });

    test('an APPROVED kyc status is not a substitute for approved', () {
      // An admin can revoke approved without moving the status.
      final me = MeProfile.fromJson(_me(electrician: {
        'fullName': 'X', 'approved': false, 'kycStatus': 'APPROVED',
      }));
      expect(me.providerApproved, isFalse);
    });

    test('no profile row at all means not onboarded', () {
      final me = MeProfile.fromJson(_me());
      expect(me.hasProviderProfile, isFalse);
      expect(me.providerApproved, isNull);
    });

    test('a buyer has neither profile and is unaffected', () {
      final me = MeProfile.fromJson(_me(role: 'BUYER'));
      expect(me.hasProviderProfile, isFalse);
      expect(me.electricianProfile, isNull);
      expect(me.supplierProfile, isNull);
    });

    test('the supplier path is unchanged', () {
      final me = MeProfile.fromJson(_me(role: 'SUPPLIER', supplier: {
        'businessName': 'S', 'address': 'A', 'regionsServed': ['LONDON'],
        'brands': <String>[], 'categories': <Object>[],
        'kycStatus': 'APPROVED', 'approved': true,
      }));
      expect(me.providerApproved, isTrue);
      expect(me.hasProviderProfile, isTrue);
    });

    test('an unknown kyc status reads as not-approved, never approved', () {
      final me = MeProfile.fromJson(_me(electrician: {
        'fullName': 'X', 'approved': false, 'kycStatus': 'UNDER_APPEAL',
      }));
      expect(me.providerKycStatus, isNull);
      expect(me.providerApproved, isFalse);
    });
  });
}
