/// The backend gives NINE semantically different 409s the same `CONFLICT`
/// code; only the English prose tells them apart. This is the one place that
/// prose is read, so a backend copy change fails a test here instead of
/// silently degrading the UX on three different screens.
library;

enum ConflictKind {
  requestNotOpen,
  offerNotAcceptable,
  requestAlreadyAccepted,
  illegalTransition,
  notCancellable,
  staleRead,
  alreadyExists,
  alreadyReviewed,
  notDeliveredYet,
  other,
}

/// Classification is by SUBSTRING, never equality: two of the nine messages
/// interpolate live values ('Illegal transition PLACED → DELIVERED',
/// 'Order cannot be cancelled at PREPARING'), so matching whole sentences would
/// miss every real occurrence.
ConflictKind classifyConflict(String message) {
  final m = message.toLowerCase();
  if (m.contains('already reviewed')) return ConflictKind.alreadyReviewed;
  if (m.contains('only after delivery')) return ConflictKind.notDeliveredYet;
  if (m.contains('already has an accepted offer')) {
    return ConflictKind.requestAlreadyAccepted;
  }
  if (m.contains('no longer acceptable')) return ConflictKind.offerNotAcceptable;
  if (m.contains('is not open')) return ConflictKind.requestNotOpen;
  if (m.contains('illegal transition')) return ConflictKind.illegalTransition;
  if (m.contains('cannot be cancelled at')) return ConflictKind.notCancellable;
  if (m.contains('changed concurrently')) return ConflictKind.staleRead;
  if (m.contains('already exists')) return ConflictKind.alreadyExists;
  return ConflictKind.other;
}
