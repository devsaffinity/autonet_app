import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/buyer/detail/review_page.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

// ── Status model
class _OrderStep {
  final String icon;
  final String title;
  final String subtitle;
  final String? description;
  final _StepState state;

  const _OrderStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.description,
    required this.state,
  });
}

enum _StepState { completed, inProgress, pending }

class OrderStatusPage extends StatelessWidget {
  /// Who fulfilled the order and what it was for. Carried so ReviewPage knows
  /// what the buyer is actually rating instead of asking about nothing.
  final String sellerName, partName;

  const OrderStatusPage({
    super.key,
    this.sellerName = 'AutoParts Hub',
    this.partName = 'Front Brake Pads',
  });

  // ── Change step states here to reflect real order status
  static final List<_OrderStep> _steps = [
    _OrderStep(
      icon: Assets.imagesStepperCompleted,
      title: 'Order Placed',
      subtitle: 'January 19, 2026 at 2:15 PM',
      description: 'Your order has been received and confirmed',
      state: _StepState.completed,
    ),
    _OrderStep(
      icon: Assets.imagesStepperPIcon,
      title: 'Preparing Order',
      subtitle: 'In progress...',
      description: 'Seller is preparing your part for delivery',
      // state: _StepState.inProgress,
      state: _StepState.inProgress,
    ),
    _OrderStep(
      icon: Assets.imagesStepperDeliverIcon,
      title: 'Out for Delivery',
      subtitle: 'Pending',
      description: null,
      state: _StepState.pending,
    ),
    _OrderStep(
      icon: Assets.imagesStepperDeliverIcon,
      title: 'Delivered',
      subtitle: 'Pending',
      description: null,
      state: _StepState.pending,
    ),
  ];

  // ── When all steps are completed show Give Review button
  bool get _isAllCompleted =>
      _steps.every((s) => s.state == _StepState.completed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "Order Status", centerdTitle: false),
      body: Column(
        children: [
          // ── Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _OrderProgressCard(steps: _steps),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Give Review button (only when all completed)
          // if (_isAllCompleted)
        ],
      ),
      bottomNavigationBar: NavButton(
        buttonText: "Give Review",
        onTap: () {
          Get.to(() => ReviewPage(sellerName: sellerName, partName: partName));
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order Progress Card
// ─────────────────────────────────────────────────────────────────────────────

class _OrderProgressCard extends StatelessWidget {
  final List<_OrderStep> steps;
  const _OrderProgressCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBlackColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          ...steps.asMap().entries.map((e) {
            final isLast = e.key == steps.length - 1;
            return _StepRow(step: e.value, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single Step Row
// ─────────────────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final _OrderStep step;
  final bool isLast;

  const _StepRow({required this.step, required this.isLast});

  Color get _circleColor {
    switch (step.state) {
      case _StepState.completed:
        return kSecondaryColor;
      case _StepState.inProgress:
        return kSecondaryColor;
      case _StepState.pending:
        return kPrimaryColor;
    }
  }

  Color get _iconColor {
    switch (step.state) {
      case _StepState.completed:
        return kWhiteColor;
      case _StepState.inProgress:
        return kWhiteColor;
      case _StepState.pending:
        return kGreyTextColor;
    }
  }

  Color get _borderColor {
    switch (step.state) {
      case _StepState.completed:
        return kSecondaryColor;
      case _StepState.inProgress:
        return kSecondaryColor;
      case _StepState.pending:
        return kGreyTextColor.withOpacity(0.4);
    }
  }

  Color get _lineColor {
    switch (step.state) {
      case _StepState.completed:
        return kSecondaryColor;
      case _StepState.inProgress:
        return kGreyTextColor.withOpacity(0.3);
      case _StepState.pending:
        return kGreyTextColor.withOpacity(0.3);
    }
  }

  Color get _titleColor {
    switch (step.state) {
      case _StepState.completed:
        return kBlackColor;
      case _StepState.inProgress:
        return kBlackColor;
      case _StepState.pending:
        return kGreyTextColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: circle + vertical line
          Column(
            children: [
              // Circle icon
              CommonImageView(
                height: 48,
                width: 48,
                imagePath: step.state == _StepState.completed
                    ? Assets.imagesStepperCompleted
                    : step.icon,
              ),

              // Vertical line (not shown for last step)
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

          // ── Right: text content
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
                  const SizedBox(height: 2),
                  MyText(text: step.subtitle, size: 12, color: kGreyTextColor),
                  if (step.description != null) ...[
                    const SizedBox(height: 4),
                    MyText(
                      text: step.description!,
                      size: 12,
                      color: kGreyTextColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
