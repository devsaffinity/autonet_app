import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/offer_actionability.dart';
import 'package:flutter_test/flutter_test.dart';

Offer _offer(OfferStatus? status) => Offer(
  id: 'off_1',
  requestId: 'req_1',
  supplierId: 'sup_1',
  pricePence: 12999,
  quantity: 1,
  status: status,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 1),
  supplier: const OfferSupplier(id: 'sup_1'),
);

/// Built through fromJson so the wire strings — and the null both enums answer
/// for a member this build does not know — are exercised, not bypassed.
PartRequest _requestFromWire(String? wire) => PartRequest.fromJson({
  'id': 'req_1', 'buyerId': 'usr_buyer', 'regNumber': 'LM19XYZ',
  'categoryId': 'cat_brakes', 'partName': 'Front brake discs',
  'status': wire, 'offerCount': 1,
  'createdAt': '2026-09-01T10:15:00.000Z',
  'updatedAt': '2026-09-01T10:15:00.000Z',
  'category': {'id': 'cat_brakes', 'name': 'Brakes'},
  'images': <Object?>[],
});

PartRequest _request(RequestStatus? status) => _requestFromWire(status?.wire);

void main() {
  // The only two offer states that are not provably dead.
  const liveOffer = <OfferStatus?>[OfferStatus.pending, null];

  group('canAcceptOffer', () {
    test('every OfferStatus x every RequestStatus, plus both nulls', () {
      for (final os in <OfferStatus?>[...OfferStatus.values, null]) {
        for (final rs in <RequestStatus?>[...RequestStatus.values, null]) {
          expect(
            canAcceptOffer(_offer(os), _request(rs)),
            liveOffer.contains(os) && rs == RequestStatus.open,
            reason: 'offer ${os?.wire} on request ${rs?.wire}',
          );
        }
      }
    });

    test('PENDING on OPEN is the one accepting combination', () {
      expect(
        canAcceptOffer(_offer(OfferStatus.pending), _request(RequestStatus.open)),
        isTrue,
      );
    });

    test('ACCEPTED, REJECTED and WITHDRAWN block on an OPEN request', () {
      for (final os in const [
        OfferStatus.accepted,
        OfferStatus.rejected,
        OfferStatus.withdrawn,
      ]) {
        expect(canAcceptOffer(_offer(os), _request(RequestStatus.open)), isFalse,
            reason: os.wire);
      }
    });

    test('CLOSED and CANCELLED block offers that are still PENDING', () {
      // closeOrCancel (requests.service.ts:98-106) moves only the request, so
      // this is the exact shape a cancelled request's offers arrive in.
      for (final rs in const [RequestStatus.closed, RequestStatus.cancelled]) {
        expect(
          canAcceptOffer(_offer(OfferStatus.pending), _request(rs)),
          isFalse,
          reason: rs.wire,
        );
      }
    });

    test('an UNRECOGNISED offer status does NOT block', () {
      // fromWire answers null only for a member this build does not know.
      // Hiding a possibly-live offer costs a real purchase; the 409 does not.
      final unknown = Offer.fromJson({
        'id': 'off_1', 'requestId': 'req_1', 'supplierId': 'sup_1',
        'pricePence': 12999, 'quantity': 1, 'status': 'EXPIRED',
        'createdAt': '2026-09-01T10:15:00.000Z',
        'updatedAt': '2026-09-01T10:15:00.000Z',
        'supplier': {'id': 'sup_1'},
      });
      expect(unknown.status, isNull);
      expect(canAcceptOffer(unknown, _request(RequestStatus.open)), isTrue);
      expect(unacceptableReason(unknown, _request(RequestStatus.open)), isNull);
    });

    test('an UNRECOGNISED request status DOES block', () {
      // The asymmetry is deliberate: the offer has already been shown live, so
      // an undecodable request is the only thing left that could be wrong.
      final r = _requestFromWire('ARCHIVED');
      expect(r.status, isNull);
      expect(canAcceptOffer(_offer(OfferStatus.pending), r), isFalse);
    });
  });

  group('unacceptableReason', () {
    test('is null exactly when canAcceptOffer is true', () {
      for (final os in <OfferStatus?>[...OfferStatus.values, null]) {
        for (final rs in <RequestStatus?>[...RequestStatus.values, null]) {
          final o = _offer(os), r = _request(rs);
          expect(unacceptableReason(o, r) == null, canAcceptOffer(o, r),
              reason: 'offer ${os?.wire} on request ${rs?.wire}');
        }
      }
    });

    test('names the offer state before the request state', () {
      // The winner of an accept sits on a CLOSED request; 'Accepted' is the
      // more useful of the two true things that can be said about it.
      final r = _request(RequestStatus.closed);
      expect(unacceptableReason(_offer(OfferStatus.accepted), r),
          'You have already accepted this offer.');
      expect(unacceptableReason(_offer(OfferStatus.rejected), r),
          'This offer closed when another offer on this request was accepted.');
      expect(unacceptableReason(_offer(OfferStatus.withdrawn), r),
          'The supplier has withdrawn this offer.');
      expect(unacceptableReason(_offer(OfferStatus.pending), r),
          startsWith('This request is no longer open'));
    });
  });

  group('unacceptableLabel', () {
    test('is pill-length and matches the offer state', () {
      final open = _request(RequestStatus.open);
      expect(unacceptableLabel(_offer(OfferStatus.pending), open), isNull);
      expect(unacceptableLabel(_offer(OfferStatus.accepted), open), 'Accepted');
      expect(unacceptableLabel(_offer(OfferStatus.rejected), open), 'Rejected');
      expect(unacceptableLabel(_offer(OfferStatus.withdrawn), open), 'Withdrawn');
    });

    test('borrows RequestStatus.label so the pill matches the header', () {
      final pending = _offer(OfferStatus.pending);
      expect(unacceptableLabel(pending, _request(RequestStatus.closed)), 'Closed');
      expect(unacceptableLabel(pending, _request(RequestStatus.cancelled)),
          'Cancelled');
      // No label to borrow for a status this build cannot decode.
      expect(unacceptableLabel(pending, _requestFromWire('ARCHIVED')), 'Not open');
    });
  });
}
