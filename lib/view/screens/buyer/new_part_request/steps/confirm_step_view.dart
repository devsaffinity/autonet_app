import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/buyer/new_request_controller.dart';
import 'package:autonect/domain/reg_number.dart';
import 'package:autonect/domain/request_draft.dart';
import 'package:autonect/view/screens/buyer/nav_bar/nav_bar.dart';
import 'package:autonect/view/screens/buyer/new_part_request/new_part_request.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The comp's glyph tile: 40pt square, corner 10, #F2F2F2 behind #D94D2F.
///
/// All three numbers are READ OFF the shipped SVGs (`summary_a..d.svg`), whose
/// background is baked into the asset — a Material glyph has to rebuild that
/// same box by hand, so the two kinds of row have to agree here or the card
/// visibly mixes two tile shapes. 10 is deliberately not an [AppSizes] radius:
/// it is this asset's `rx`, not a step on the app's scale.
const double _kTile = 40, _kTileRadius = 10;

/// Step 3 — the real draft, and the one submit.
///
/// The CTA is disabled while `validate()` is non-empty, which is what makes
/// `toBody()`'s StateError unreachable rather than merely unlikely. Submit is
/// never auto-retried: creating a request fans PUSH notifications out to every
/// matching supplier, so a second attempt is a second real broadcast.
///
/// The comp draws three summary rows; this card draws EVERY field the draft
/// carries. Three would be a confirm screen that hides most of what is about
/// to be confirmed — and the two it drops, Region and Category, are exactly
/// the pair that decides which suppliers the request reaches.
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
            // STRETCH, not start. Under `start` the card sized itself to its
            // widest row, so a summary of short values ('AC', 'Used') rendered
            // as a narrow column floating in the left of the screen while the
            // longer-texted note below it went full width.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom padding 0: every row carries its own s16 gap, so the
              // last one's gap IS the card's bottom padding. Saves threading
              // an is-last flag through rows that are conditional anyway.
              AppCard(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.s16, AppSizes.s16, AppSizes.s16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(glyph: const _Glyph.asset(Assets.imagesSummaryA),
                        label: 'Vehicle', value: _vehicle(d)),
                    _SummaryRow(glyph: const _Glyph.icon(Icons.badge_outlined),
                        label: 'Registration',
                        value: normaliseReg(d.regNumber)),
                    _SummaryRow(glyph: const _Glyph.asset(Assets.imagesSummaryB),
                        label: 'Requested Part',
                        value: d.partName.isEmpty ? '—' : d.partName),
                    _SummaryRow(
                        glyph: const _Glyph.icon(Icons.category_outlined),
                        label: 'Category', value: d.categoryName ?? '—'),
                    _SummaryRow(glyph: const _Glyph.asset(Assets.imagesSummaryC),
                        label: 'Region', value: d.region?.label ?? '—'),
                    _SummaryRow(
                        glyph: const _Glyph.icon(Icons.verified_outlined),
                        label: 'Condition', value: d.condition?.label ?? '—'),
                    _SummaryRow(glyph: const _Glyph.icon(Icons.timer_outlined),
                        label: 'Urgency', value: d.urgency?.label ?? '—'),
                    if (d.partNumber?.trim().isNotEmpty ?? false)
                      _SummaryRow(glyph: const _Glyph.icon(Icons.tag),
                          label: 'Part Number', value: d.partNumber!),
                    if (d.description?.trim().isNotEmpty ?? false)
                      _SummaryRow(glyph: const _Glyph.icon(Icons.notes_rounded),
                          label: 'Description', value: d.description!),
                    _SummaryRow(
                        glyph: const _Glyph.icon(Icons.photo_library_outlined),
                        label: 'Photos',
                        value: '${d.uploadedKeys.length} of ${d.images.length} '
                            'uploaded'),
                  ],
                ),
              ),
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
    // Bottom s4 rather than s16: the last bullet brings its own s12, and the
    // note otherwise sits noticeably lower than it does at the top.
    padding: const EdgeInsets.fromLTRB(
        AppSizes.s16, AppSizes.s16, AppSizes.s16, AppSizes.s4),
    decoration: AppStyling().myDecoration(
      color: kSecondaryColor.withValues(alpha: .06),
      borderColor: kSecondaryColor, radius: AppSizes.radiusMd,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(text: 'What happens next?', size: AppTextScale.subtitle,
            weight: AppWeights.semibold, color: kSecondaryColor,
            paddingBottom: AppSizes.s12),
        for (final line in const [
          'Sellers in your area will review your request and send offers',
          "You'll be notified when new offers arrive",
          'Compare offers and select the best one for your needs',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.s12),
            // A hanging indent: the dot sits OUTSIDE the text column, so the
            // second line of a wrapping bullet starts under the first word
            // rather than under the dot. Every one of these three wraps at
            // 320dp, which is where the single interpolated string this
            // replaces read as one ragged block.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(text: '•', size: AppTextScale.body, color: kBlackColor),
                Expanded(child: MyText(text: line, size: AppTextScale.body,
                    color: kBlackColor, paddingLeft: AppSizes.s8)),
              ],
            ),
          ),
      ],
    ),
  );
}

/// A summary row's glyph, from one of two sources.
///
/// The comp shipped four 40pt tiles as SVG (`summary_a..d`) with their own
/// background baked in, and they cover exactly the fields it chose to draw.
/// The rest of the draft gets a Material glyph on a tile rebuilt to the same
/// spec — the alternative was inventing six more assets, or shipping a confirm
/// screen that only confirms four things.
class _Glyph {
  const _Glyph.asset(this.asset) : icon = null;
  const _Glyph.icon(this.icon) : asset = null;

  final String? asset;
  final IconData? icon;

  Widget build() {
    if (asset case final path?) {
      return CommonImageView(svgPath: path, height: _kTile, width: _kTile);
    }
    return Container(
      width: _kTile,
      height: _kTile,
      decoration: BoxDecoration(
        color: kTertiaryColor,
        borderRadius: BorderRadius.circular(_kTileRadius),
      ),
      child: Icon(icon, color: kSecondaryColor, size: AppSizes.s20),
    );
  }
}

/// One row of the confirm card: a glyph tile, then the field NAME in black
/// over its value in grey.
///
/// That emphasis is INVERTED from [DetailItem], which is why this is its own
/// widget rather than a flag on that one — five other screens read the value
/// as the loud half of the pair, and only this card reads the label that way.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.glyph, required this.label,
      required this.value});

  final _Glyph glyph;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.s16),
    // Top-aligned, not centred: a long description wraps to three or four
    // lines, and a centred tile would then float in the middle of them.
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        glyph.build(),
        const SizedBox(width: AppSizes.s12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(text: label, size: AppTextScale.body,
                weight: AppWeights.semibold, color: kBlackColor),
            MyText(text: value, size: AppTextScale.body,
                color: kGreyTextColor, paddingTop: AppSizes.s4),
          ],
        )),
      ],
    ),
  );
}
