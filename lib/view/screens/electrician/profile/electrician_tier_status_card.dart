import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/billing_display.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

const _pro = Color(0xffFF9500);
const _green = Color(0xff34C759);

/// "Current Active Tier" — the design's card, with the plan's real state:
/// renewing (dated), cancelling (dated, with Resume), payment failed (with
/// Update Payment), processing, or the Pay-Per-Lead balance.
class ElectricianTierStatusCard extends StatelessWidget {
  const ElectricianTierStatusCard({
    super.key,
    required this.status,
    required this.banner,
    required this.enabled,
    required this.onManage,
    required this.onBuyCredits,
  });

  final BillingStatus status;
  final BillingBanner banner;

  /// False while a payment or change is in progress — every action is inert.
  final bool enabled;

  /// Cancel, resume and card changes all happen in the store.
  final VoidCallback onManage;
  final VoidCallback onBuyCredits;

  Color get _pillColor => switch (banner.tone) {
    BannerTone.positive => _green,
    BannerTone.warning => _pro,
    BannerTone.critical => kRedColor,
    BannerTone.neutral => kGreyTextColor,
  };

  @override
  Widget build(BuildContext context) {
    final isPro = status.level.rank >= 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppStyling().myShadowDecoration(color: kPrimaryColor, radius: 14, borderColor: kTransperentColor),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPro ? _pro.withValues(alpha: .15) : kSecondaryColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPro ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
                  color: isPro ? _pro : kSecondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MyText(text: 'Current Active Tier', size: 12, weight: FontWeight.w500, color: kGreyTextColor),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: MyText(text: banner.title, size: 16, weight: FontWeight.w700, color: kBlackColor),
                        ),
                        if (isPro) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: _pro, borderRadius: BorderRadius.circular(4)),
                            child: const MyText(text: 'PRO', size: 9, weight: FontWeight.w800, color: kWhiteColor),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _pillColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: MyText(text: banner.pill, size: 11, weight: FontWeight.w700, color: _pillColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _detailRow(),
        ],
      ),
    );
  }

  Widget _detailRow() {
    if (banner.busy) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: kSecondaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(child: MyText(text: banner.detail, size: 13, color: kGreyTextColor)),
        ],
      );
    }
    final sub = status.subscription;
    final Widget? action = switch (status.displayState) {
      BillingDisplayState.pastDue => _button('Fix Payment', onManage, filled: true),
      BillingDisplayState.activeCancelling => _button('Resume', onManage, filled: true),
      BillingDisplayState.activeRenewing || BillingDisplayState.trialing when status.canCancel =>
        _button('Manage', onManage),
      _ when status.level.rank == 1 => _button('Buy Credits', onBuyCredits, filled: true, icon: Icons.add_shopping_cart_rounded),
      _ => null,
    };
    final (label, value) = status.level.rank >= 2 && sub != null
        ? ('Pro Subscription', '${formatPriceTag(sub.pricePence)} / month')
        : status.level.rank == 1
            ? ('Available Lead Credits', '${status.credits} credit${status.credits == 1 ? '' : 's'}')
            : ('', '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(text: label, size: 12, color: kGreyTextColor),
                  const SizedBox(height: 2),
                  MyText(text: value, size: 16, weight: FontWeight.w800, color: kBlackColor),
                ],
              ),
              ?action,
            ],
          ),
        SizedBox(height: label.isNotEmpty ? 8 : 0),
        MyText(
          text: banner.detail,
          size: 12,
          color: status.displayState == BillingDisplayState.pastDue ? kRedColor : kGreyTextColor,
        ),
        if (label.isEmpty && action != null) ...[const SizedBox(height: 8), action],
      ],
    );
  }

  Widget _button(String text, VoidCallback onTap, {bool filled = false, bool danger = false, IconData? icon}) {
    final color = danger ? kRedColor : kSecondaryColor;
    final child = MyText(text: text, size: 13, weight: FontWeight.w700, color: filled ? kWhiteColor : color);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    if (filled) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: shape, padding: padding),
        onPressed: enabled ? onTap : null,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16, color: kWhiteColor),
        label: child,
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(side: BorderSide(color: color), shape: shape, padding: padding),
      onPressed: enabled ? onTap : null,
      child: child,
    );
  }
}
