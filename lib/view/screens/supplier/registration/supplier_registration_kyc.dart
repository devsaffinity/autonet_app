import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/supplier/supplier_kyc_controller.dart';
import 'package:autonect/data/models/kyc_status.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 4 of 5 — the three KYC documents.
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => StateView<KycState>(
              state: _c.state.value,
              onRetry: _c.load,
              builder: (_, kyc) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.s16),
                  // The required set comes from the SERVER, not a hard-coded
                  // three: an electrician needs ID + LICENCE, and the same
                  // widget serves both.
                  for (final type in kyc.requiredDocuments) ...[
                    _DocumentCard(
                      type: type,
                      document: kyc.documentFor(type),
                      controller: _c,
                    ),
                    const SizedBox(height: AppSizes.s16),
                  ],
                  const _TrustRow(),
                  const SizedBox(height: AppSizes.s24),
                ],
              ),
            )),
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
  });

  final KycDocType type;
  final KycDocument? document;
  final SupplierKycController controller;

  @override
  Widget build(BuildContext context) {
    final uploaded = document?.uploaded ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.s16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: kGreyTextColor.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.s8),
                decoration: BoxDecoration(
                  color: kLightOrangeColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(Icons.badge_outlined,
                    size: AppSizes.s20, color: kSecondaryColor),
              ),
              const SizedBox(width: AppSizes.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(text: type.label, size: AppTextScale.body,
                        weight: AppWeights.bold, color: kBlackColor),
                    MyText(text: type.hint, size: AppTextScale.label,
                        color: kGreyTextColor, maxLines: 2,
                        textOverflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s12),
          Obx(() {
            final busy = controller.uploading.value == type;
            return uploaded
                ? _UploadedRow(
                    document: document!,
                    busy: busy,
                    onRemove: () => controller.remove(type),
                  )
                : _DropZone(
                    busy: busy,
                    onTap: () => controller.pickAndUpload(type),
                  );
          }),
        ],
      ),
    );
  }
}

/// The comp draws "Drag and drop file". There is no drag-and-drop on a phone,
/// so the whole zone is the tap target and the label says what actually works.
class _DropZone extends StatelessWidget {
  const _DropZone({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Choose a file to upload',
    child: InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        width: double.infinity,
        // Comfortably over the 48dp floor, and the whole area is the target
        // rather than just the button the comp draws inside it.
        padding: const EdgeInsets.symmetric(vertical: AppSizes.s24),
        decoration: BoxDecoration(
          color: kMutedSurfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          children: [
            if (busy)
              const SizedBox(
                height: AppSizes.s24,
                width: AppSizes.s24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: kSecondaryColor),
              )
            else
              const Icon(Icons.cloud_upload_outlined,
                  size: AppSizes.s32, color: kSecondaryColor),
            const SizedBox(height: AppSizes.s8),
            MyText(
              text: busy ? 'Uploading…' : 'Choose a file',
              size: AppTextScale.body,
              weight: AppWeights.medium,
              color: kBlackColor,
            ),
            MyText(
              text: 'PDF, JPG or PNG · max 10 MB',
              size: AppTextScale.caption,
              color: kGreyTextColor,
              paddingTop: AppSizes.s4,
            ),
          ],
        ),
      ),
    ),
  );
}

class _UploadedRow extends StatelessWidget {
  const _UploadedRow({
    required this.document,
    required this.busy,
    required this.onRemove,
  });

  final KycDocument document;
  final bool busy;
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
                MyText(text: name, size: AppTextScale.label,
                    weight: AppWeights.medium, color: kBlackColor,
                    maxLines: 1, textOverflow: TextOverflow.ellipsis),
                MyText(
                  // The comp said "2.4 MB · Processing". Nothing processes a
                  // KYC document asynchronously — confirm is synchronous and
                  // the row only exists once it succeeded — so claiming
                  // otherwise would leave a status that never changes.
                  text: size == null ? 'Uploaded' : '$size · Uploaded',
                  size: AppTextScale.caption,
                  color: kGreyTextColor,
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              height: AppSizes.s20,
              width: AppSizes.s20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: kSecondaryColor),
            )
          else
            Semantics(
              button: true,
              label: 'Remove ${document.type.label}',
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline,
                    size: AppSizes.s20, color: kRedColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// The comp's footer badges.
///
/// "ISO 27001" is DELIBERATELY ABSENT. It is an audited certification, not a
/// UI string, and printing it without holding the certificate is the kind of
/// claim that surfaces in a procurement review. Add it here only once someone
/// confirms the certificate exists.
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _item(Icons.lock_outline, 'Encrypted in transit'),
      const SizedBox(width: AppSizes.s16),
      _item(Icons.shield_outlined, 'Used only for verification'),
    ],
  );

  Widget _item(IconData icon, String label) => Flexible(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.s12, color: kSecondaryColor),
        const SizedBox(width: AppSizes.s4),
        Flexible(
          child: MyText(text: label, size: AppTextScale.caption,
              color: kGreyTextColor, maxLines: 1,
              textOverflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
