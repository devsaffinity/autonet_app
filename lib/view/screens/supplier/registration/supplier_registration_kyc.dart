import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/supplier/supplier_kyc_controller.dart';
import 'package:autonect/data/models/kyc_status.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/dashed_border.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 2 of 3 — the three KYC documents.
///
/// Every card renders from the SERVER's answer, never from what the screen just
/// did. Upload is three round trips (ticket, PUT to S3, confirm) and only the
/// last makes it count, so optimistically ticking a card would show a document
/// as accepted that the server may have rejected on re-read.
class SupplierKycStep extends StatefulWidget {
  final VoidCallback onNext;
  const SupplierKycStep({super.key, required this.onNext});

  @override
  State<SupplierKycStep> createState() => _SupplierKycStepState();
}

class _SupplierKycStepState extends State<SupplierKycStep> {
  final _c = SupplierKycController.ensure();

  @override
  void initState() {
    super.initState();
    _c.load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSizes.HORIZONTAL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // OUTSIDE StateView, deliberately. absorb() routes every non-network
            // failure to formError, and nothing on this screen rendered it — so
            // an upload that failed after the server had already deleted the
            // previous document was completely silent, left the card showing a
            // file that no longer exists, and kept Next enabled over the hole.
            // Inside StateView.builder it would vanish precisely when load()
            // fails and the state becomes Failed.
            Obx(() {
              final message = _c.formError.value;
              if (message == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: AppSizes.s16),
                padding: const EdgeInsets.all(AppSizes.s12),
                decoration: BoxDecoration(
                  color: kRedColor.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(color: kRedColor.withValues(alpha: .4)),
                ),
                child: MyText(text: message, size: AppTextScale.label,
                    color: kRedColor, lineHeight: 1.4),
              );
            }),
            Obx(() => StateView<KycState>(
              state: _c.state.value,
              onRetry: _c.load,
              builder: (_, kyc) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.s16),
                  // The required set comes from the SERVER, not a hard-coded
                  // three: an electrician needs ID + LICENCE, and the same
                  // widget serves both.
                  for (final (i, type) in kyc.requiredDocuments.indexed) ...[
                    _DocumentCard(
                      type: type,
                      document: kyc.documentFor(type),
                      controller: _c,
                      // The design gives the FIRST card the full affordance —
                      // cloud glyph, supported formats, a Select File button —
                      // and the rest a compact one-line zone.
                      expanded: i == 0,
                    ),
                    const SizedBox(height: AppSizes.s16),
                  ],
                  const _TrustRow(),
                  const SizedBox(height: AppSizes.s16),
                ],
              ),
            )),
              ],
            ),
          ),
        ),
        // Gated on every required document being present, which is the same
        // rule the server uses to decide SUBMITTED.
        Obx(() => SupplierBottomButton(
          label: 'Next',
          onTap: _c.isComplete ? widget.onNext : null,
        )),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.type,
    required this.document,
    required this.controller,
    required this.expanded,
  });

  final KycDocType type;
  final KycDocument? document;
  final SupplierKycController controller;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    // Material, not a coloured Container: the nearest Material ancestor was
    // the Scaffold, so every InkWell splash inside painted BEHIND this card's
    // opaque background and no tap produced any feedback at all.
    return Material(
      color: kPrimaryColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(color: kGreyTextColor.withValues(alpha: .25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
          const SizedBox(height: AppSizes.s16),
          Obx(() {
            final active = controller.uploading.value ?? controller.picking.value;
            final busy = active == type;
            // Another card holds the latch. Its controls must LOOK unavailable
            // rather than staying lit and silently dropping every tap.
            final blocked = active != null && !busy;
            final uploaded = document?.uploaded ?? false;
            return Column(
              children: [
                // The zone STAYS after an upload, as drawn — the uploaded row
                // sits beneath it rather than replacing it, so replacing a
                // document is one tap and needs no delete first.
                _UploadZone(
                  type: type,
                  expanded: expanded,
                  busy: busy,
                  blocked: blocked,
                  onTap: () => controller.pickAndUpload(type),
                ),
                if (uploaded) ...[
                  const SizedBox(height: AppSizes.s12),
                  _UploadedRow(
                    document: document!,
                    busy: busy,
                    blocked: blocked,
                    onRemove: () => controller.remove(type),
                  ),
                ],
              ],
            );
          }),
          ],
        ),
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(AppSizes.s8),
        decoration: BoxDecoration(
          color: kLightOrangeColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Icon(_glyphFor(type), size: AppSizes.s20,
            color: kSecondaryColor),
      ),
      const SizedBox(width: AppSizes.s12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(text: type.label, size: AppTextScale.body,
                weight: AppWeights.bold, color: kBlackColor),
            // label (12), not caption (10): every sibling card subtitle in
            // this wizard uses 12, and caption is the tertiary tier here.
            // Uncapped because nothing below is height-constrained, so a cap
            // could only ever destroy text.
            MyText(text: type.hint, size: AppTextScale.label,
                color: kGreyTextColor),
          ],
        ),
      ),
    ],
  );

  static IconData _glyphFor(KycDocType type) => switch (type) {
    KycDocType.id => Icons.badge_outlined,
    KycDocType.businessRegistry => Icons.business_center_outlined,
    KycDocType.tax => Icons.receipt_long_outlined,
    KycDocType.license => Icons.workspace_premium_outlined,
  };
}

