import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/domain/order_steps.dart';
import 'package:autonect/view/widget/app_card.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

const double _marker = AppSizes.s24, _rail = 2;

/// THE order stepper. It replaces both pre-existing copies and owns NO mapping
/// logic: `buildOrderSteps` in lib/domain decides the phases, this paints them.
class OrderProgressCard extends StatelessWidget {
  const OrderProgressCard({super.key, required this.steps});

  final List<OrderStep> steps;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    ),
  );
}

Color _colorOf(StepPhase p) => switch (p) {
  StepPhase.done => kSuccessColor,
  StepPhase.current => kSecondaryColor,
  StepPhase.pending => kGreyTextColor,
  StepPhase.skipped => kGreyTextColor,
  StepPhase.cancelled => kRedColor,
};

/// WHY `skipped` gets its own copy: an admin can force PLACED -> DELIVERED, so
/// this row's status never happened. Painting a tick would assert a completion
/// the backend never produced; painting it `pending` behind a delivered head
/// would be incoherent. It says, truthfully, that nothing was recorded.
String? _subtitleOf(OrderStep step) =>
    step.phase == StepPhase.skipped ? (step.subtitle ?? 'Not recorded') : step.subtitle;

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final OrderStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(step.phase);
    final subtitle = _subtitleOf(step);
    final muted = step.phase == StepPhase.pending || step.phase == StepPhase.skipped;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _Marker(phase: step.phase, color: color),
              if (!isLast)
                Expanded(child: Container(width: _rail, color: kTertiaryColor)),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: AppSizes.s12, bottom: AppSizes.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: step.title,
                    size: AppTextScale.body,
                    weight: step.phase == StepPhase.current
                        ? AppWeights.bold
                        : AppWeights.semibold,
                    color: muted ? kGreyTextColor : color,
                  ),
                  if (subtitle != null)
                    MyText(text: subtitle, size: AppTextScale.label,
                        color: kGreyTextColor, paddingTop: AppSizes.s4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// All five phases are drawn here and only [StepPhase.done] draws a tick.
class _Marker extends StatelessWidget {
  const _Marker({required this.phase, required this.color});

  final StepPhase phase;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Shipped and referenced by nothing before this phase.
    if (phase == StepPhase.pending) {
      return CommonImageView(
        imagePath: Assets.imagesStepperPendingIcon,
        height: _marker,
        width: _marker,
        fit: BoxFit.contain,
      );
    }
    final filled = phase == StepPhase.done || phase == StepPhase.cancelled;
    return Container(
      width: _marker,
      height: _marker,
      decoration: BoxDecoration(
        color: filled ? color : kWhiteColor,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: _rail),
      ),
      child: switch (phase) {
        StepPhase.done => const Icon(Icons.check_rounded,
            size: AppSizes.s12, color: kWhiteColor),
        StepPhase.cancelled => const Icon(Icons.close_rounded,
            size: AppSizes.s12, color: kWhiteColor),
        StepPhase.skipped => const Icon(Icons.remove_rounded,
            size: AppSizes.s12, color: kGreyTextColor),
        StepPhase.current || StepPhase.pending => const SizedBox.shrink(),
      },
    );
  }
}
