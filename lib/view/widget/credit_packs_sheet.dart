import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/controller/billing/provider_billing_controller.dart';
import 'package:autonect/data/models/billing_status.dart';
import 'package:autonect/domain/billing_display.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The credit packs on offer, straight from the server's status — prices,
/// packs and whether each may be bought right now. Tapping one closes the
/// sheet and opens the store's purchase sheet.
///
/// Its OWN Obx: a bottom sheet is a separate route, so the page's Obx would
/// never rebuild it.
class CreditPacksSheet extends StatelessWidget {
  const CreditPacksSheet({super.key, required this.audience, required this.onSelect});

  final BillingAudience audience;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = ProviderBillingController.ensure();
    final electrician = audience == BillingAudience.electrician;
    return MyBSheet(
      btnText: 'Close',
      onTap: Get.back,
      body: Obx(() {
        final status = c.current;
        final busy = c.isWorking || c.awaiting.value != null;
        final packs = status?.creditPacks ?? const <BillingOffer>[];
        final single = packs.where((p) => p.credits == 1).firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              text: electrician ? 'Purchase Lead Credits' : 'Purchase Credits',
              size: 20,
              weight: FontWeight.w800,
              color: kBlackColor,
              paddingBottom: 4,
            ),
            MyText(
              text: electrician
                  ? '1 credit unlocks 1 customer booking lead. Unused credits never expire.'
                  : '1 credit unlocks 1 part request. Unused credits never expire.',
              size: 13,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              paddingBottom: 16,
            ),
            if (packs.isEmpty)
              const MyText(
                text: 'No credit packs are available right now.',
                size: 14,
                color: kGreyTextColor,
                paddingBottom: 16,
              ),
            for (final pack in packs) ...[
              _PackTile(
                pack: pack,
                savings: _savings(pack, single),
                enabled: pack.allowed && !busy,
                onTap: () {
                  Get.back();
                  onSelect(pack.lookupKey);
                },
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
          ],
        );
      }),
    );
  }

  /// 'Save £5' against buying the same credits one at a time — only when a
  /// single-credit pack exists to compare with.
  static String? _savings(BillingOffer pack, BillingOffer? single) {
    final credits = pack.credits ?? 0;
    if (single == null || credits <= 1) return null;
    final saved = single.pricePence * credits - pack.pricePence;
    return saved > 0 ? 'Save ${formatPriceTag(saved)}' : null;
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack, required this.savings, required this.enabled, required this.onTap});

  final BillingOffer pack;
  final String? savings;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = savings;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      // Material, not a decorated Container: ListTile paints its ink on the
      // nearest Material, so a coloured box in between would hide the tap.
      child: Material(
        color: kWhiteColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: kBlackColor.withValues(alpha: .15)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          onTap: enabled ? onTap : null,
          title: Row(
            children: [
              Flexible(
                child: MyText(text: pack.name, size: 15, weight: FontWeight.w700, color: kBlackColor),
              ),
              if (label != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xff34C759).withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: MyText(text: label, size: 11, weight: FontWeight.w700, color: const Color(0xff34C759)),
                ),
              ],
            ],
          ),
          subtitle: pack.allowed || pack.reason == null
              ? null
              : MyText(text: pack.reason!, size: 12, color: kGreyTextColor),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                text: formatPriceTag(pack.pricePence),
                size: 18,
                weight: FontWeight.w800,
                color: kSecondaryColor,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: kGreyTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
