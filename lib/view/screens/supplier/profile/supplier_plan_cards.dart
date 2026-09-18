import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/billing_display.dart';
import 'package:autonect/domain/date_format.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

const _green = Color(0xFF34C759);

/// "CURRENT ACTIVE PLAN" — the design's peach banner, with the plan's real state.
class SupplierStatusBanner extends StatelessWidget {
  const SupplierStatusBanner({super.key, required this.banner});

  final BillingBanner banner;

  @override
  Widget build(BuildContext context) {
    final pillColor = switch (banner.tone) {
      BannerTone.positive => _green,
      BannerTone.warning => const Color(0xFFFF9500),
      BannerTone.critical => kRedColor,
      BannerTone.neutral => const Color(0xFF666666),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDDD4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: kSecondaryColor, size: 22),
                  SizedBox(width: 8),
                  MyText(
                    text: 'CURRENT ACTIVE PLAN',
                    size: 11,
                    weight: FontWeight.w800,
                    color: Color(0xFF88402A),
                    letterSpacing: 0.5,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  banner.pill,
                  style: const TextStyle(color: kWhiteColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MyText(text: banner.title, size: 20, weight: FontWeight.w800, color: kBlackColor),
          const SizedBox(height: 2),
          Row(
            children: [
              if (banner.busy) ...[
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kSecondaryColor)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: MyText(
                  text: banner.detail,
                  size: 13,
                  weight: FontWeight.w500,
                  color: banner.tone == BannerTone.critical ? kRedColor : const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _featureRow(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(Icons.check_circle_rounded, color: kSecondaryColor, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: MyText(text: text, size: 13, weight: FontWeight.w500, color: const Color(0xFF333333), lineHeight: 1.35),
      ),
    ],
  ),
);

Widget _chip(String text, {Color bg = kSecondaryColor, Color fg = kWhiteColor}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
  child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
);

Widget _outline(String text, VoidCallback? onTap, {Color color = kRedColor}) => OutlinedButton(
  style: OutlinedButton.styleFrom(
    minimumSize: const Size(double.infinity, 44),
    side: BorderSide(color: onTap == null ? kGreyTextColor : color, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  onPressed: onTap,
  child: Text(text, style: TextStyle(color: onTap == null ? kGreyTextColor : color, fontSize: 14, fontWeight: FontWeight.w700)),
);

/// "Supplier Unlimited" — subscribe, or manage the one you have.
class SupplierProCard extends StatelessWidget {
  const SupplierProCard({
    super.key,
    required this.status,
    required this.busy,
    required this.onUpgrade,
    required this.onCancel,
    required this.onResume,
    required this.onFixPayment,
  });

  final BillingStatus status;
  final bool busy;
  final ValueChanged<BillingOffer> onUpgrade;
  final VoidCallback onCancel;
  final VoidCallback onResume;
  final VoidCallback onFixPayment;

  @override
  Widget build(BuildContext context) {
    final offer = status.subscriptionOffer;
    final subscribed = status.isSubscribed;
    final price = offer == null ? '—' : formatPriceTag(offer.pricePence);
    final date = status.displayDate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: subscribed ? kSecondaryColor : const Color(0xFFFFCCBA), width: subscribed ? 2 : 1.5),
        boxShadow: [BoxShadow(color: kSecondaryColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chip('RECOMMENDED FOR VOLUME'),
              if (subscribed) _chip('YOUR CURRENT PLAN', bg: const Color(0xFFE8F8EE), fg: const Color(0xFF28A745)),
            ],
          ),
          const SizedBox(height: 14),
          const MyText(text: 'Supplier Unlimited', size: 20, weight: FontWeight.w800, color: kBlackColor),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              MyText(text: price, size: 28, weight: FontWeight.w900, color: kBlackColor),
              const MyText(text: ' / month', size: 14, weight: FontWeight.w500, color: kGreyTextColor),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),
          _featureRow('Unlimited part request unlocks (0 credits deducted)'),
          _featureRow('Verified Supplier badge on quotes and profile'),
          _featureRow('Direct messaging & negotiation channels with buyers'),
          _featureRow('Priority lead distribution matching registered catalogue'),
          _featureRow('Detailed revenue analytics and transaction tracking'),
          _featureRow('Dedicated 24/7 seller support'),
          const SizedBox(height: 20),
          ..._actions(offer, price, date),
        ],
      ),
    );
  }

  List<Widget> _actions(BillingOffer? offer, String price, DateTime? date) {
    final caption = switch (status.displayState) {
      BillingDisplayState.activeRenewing when date != null => 'Renews on ${formatLongDate(date)}',
      BillingDisplayState.activeCancelling when date != null => 'Ends on ${formatLongDate(date)}',
      BillingDisplayState.pastDue => 'Your last payment failed.',
      _ => null,
    };
    final List<Widget> buttons;
    switch (status.displayState) {
      case BillingDisplayState.pastDue:
        buttons = [
          MyButton(buttonText: 'Update Payment Method', onTap: busy ? null : onFixPayment, enabled: !busy),
          const SizedBox(height: 10),
          _outline('Cancel Subscription', busy || !status.canCancel ? null : onCancel),
        ];
      case BillingDisplayState.activeCancelling:
        buttons = [MyButton(buttonText: 'Resume Subscription', onTap: busy ? null : onResume, enabled: !busy)];
      case _ when status.isSubscribed:
        buttons = [_outline('Cancel Subscription', busy || !status.canCancel ? null : onCancel)];
      case _:
        final allowed = offer != null && offer.allowed && !busy;
        buttons = [
          MyButton(
            buttonText: offer == null ? 'Currently unavailable' : 'Upgrade to Pro ($price/mo)',
            enabled: allowed,
            onTap: allowed ? () => onUpgrade(offer) : null,
          ),
          if (offer != null && !offer.allowed && offer.reason != null)
            MyText(text: offer.reason!, size: 12, color: kGreyTextColor, paddingTop: 8),
        ];
    }
    return [
      if (caption != null) MyText(text: caption, size: 12, color: kGreyTextColor, paddingBottom: 10),
      ...buttons,
    ];
  }
}

/// "Pay as you go" — credit packs, priced by the server.
class SupplierCreditsCard extends StatelessWidget {
  const SupplierCreditsCard({super.key, required this.status, required this.busy, required this.onBuy});

  final BillingStatus status;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final packs = status.creditPacks;
    final first = packs.firstOrNull;
    final allowed = packs.any((p) => p.allowed) && !busy;
    final credits = first?.credits ?? 0;
    final perCredit = first == null || credits <= 0 ? null : formatPence(first.pricePence ~/ credits);
    final String buttonText;
    if (first == null) {
      buttonText = 'Currently unavailable';
    } else if (!packs.any((p) => p.allowed) && status.isSubscribed) {
      buttonText = 'Included in Pro';
    } else if (packs.length == 1) {
      buttonText = 'Buy $credits Credits Pack (${formatPriceTag(first.pricePence)})';
    } else {
      buttonText = 'Buy Credits';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.isSubscribed ? const Color(0xFFEEEEEE) : const Color(0xFFDCDCDC), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chip('PAY AS YOU GO', bg: const Color(0xFFF0F0F0), fg: const Color(0xFF555555)),
              if (status.level.rank == 1) _chip('YOUR CURRENT PLAN', bg: const Color(0xFFE8F8EE), fg: const Color(0xFF28A745)),
            ],
          ),
          const SizedBox(height: 14),
          MyText(text: first == null ? 'Credit Packs' : '$credits Credits Pack', size: 20, weight: FontWeight.w800, color: kBlackColor),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              MyText(text: first == null ? '—' : formatPriceTag(first.pricePence), size: 28, weight: FontWeight.w900, color: kBlackColor),
              if (perCredit != null) MyText(text: ' one-off ($perCredit / lead)', size: 14, weight: FontWeight.w500, color: kGreyTextColor),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),
          _featureRow('${credits > 0 ? credits : 'Pay-per'} full lead unlocks across UK regions'),
          _featureRow('Credits never expire - keep them until you use them'),
          _featureRow('Unlocks registration number, VIN and buyer details'),
          _featureRow('Send competitive quotes and negotiate prices'),
          _featureRow('Top up your balance instantly whenever needed'),
          const SizedBox(height: 20),
          _outline(buttonText, allowed ? onBuy : null, color: kSecondaryColor),
        ],
      ),
    );
  }
}
