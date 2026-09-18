import 'package:autonect/data/models/billing_status.dart';

/// What was just paid for, and so what "confirmed" means for it.
enum PurchaseKind { credits, subscription, recovery }

/// How long, after the sheet closes, the app keeps asking the server whether
/// the purchase landed: about half a minute, backing off. After that the
/// banner keeps saying "Processing" (the webhook or the next visit settles it)
/// until [PendingConfirmation.maxAge] passes.
const List<Duration> kConfirmSchedule = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 2),
  Duration(seconds: 3),
  Duration(seconds: 5),
  Duration(seconds: 8),
  Duration(seconds: 10),
];

/// A payment the customer completed in the sheet that the server has not
/// confirmed yet. PURE: [isSatisfiedBy] reads only the server's status, so
/// the app never declares a purchase done on the sheet's word alone.
class PendingConfirmation {
  const PendingConfirmation({
    required this.kind,
    required this.lookupKey,
    required this.planName,
    required this.baselineCredits,
    required this.startedAt,
  });

  static const Duration maxAge = Duration(minutes: 10);

  final PurchaseKind kind;
  final String lookupKey;
  final String planName;

  /// The balance before paying — credits are confirmed when it goes UP.
  final int baselineCredits;
  final DateTime startedAt;

  bool isSatisfiedBy(BillingStatus s) {
    if (s.isProcessing) return false;
    return switch (kind) {
      PurchaseKind.credits => s.credits > baselineCredits,
      PurchaseKind.subscription => s.isSubscribed && s.subscription?.planLookupKey == lookupKey,
      PurchaseKind.recovery => s.displayState != BillingDisplayState.pastDue,
    };
  }

  bool isExpired(DateTime now) => now.difference(startedAt) > maxAge;
}
