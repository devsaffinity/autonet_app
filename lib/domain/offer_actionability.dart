/// The ONE definition of "can this buyer still accept this offer?".
///
/// `GET /v1/requests/{id}/offers` returns every offer that is not WITHDRAWN, so
/// an auto-REJECTED sibling and the ACCEPTED winner arrive in the same array as
/// the live ones and are told apart by nothing but `status`. Accepting sets that
/// offer ACCEPTED, every sibling REJECTED and the parent request CLOSED in ONE
/// transaction (orders.service.ts:46-66), and the buyer is sent no notification
/// of their own accept — so every screen that offers an accept has to re-derive
/// this from the data it is holding, never from the route that got the buyer
/// there. `closeOrCancel` (requests.service.ts:98-106) is the other half: it
/// leaves the offers PENDING and moves only the request, so the request status
/// has to be read even when every offer still looks live.
///
/// Pure — no Flutter, no Get — so the whole truth table is unit-tested without
/// a widget tree.
library;

import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/part_request.dart';

/// The single reason an accept is refused, so the pill and the sentence below
/// can never disagree about which reason it was.
enum _Blocker { accepted, rejected, withdrawn, requestNotOpen }

_Blocker? _blocker(Offer offer, PartRequest request) {
  // Offer state is read FIRST: on a request closed by an accept, the winner
  // should read 'Accepted' and the losers 'Rejected', which is the more useful
  // of the two true things that can be said about each of them.
  switch (offer.status) {
    case OfferStatus.accepted:
      return _Blocker.accepted;
    case OfferStatus.rejected:
      return _Blocker.rejected;
    case OfferStatus.withdrawn:
      return _Blocker.withdrawn;
    case OfferStatus.pending:
    case null:
      // PENDING is live, and so is null. `OfferStatus.fromWire` answers null
      // ONLY for a wire value this build does not recognise (request_enums.dart
      // deliberately has no unknown member), and hiding a possibly-live offer
      // costs the buyer a real purchase, while the occasional 409 is a path the
      // accept screen already handles well.
      break;
  }
  // Unlike the offer above, an unrecognised REQUEST status is not waved
  // through: `PartRequest.isOpen` is this codebase's one definition of open and
  // already reads null as not-open, and — decisively — the offer's own status
  // has just been confirmed live, so the request is the only thing left that
  // could be wrong. Guessing 'open' here would re-open every symptom.
  return request.isOpen ? null : _Blocker.requestNotOpen;
}

/// True when POST /v1/offers/{id}/accept has a chance of succeeding.
bool canAcceptOffer(Offer offer, PartRequest request) =>
    _blocker(offer, request) == null;

/// A pill-length label for [StatusBadge], or null when the offer is live.
///
/// Separate from [unacceptableReason] because `OfferStatus` carries no `label`
/// the way the other wire enums do, and a badge cannot hold a sentence.
String? unacceptableLabel(Offer offer, PartRequest request) =>
    switch (_blocker(offer, request)) {
      _Blocker.accepted => 'Accepted',
      _Blocker.rejected => 'Rejected',
      _Blocker.withdrawn => 'Withdrawn',
      // Off RequestStatus so the pill matches the one the request header draws;
      // 'Not open' covers the undecodable status, which has no label to borrow.
      _Blocker.requestNotOpen => request.status?.label ?? 'Not open',
      null => null,
    };

/// One buyer-facing sentence saying why the accept is gone, or null when it is
/// not gone. Says what happened, never what the buyer did wrong.
String? unacceptableReason(Offer offer, PartRequest request) =>
    switch (_blocker(offer, request)) {
      _Blocker.accepted => 'You have already accepted this offer.',
      _Blocker.rejected =>
        'This offer closed when another offer on this request was accepted.',
      _Blocker.withdrawn => 'The supplier has withdrawn this offer.',
      _Blocker.requestNotOpen =>
        'This request is no longer open, so its offers can no longer be '
            'accepted.',
      null => null,
    };
