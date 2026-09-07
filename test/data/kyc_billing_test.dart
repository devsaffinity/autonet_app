import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/kyc_status.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _state({
  List<Object?> required = const ['ID', 'BUSINESS_REGISTRY', 'TAX'],
  List<Object?> documents = const [],
  String kycStatus = 'PENDING',
}) => {
  'kycStatus': kycStatus,
  'approved': false,
  'requiredDocuments': required,
  'documents': documents,
};

Map<String, dynamic> _doc(
  String type, {
  bool uploaded = true,
  String? fileName,
  int? sizeBytes,
}) => {
  'type': type,
  'uploaded': uploaded,
  'fileName': fileName,
  'sizeBytes': sizeBytes,
};

void main() {
  group('KycState', () {
    test('isComplete needs every REQUIRED document, not just some', () {
      final partial = KycState.fromJson(
        _state(documents: [_doc('ID'), _doc('TAX')]),
      );
      expect(partial.isComplete, isFalse);

      final whole = KycState.fromJson(
        _state(documents: [_doc('ID'), _doc('BUSINESS_REGISTRY'), _doc('TAX')]),
      );
      expect(whole.isComplete, isTrue);
    });

    test('a document present but not uploaded does not count', () {
      // A ticket is issued before the bytes land, so the row exists first.
      final s = KycState.fromJson(
        _state(
          documents: [
            _doc('ID'),
            _doc('BUSINESS_REGISTRY'),
            _doc('TAX', uploaded: false),
          ],
        ),
      );
      expect(s.isComplete, isFalse);
      expect(s.hasUploaded(KycDocType.tax), isFalse);
    });

    test('an unknown document type is dropped, not fatal', () {
      // A server adding a fourth type must not break the screen on an old build.
      final s = KycState.fromJson(
        _state(documents: [_doc('ID'), _doc('PASSPORT_SCAN')]),
      );
      expect(s.documents, hasLength(1));
      expect(s.documents.single.type, KycDocType.id);
    });

    test('an unknown kycStatus is null and never reads as approved', () {
      final s = KycState.fromJson(_state(kycStatus: 'ESCALATED'));
      expect(s.kycStatus, isNull);
      expect(s.approved, isFalse);
    });

    test('missing lists decode to empty rather than throwing', () {
      final s = KycState.fromJson({'kycStatus': 'PENDING', 'approved': false});
      expect(s.requiredDocuments, isEmpty);
      expect(s.documents, isEmpty);
      // Vacuously true, but the step also gates on the list being non-empty.
      expect(s.isComplete, isTrue);
    });
  });

  group('KycDocument.displaySize', () {
    KycDocument doc(int? bytes) =>
        KycDocument.tryFromJson(_doc('ID', sizeBytes: bytes))!;

    test('formats bytes, KB and MB', () {
      expect(doc(512).displaySize, '512 B');
      expect(doc(2048).displaySize, '2 KB');
      expect(doc(2516582).displaySize, '2.4 MB');
    });

    test('is null when the server recorded no size', () {
      // Documents predating the metadata columns; the row must still render.
      expect(doc(null).displaySize, isNull);
    });
  });

  group('BillingPlan', () {
    BillingPlan plan({
      String name = '10 Credit Pack',
      int pricePence = 1000,
      String interval = 'ONE_TIME',
      int? credits = 10,
    }) => BillingPlan.fromJson({
      'id': 'p1',
      'lookupKey': 'credits-10',
      'name': name,
      'pricePence': pricePence,
      'interval': interval,
      'credits': credits,
    });

    test('formats a subscription price with its interval suffix', () {
      final p = plan(pricePence: 29900, interval: 'MONTH', credits: null);
      expect(p.displayPrice, '£299.00/mo');
      expect(p.isCreditPack, isFalse);
    });

    test('a credit pack has no interval suffix', () {
      expect(plan().displayPrice, '£10.00');
      expect(plan().isCreditPack, isTrue);
    });

    test('per-credit price divides the pack, it is NOT the pack price', () {
      // credits-10 is £10.00 for TEN credits, so a lead costs £1.00. Showing
      // the pack price per lead would overstate it tenfold.
      expect(plan().displayPerCredit, '£1.00 per credit');
    });

    test('a subscription has no per-credit price', () {
      expect(plan(credits: null).displayPerCredit, isNull);
      expect(plan(credits: 0).displayPerCredit, isNull);
    });

    test('an unknown interval leaves the price unsuffixed rather than wrong',
        () {
      final p = plan(interval: 'FORTNIGHT', credits: null);
      expect(p.interval, isNull);
      expect(p.displayPrice, '£10.00');
    });
  });
}
