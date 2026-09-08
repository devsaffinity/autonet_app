import 'package:autonect/controller/supplier/supplier_registration_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/view/screens/supplier/registration/widgets/category_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubProfileRepository implements ProfileRepository {
  @override
  Future<ApiResult<MeProfile>> me() async => throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> registerSupplierBusiness(
    SupplierBusinessDraft draft,
  ) async => throw UnimplementedError();

  // The avatar endpoints are not exercised here; the seam requires them.
  @override
  Future<ApiResult<UploadTicket>> createAvatarUploadTicket(String contentType) =>
      throw UnimplementedError();

  @override
  Future<ApiResult<MeProfile>> setAvatar(String avatarKey) =>
      throw UnimplementedError();
}

void main() {
  late SupplierRegistrationController c;

  setUp(() {
    // Constructed directly, not through ensure(): that resolves CatalogRepository
    // out of Get, which a unit test has no reason to stand up.
    c = SupplierRegistrationController(_StubProfileRepository());
  });

  group('region', () {
    test('is null until one is picked, so the field shows its hint', () {
      expect(c.region, isNull);
      expect(c.regionsServed, isEmpty);
    });

    test('the dropdown writes a ONE-element list, never appends', () {
      // regionsServed is an array server-side; a dropdown that appended would
      // silently accumulate every region the supplier browsed past.
      c.region = Region.london;
      c.region = Region.westMidlands;
      expect(c.regionsServed, [Region.westMidlands]);
    });

    test('clearing empties the list rather than leaving a stale value', () {
      c.region = Region.london;
      c.region = null;
      expect(c.regionsServed, isEmpty);
      expect(c.region, isNull);
    });
  });

  group('addBrand', () {
    test('trims and selects', () {
      expect(c.addBrand('  Skoda  '), isTrue);
      expect(c.brands, ['Skoda']);
    });

    test('a blank entry is rejected', () {
      expect(c.addBrand('   '), isFalse);
      expect(c.brands, isEmpty);
    });

    test('matches a suggestion case-insensitively instead of duplicating', () {
      // 'audi' must select the existing Audi chip, not add a second one.
      expect(c.addBrand('audi'), isTrue);
      expect(c.brands, ['Audi']);
      expect(c.brandOptions.where((b) => b.toLowerCase() == 'audi'), hasLength(1));
    });

    test('re-adding something already selected reports false', () {
      c.addBrand('Skoda');
      expect(c.addBrand('skoda'), isFalse);
      expect(c.brands, ['Skoda']);
    });

    test('a typed brand joins the options list once, after the suggestions', () {
      c.addBrand('Skoda');
      final options = c.brandOptions;
      expect(options.where((b) => b == 'Skoda'), hasLength(1));
      expect(options.last, 'Skoda');
      expect(options.take(SupplierRegistrationController.suggestedBrands.length),
          SupplierRegistrationController.suggestedBrands);
    });
  });

  group('blockingReason', () {
    void fill() {
      c.businessName.value = 'JIN Motors';
      c.address.value = 'Jinnah Center';
      c.region = Region.london;
      c.categoryIds.add('cat-1');
    }

    test('names the first missing field, in form order', () {
      expect(c.blockingReason, 'Add your business name');
      c.businessName.value = 'JIN Motors';
      expect(c.blockingReason, 'Add your business address');
      c.address.value = 'Jinnah Center';
      expect(c.blockingReason, 'Pick at least one region you serve');
      c.region = Region.london;
      expect(c.blockingReason, 'Pick at least one part category');
    });

    test('is null once every server-required field is set', () {
      fill();
      expect(c.blockingReason, isNull);
      expect(c.canSubmit, isTrue);
    });

    test('whitespace does not satisfy a required field', () {
      fill();
      c.businessName.value = '   ';
      expect(c.blockingReason, 'Add your business name');
    });
  });

  group('CategoryGrid.iconFor', () {
    test('maps every real category the API returns', () {
      // The live list, verified against GET /v1/categories.
      const live = [
        'Body & Exterior', 'Brakes', 'Cooling', 'Electrical', 'Engine',
        'Exhaust', 'Filters', 'Interior', 'Lighting', 'Suspension & Steering',
        'Transmission', 'Wheels & Tyres',
      ];
      for (final name in live) {
        expect(CategoryGrid.iconFor(name), isNot(Icons.build_outlined),
            reason: '$name falls through to the generic glyph');
      }
    });

    test('an unmapped category degrades to a generic glyph, never null', () {
      // An admin adding a category must not render an empty cell.
      expect(CategoryGrid.iconFor('Turbochargers'), Icons.build_outlined);
    });
  });
}
