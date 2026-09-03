import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Supplier-side order stepper.
///
/// Visually identical to the buyer's `_OrderProgressCard` in
/// buyer/detail/order_status.dart — same stepper assets, same 48px circles,
/// same vertical rule. The binding spec promotes that widget to
/// lib/view/widget/order_progress_card.dart as `OrderProgressCard`; that file
/// lives outside this agent's owned directory, so the supplier tree carries its
/// own copy for now. Swap the import once the shared widget lands.
enum SupplierStepState { completed, inProgress, pending }

class SupplierOrderStep {
  final String icon;
  final String title;
  final String subtitle;
  final SupplierStepState state;
  const SupplierOrderStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
  });
}

class SupplierOrderProgress extends StatelessWidget {
  final List<SupplierOrderStep> steps;
  const SupplierOrderProgress({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return SupplierCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'Order Progress',
            size: 15,
            weight: FontWeight.w700,
            color: kBlackColor,
            paddingBottom: 16,
          ),
          ...steps.asMap().entries.map(
            (e) =>
                _StepRow(step: e.value, isLast: e.key == steps.length - 1),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final SupplierOrderStep step;
  final bool isLast;
  const _StepRow({required this.step, required this.isLast});

  Color get _lineColor => step.state == SupplierStepState.completed
      ? kSecondaryColor
      : kGreyTextColor.withValues(alpha: 0.3);

  Color get _titleColor => step.state == SupplierStepState.pending
      ? kGreyTextColor
      : kBlackColor;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CommonImageView(
                height: 48,
                width: 48,
                imagePath: step.state == SupplierStepState.completed
                    ? Assets.imagesStepperCompleted
                    : step.icon,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: _lineColor,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  MyText(
                    text: step.title,
                    size: 14,
                    weight: FontWeight.w700,
                    color: _titleColor,
                  ),
                  MyText(
                    paddingTop: 2,
                    text: step.subtitle,
                    size: 12,
                    color: kGreyTextColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