/// The dashed upload target.
///
/// The whole zone is the tap target, not just the button inside it — the design
/// draws "Select File" as the affordance, but a 200px dashed box that ignores
/// taps everywhere except one pill is a worse control than it looks.
class _UploadZone extends StatelessWidget {
  const _UploadZone({
    required this.type,
    required this.expanded,
    required this.busy,
    required this.blocked,
    required this.onTap,
  });

  final KycDocType type;
  final bool expanded;

  /// THIS zone's document is in flight. Owns the spinner and the copy swap.
  final bool busy;

  /// ANOTHER card holds the latch. Disabled — but it must NOT claim to be
  /// uploading, which is why this is a second flag rather than reusing [busy].
  final bool blocked;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    // Announced as disabled rather than as a live button that does nothing.
    enabled: !busy && !blocked,
    label: busy ? 'Uploading ${type.label}' : 'Upload ${type.label}',
    child: Opacity(
      opacity: blocked ? .45 : 1,
      child: InkWell(
        onTap: (busy || blocked) ? null : onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: DashedBorder(
          radius: AppSizes.radiusMd,
          color: kGreyTextColor.withValues(alpha: blocked ? .3 : .55),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: expanded ? AppSizes.s24 : AppSizes.s20,
              horizontal: AppSizes.s12,
            ),
            child: ExcludeSemantics(
              child: expanded ? _expandedBody() : _compactBody(),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _expandedBody() => Column(
    children: [
      _icon(Icons.cloud_upload_outlined, AppSizes.s32),
      const SizedBox(height: AppSizes.s8),
      MyText(
        text: busy ? 'Uploading…' : 'Drag and drop file',
        size: AppTextScale.body,
        weight: AppWeights.medium,
        color: kBlackColor,
      ),
      MyText(
        text: 'Supported: JPG, PNG, PDF (Max 10MB)',
        size: AppTextScale.caption,
        color: kGreyTextColor,
        paddingTop: AppSizes.s4,
        paddingBottom: AppSizes.s16,
      ),
      // Not a nested tap target: the zone above already handles the tap, and
      // two overlapping InkWells would fight over the gesture.
      IgnorePointer(
        child: SizedBox(
          width: 160,
          child: MyButton(
            buttonText: 'Select File',
            height: 40,
            fontSize: AppTextScale.body,
            loading: busy,
          ),
        ),
      ),
    ],
  );

  Widget _compactBody() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _icon(Icons.upload_file_outlined, AppSizes.s20),
      const SizedBox(width: AppSizes.s8),
      Flexible(
        child: MyText(
          text: busy ? 'Uploading…' : _compactLabel,
          size: AppTextScale.body,
          weight: AppWeights.medium,
          color: kBlackColor,
          maxLines: 1,
          textOverflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  /// The design labels each compact zone with its own verb.
  String get _compactLabel => switch (type) {
    KycDocType.businessRegistry => 'Upload Registry',
    KycDocType.tax => 'Upload Tax ID',
    KycDocType.id => 'Upload ID',
    KycDocType.license => 'Upload Licence',
  };

  Widget _icon(IconData icon, double size) => busy
      ? SizedBox(
          height: size,
          width: size,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: kSecondaryColor,
          ),
        )
      : Icon(icon, size: size, color: kGreyTextColor);
}

class _UploadedRow extends StatelessWidget {
  const _UploadedRow({
    required this.document,
    required this.busy,
    required this.blocked,
    required this.onRemove,
  });

  final KycDocument document;
  final bool busy;
  final bool blocked;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // fileName is null for documents uploaded before the server recorded it, so
    // the type is the fallback rather than a blank row.
    final name = document.fileName ?? document.type.label;
    final size = document.displaySize;
    return Container(
      padding: const EdgeInsets.all(AppSizes.s12),
      decoration: BoxDecoration(
        color: kMutedSurfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              size: AppSizes.s20, color: kGreyTextColor),
          const SizedBox(width: AppSizes.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(text: name, size: AppTextScale.body,
                    weight: AppWeights.medium, color: kBlackColor,
                    maxLines: 1, textOverflow: TextOverflow.ellipsis),
                MyText(
                  // The design says "Processing". Nothing processes a KYC
                  // document asynchronously — confirm is synchronous and this
                  // row only exists once it returned — so a Processing label
                  // would never change to anything.
                  text: size == null ? 'Uploaded' : '$size · Uploaded',
                  size: AppTextScale.caption,
                  color: kGreyTextColor,
                ),
              ],
            ),
          ),
          // Both branches occupy the SAME 48x48 box. IconButton lays out at
          // kMinInteractiveDimension under Material 3, so a bare 20px spinner
          // here made the row visibly shrink the moment a delete started and
          // snap back when it finished — for the whole of a three-round-trip
          // replace, that is seconds of the layout jumping.
          if (busy)
            const SizedBox(
              height: kMinInteractiveDimension,
              width: kMinInteractiveDimension,
              child: Center(
                child: SizedBox(
                  height: AppSizes.s20,
                  width: AppSizes.s20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kSecondaryColor),
                ),
              ),
            )
          else
            // The label goes ON the IconButton, not on a Semantics wrapper
            // around it: the wrapper produced one node carrying the label and a
            // separate child node carrying the tap action, so a screen reader
            // announced an unlabelled button.
            IconButton(
              onPressed: blocked ? null : onRemove,
              tooltip: 'Remove ${document.type.label}',
              // Dropped when disabled so IconButton can grey it out; a
              // hard-coded red stays fully red under a null onPressed and
              // keeps looking live.
              icon: Icon(Icons.delete_outline,
                  size: AppSizes.s20, color: blocked ? null : kRedColor),
            ),
        ],
      ),
    );
  }
}

