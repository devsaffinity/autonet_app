import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/domain/reg_number.dart';
import 'package:autonect/domain/request_draft.dart';
import 'package:autonect/view/screens/buyer/nav_bar/nav_bar.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/detail_item.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 3 — the real draft, and the one submit.
///
/// The CTA is disabled while `validate()` is non-empty, which is what makes
/// `toBody()`'s StateError unreachable rather than merely unlikely. Submit is
/// never auto-retried: creating a request fans PUSH notifications out to every
/// matching supplier, so a second attempt is a second real broadcast.
class ConfirmStepView extends StatefulWidget {
  const ConfirmStepView({super.key, required this.controller});

  final NewRequestController controller;

  @override
  State<ConfirmStepView> createState() => _ConfirmStepViewState();
}

class _ConfirmStepViewState extends State<ConfirmStepView> {
  bool _unconfirmed = false;

  Future<void> _submit() async {
    final outcome = await widget.controller.submit();
    if (!mounted) return;
    setState(() => _unconfirmed = outcome == SubmitOutcome.unconfirmed);
    if (outcome != SubmitOutcome.created) return;
    final created = widget.controller.created.value;
    if (created == null) return;
    await Get.bottomSheet(RequestSendBSheet(request: created),
        isScrollControlled: true);
    // The request exists either way — dismissing the sheet is not a reason to
    // strand the buyer on a wizard they can no longer submit.
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final d = c.draft;
    return Obx(() {
      final missing = d.validate();
      return Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: AppSizes.DEFAULT,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailItem(label: 'Vehicle', value: _vehicle(d)),
                  DetailItem(label: 'Registration',
                      value: normaliseReg(d.regNumber)),
                  DetailItem(label: 'Requested part',
                      value: d.partName.isEmpty ? '—' : d.partName),
                  DetailItem(label: 'Category', value: d.categoryName ?? '—'),
                  DetailItem(label: 'Region', value: d.region?.label ?? '—'),
                  DetailItem(label: 'Condition',
                      value: d.condition?.label ?? '—'),
                  DetailItem(label: 'Urgency', value: d.urgency?.label ?? '—'),
                  if (d.partNumber?.trim().isNotEmpty ?? false)
                    DetailItem(label: 'Part number', value: d.partNumber!),
                  if (d.description?.trim().isNotEmpty ?? false)
                    DetailItem(label: 'Description', value: d.description!),
                  DetailItem(label: 'Photos',
                      value: '${d.uploadedKeys.length} of ${d.images.length} '
                          'uploaded'),
                ],
              )),
              const SizedBox(height: AppSizes.s20),
              _whatHappensNext(),
              if (c.formError.value case final message?) ...[
                const SizedBox(height: AppSizes.s16),
                MyText(text: message, size: AppTextScale.body,
                    color: kRedColor),
                if (_unconfirmed)
                  MyButton(buttonText: 'Check My Requests', mTop: AppSizes.s12,
                      backgroundColor: kTertiaryColor, fontColor: kBlackColor,
                      // Back into the SHELL, on its requests tab. Pushing the
                      // bare page landed the buyer somewhere with no back
                      // button and no nav bar, whose only exits were the OS
                      // gesture and the '+' that reopens this wizard.
                      onTap: () => Get.offAll(() => const BuyerNavBar(
                          initialIndex: BuyerNavBar.requestsTab))),
              ],
              if (missing.isNotEmpty)
                MyText(text: 'Still needed: ${missing.values.join(', ')}',
                    size: AppTextScale.label, color: kGreyTextColor,
                    paddingTop: AppSizes.s16),
            ],
          ),
        )),
        WizardBottomBar(child: MyButton(
          buttonText: 'Send Request', enabled: missing.isEmpty,
          loading: c.busy.value, onTap: _submit,
        )),
      ]);
    });
  }

  /// Falls back to whatever the buyer typed only while there is no server
  /// answer yet; once created, the sheet shows the server's own vehicle row.
  String _vehicle(RequestDraft d) {
    final model = d.vehicleModel?.trim() ?? '';
    return model.isEmpty ? 'From registration' : model;
  }

  Widget _whatHappensNext() => Container(
    padding: const EdgeInsets.all(AppSizes.s16),
    decoration: AppStyling().myDecoration(
      color: kSecondaryColor.withValues(alpha: .06),
      borderColor: kSecondaryColor, radius: AppSizes.radiusMd,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(text: 'What happens next?', size: AppTextScale.subtitle,
            weight: AppWeights.semibold, color: kSecondaryColor,
            paddingBottom: AppSizes.s8),
        for (final line in const [
          'Suppliers in your region review your request and send offers',
          'You are notified as offers arrive',
          'Compare the offers and accept the one you want',
        ])
          MyText(text: '•  $line', size: AppTextScale.body, color: kBlackColor,
              paddingBottom: AppSizes.s4),
      ],
    ),
  );
}
