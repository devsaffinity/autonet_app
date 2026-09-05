import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// The four-state renderer every buyer screen goes through.
///
/// The switch is exhaustive because [ViewState] is sealed: deleting the
/// [Failed] arm is a COMPILE ERROR, which is the only real enforcement of
/// DoD's 'every list screen handles loading / empty / error / data'. It reads
/// [Failed.message]/[Failed.retryable] — primitives — never `ApiError`, so no
/// widget in this tree imports `data/core/`.
///
/// CALLERS: [builder] runs inside THIS widget's `build`, NOT inside the `Obx`
/// closure that constructed the StateView, so an `Rx` read there sits outside
/// the tracking zone and registers no dependency — the subtree then never
/// rebuilds when that value lands. Read every Rx the subtree needs in the Obx
/// closure itself and pass the plain value down.
class StateView<T> extends StatelessWidget {
  const StateView({
    super.key,
    required this.state,
    required this.builder,
    required this.onRetry,
    this.emptyTitle,
    this.emptyBody,
    this.emptyAction,
  });

  final ViewState<T> state;
  final Widget Function(BuildContext, T) builder;
  final VoidCallback onRetry;

  /// Fallbacks used only when the controller's own [Empty] carried no copy.
  final String? emptyTitle;
  final String? emptyBody;

  /// Empty-state CTA slot — 'No requests yet' + a 'Request a part' button.
  final Widget? emptyAction;

  @override
  Widget build(BuildContext context) => switch (state) {
    Loading() => const Center(child: DiscreteCircleLoading()),
    Empty(:final title, :final body) => _EmptyStateView(
      title: title ?? emptyTitle ?? 'Nothing here yet',
      body: body ?? emptyBody,
      action: emptyAction,
    ),
    Failed(:final message, :final retryable) => _ErrorStateView(
      message: message,
      onRetry: retryable ? onRetry : null,
    ),
    Data(:final value) => builder(context, value),
  };
}

/// The centred column both private states below are built from.
Widget _panel(List<Widget> children) => Center(
  child: Padding(
    padding: AppSizes.DEFAULT,
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  ),
);

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({required this.title, this.body, this.action});

  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _panel([
    MyText(
      text: title,
      size: AppTextScale.subtitle,
      weight: AppWeights.semibold,
      color: kBlackColor,
      textAlign: TextAlign.center,
    ),
    if (body != null)
      MyText(
        text: body!,
        size: AppTextScale.body,
        color: kGreyTextColor,
        textAlign: TextAlign.center,
        paddingTop: AppSizes.s8,
      ),
    if (action != null)
      Padding(padding: const EdgeInsets.only(top: AppSizes.s20), child: action),
  ]);
}

/// [onRetry] is null when repeating the request cannot help (every 4xx). A
/// 'Try again' button on a 403 teaches the user that the button lies.
class _ErrorStateView extends StatelessWidget {
  const _ErrorStateView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _panel([
    const Icon(Icons.error_outline_rounded, size: AppSizes.s32, color: kRedColor),
    MyText(
      text: message,
      size: AppTextScale.body,
      color: kBlackColor,
      textAlign: TextAlign.center,
      paddingTop: AppSizes.s12,
    ),
    if (onRetry != null)
      Padding(
        padding: const EdgeInsets.only(top: AppSizes.s20),
        child: MyButton(
          buttonText: 'Try again',
          onTap: onRetry,
          fontSize: AppTextScale.body,
        ),
      ),
  ]);
}
