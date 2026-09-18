import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/billing_confirmation.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';

/// Whose plan screen — an electrician buys LEADS, a supplier buys request
/// access, and the copy says so. (Not AppRole: `lib/domain` stays pure.)
enum BillingAudience { electrician, supplier }

enum BannerTone { positive, neutral, warning, critical }

/// The status banner at the top of the plans screen, decided in one place so
/// both roles' screens say the same true thing.
class BillingBanner {
  const BillingBanner({
    required this.pill,
    required this.tone,
    required this.title,
    required this.detail,
    this.busy = false,
  });

  final String pill;
  final BannerTone tone;
  final String title;
  final String detail;

  /// A payment is being confirmed — the banner shows a spinner.
  final bool busy;
}

/// Level names as the design writes them.
String levelLabel(int rank, BillingAudience audience) => switch ((audience, rank)) {
  (BillingAudience.electrician, >= 2) => 'Pro (Monthly)',
  (BillingAudience.electrician, 1) => 'Pay-Per-Lead',
  (BillingAudience.electrician, _) => 'Free',
  (BillingAudience.supplier, >= 2) => 'Pro Unlimited',
  (BillingAudience.supplier, 1) => 'Pay-Per-Lead',
  (BillingAudience.supplier, _) => 'Standard',
};

String _creditsLine(int credits, BillingAudience a) {
  final unit = a == BillingAudience.electrician ? 'lead credit' : 'credit';
  return '$credits $unit${credits == 1 ? '' : 's'} available';
}

String _date(DateTime? d) => d == null ? 'the end of this period' : formatLongDate(d);

String _perInterval(BillingSubscriptionInfo? sub) {
  if (sub == null || sub.pricePence <= 0) return '';
  return ' · ${formatPriceTag(sub.pricePence)}${sub.interval?.suffix ?? ''}';
}

BillingBanner describeBilling(
  BillingStatus s,
  BillingAudience a, {
  PendingConfirmation? awaiting,
}) {
  final pro = a == BillingAudience.electrician ? 'Pro' : 'your subscription';
  if (awaiting != null || s.isProcessing) {
    return BillingBanner(
      pill: 'PROCESSING',
      tone: BannerTone.warning,
      title: awaiting?.planName.isNotEmpty == true ? awaiting!.planName : levelLabel(s.level.rank, a),
      detail: 'Confirming your payment…',
      busy: true,
    );
  }
  final title = levelLabel(s.level.rank, a);
  switch (s.displayState) {
    case BillingDisplayState.pastDue:
      return BillingBanner(
        pill: 'PAYMENT FAILED',
        tone: BannerTone.critical,
        title: title,
        detail: 'Your last payment failed. Update your card by ${_date(s.displayDate)} to keep $pro.',
      );
    case BillingDisplayState.activeCancelling:
      return BillingBanner(
        pill: 'CANCELLING',
        tone: BannerTone.warning,
        title: title,
        detail: 'Ends on ${_date(s.displayDate)} — you can resume until then.',
      );
    case BillingDisplayState.activeRenewing:
      return BillingBanner(
        pill: a == BillingAudience.supplier ? 'ACTIVE PRO' : 'ACTIVE',
        tone: BannerTone.positive,
        title: title,
        detail: 'Renews on ${_date(s.displayDate)}${_perInterval(s.subscription)}',
      );
    case BillingDisplayState.trialing:
      return BillingBanner(
        pill: 'TRIAL',
        tone: BannerTone.positive,
        title: title,
        detail: 'Free trial until ${_date(s.displayDate)}',
      );
    case BillingDisplayState.processing:
    case BillingDisplayState.none:
      break;
  }
  if (s.level.rank == 1) {
    return BillingBanner(pill: 'ACTIVE', tone: BannerTone.positive, title: title, detail: _creditsLine(s.credits, a));
  }
  return BillingBanner(
    pill: a == BillingAudience.supplier ? 'STANDARD' : 'ACTIVE',
    tone: BannerTone.neutral,
    title: title,
    detail: a == BillingAudience.electrician
        ? 'Choose Pay-Per-Lead or Pro to accept client leads.'
        : _creditsLine(s.credits, a),
  );
}

/// The confirm-cancel dialog's promise, with the real date.
String cancelWarning(BillingStatus s, BillingAudience a) {
  final end = _date(s.subscription?.cancelAt ?? s.subscription?.currentPeriodEnd);
  final fallback = levelLabel(s.baseLevel.rank, a);
  final keep = a == BillingAudience.electrician ? 'unlimited leads and your PRO badge' : 'unlimited request access';
  return 'You keep $keep until $end. After that your plan becomes $fallback. You can resume any time before then.';
}

/// The confirm-resume dialog's promise — the next charge, dated and priced.
String resumeWarning(BillingStatus s) {
  final sub = s.subscription;
  final price = sub == null || sub.pricePence <= 0 ? '' : ' of ${formatPriceTag(sub.pricePence)}';
  return 'Your plan will renew on ${_date(sub?.currentPeriodEnd)} with the usual payment$price.';
}