/// The design's footer badges.
///
/// "256-Bit Encryption" is a fact about TLS. The other two are CLAIMS: GDPR
/// compliance is a legal position and ISO 27001 is an audited certification
/// that an organisation either holds or does not. They are listed here in one
/// place, data-driven, so a single edit removes any that turn out not to be
/// true — do not scatter them into the layout.
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const List<(IconData, String)> _items = [
    (Icons.lock_outline, '256-Bit Encryption'),
    (Icons.verified_user_outlined, 'GDPR Compliant'),
    (Icons.workspace_premium_outlined, 'ISO 27001'),
  ];

  @override
  // Wrap, NOT a Row of equal Flexibles. Three flex:1 slots cap every badge at
  // a third of the width regardless of what it needs, so "256-Bit Encryption"
  // rendered as "256-Bit Encrypti…" at 320dp on the DEFAULT text scale — with
  // no overflow warning, because maxLines + ellipsis absorb it silently —
  // while "ISO 27001" sat on 33dp of slack it could not lend. Wrap gives each
  // badge the full width to measure against and moves to a second run instead
  // of truncating.
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: AppSizes.s12,
    runSpacing: AppSizes.s8,
    children: [
      for (final (icon, label) in _items)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.s12, color: kSecondaryColor),
            const SizedBox(width: AppSizes.s4),
            // Kept so a badge wider than the whole line still ellipsizes
            // rather than overflowing.
            Flexible(
              child: MyText(text: label, size: AppTextScale.caption,
                  color: kGreyTextColor, maxLines: 1,
                  textOverflow: TextOverflow.ellipsis),
            ),
          ],
        ),
    ],
  );
}
