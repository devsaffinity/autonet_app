import 'package:autonect/data/models/billing_plan.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/money_format.dart';

/// What tapping a plan card's button does.
enum TierAction { none, subscribe, manage, resume, fixPayment, buyCredits, chooseFree, choosePayPerLead }

/// One card's dynamic half — price, button, state. The static half (tag,
/// title, feature bullets) is design copy and stays in the widget.
class TierCardModel {
  const TierCardModel({
    required this.price,
    required this.period,
    required this.buttonText,
    required this.action,
    this.isCurrent = false,
    this.enabled = true,
    this.showBestValue = false,
  });

  final String price;
  final String period;
  final String buttonText;
  final TierAction action;
  final bool isCurrent;

  /// False greys the button out — the move is not allowed right now.
  final bool enabled;
  final bool showBestValue;
}

class TierCards {
  const TierCards({required this.free, required this.pro, required this.payPerLead});

  final TierCardModel free;
  final TierCardModel pro;
  final TierCardModel payPerLead;
}

const String _unavailable = '—';

String _perLeadPrice(List<({int pricePence, int credits})> packs) {
  if (packs.isEmpty) return _unavailable;
  final single = packs.where((p) => p.credits == 1).firstOrNull;
  if (single != null) return formatPriceTag(single.pricePence);
  final cheapest = packs.map((p) => p.pricePence ~/ p.credits).reduce((a, b) => a < b ? a : b);
  return formatPriceTag(cheapest);
}

/// The electrician's three cards (Free < Pay-Per-Lead < Pro), from the
/// server's status — every move offered is one the server said is allowed.
TierCards electricianTierCards(BillingStatus s, {required bool busy}) {
  final rank = s.level.rank;
  final sub = s.subscriptionOffer;
  final packs = s.creditPacks;
  final cancelling = s.displayState == BillingDisplayState.activeCancelling;
  final pastDue = s.displayState == BillingDisplayState.pastDue;

  final free = TierCardModel(
    price: '£0',
    period: '/Lifetime',
    buttonText: rank == 0 ? 'Current Plan' : 'Included',
    action: TierAction.none,
    isCurrent: rank == 0,
    enabled: rank == 0,
  );

  final TierCardModel pro;
  final proPrice = sub == null ? _unavailable : formatPriceTag(sub.pricePence);
  if (rank >= 2) {
    final (text, action) = pastDue
        ? ('Update Payment', TierAction.fixPayment)
        : cancelling
            ? ('Resume Pro', TierAction.resume)
            : ('Manage / Cancel', TierAction.manage);
    pro = TierCardModel(
      price: proPrice,
      period: '/Month',
      buttonText: busy ? 'Processing…' : text,
      action: action,
      isCurrent: true,
      enabled: !busy,
    );
  } else {
    final allowed = sub != null && sub.allowed && !busy;
    pro = TierCardModel(
      price: proPrice,
      period: '/Month',
      buttonText: busy ? 'Processing…' : (sub == null ? 'Currently unavailable' : 'Upgrade to Pro'),
      action: TierAction.subscribe,
      enabled: allowed,
      showBestValue: true,
    );
  }

  final canBuy = packs.any((p) => p.allowed);
  final ppl = TierCardModel(
    price: _perLeadPrice([for (final p in packs) (pricePence: p.pricePence, credits: p.credits ?? 1)]),
    period: '/Per Lead',
    buttonText: busy
        ? 'Processing…'
        : rank >= 2 && !canBuy
            ? 'Included in Pro'
            : rank == 1
                ? 'Top-Up Credits'
                : rank >= 2
                    ? 'Buy Credits'
                    : 'Choose Credits',
    action: TierAction.buyCredits,
    isCurrent: rank == 1,
    enabled: canBuy && !busy,
  );
  return TierCards(free: free, pro: pro, payPerLead: ppl);
}

/// The registration wizard's cards: prices only, nothing sold. Pro is shown
/// but not choosable — it starts by subscribing, after approval.
TierCards registrationTierCards(List<BillingPlan> plans, {required String selectedTier}) {
  final pro = plans.where((p) => !p.isCreditPack && p.interval == PlanInterval.month).firstOrNull;
  final packs = [
    for (final p in plans)
      if (p.isCreditPack) (pricePence: p.pricePence, credits: p.credits!),
  ];
  return TierCards(
    free: TierCardModel(
      price: '£0',
      period: '/Lifetime',
      buttonText: 'Continue with Free',
      action: TierAction.chooseFree,
      isCurrent: selectedTier == 'FREE',
    ),
    pro: TierCardModel(
      price: pro == null ? _unavailable : formatPriceTag(pro.pricePence),
      period: '/Month',
      buttonText: 'Available after approval',
      action: TierAction.none,
      enabled: false,
      showBestValue: true,
    ),
    payPerLead: TierCardModel(
      price: _perLeadPrice(packs),
      period: '/Per Lead',
      buttonText: 'Choose Pay-Per-Lead',
      action: TierAction.choosePayPerLead,
      isCurrent: selectedTier == 'PAY_PER_LEAD',
    ),
  );
}
