import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/state_view.dart';
import 'package:flutter/material.dart';

/// Every buyer list is this widget. It owns THE scroll controller, so no
/// screen writes a scroll listener and no screen forgets to dispose one.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key, required this.state, required this.loadingMore,
    required this.loadMoreError, required this.hasMore,
    required this.onLoadMore, required this.onRefresh,
    required this.itemBuilder, this.emptyAction,
    this.emptyTitle, this.emptyBody,
  });

  final ViewState<List<T>> state;
  final bool loadingMore, hasMore;
  final String? loadMoreError;
  final VoidCallback onLoadMore, onRefresh;
  final Widget Function(BuildContext, T) itemBuilder;

  /// Forwarded to [StateView] so an empty list can offer its CTA.
  final Widget? emptyAction;

  /// Fallback empty copy, used only when the controller's own [Empty] carried
  /// none. StateView has always accepted these; PagedListView simply never
  /// forwarded them, so every paged screen fell back to 'Nothing here yet'
  /// even where a filter was what emptied the list.
  final String? emptyTitle, emptyBody;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  /// Created here rather than in initState so the listener attaches exactly
  /// once, at the same place it is torn down below.
  late final ScrollController _controller = ScrollController()
    ..addListener(_onScroll);

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  /// Fires at 80% of the extent, and is suppressed while a page is in flight
  /// and after a failure — a stuck list must not hammer the global limiter.
  void _onScroll() {
    if (!widget.hasMore || widget.loadingMore) return;
    if (widget.loadMoreError != null || !_controller.hasClients) return;
    final p = _controller.position;
    if (p.pixels >= p.maxScrollExtent * 0.8) widget.onLoadMore();
  }

  Widget? get _footer {
    const pad = EdgeInsets.symmetric(vertical: AppSizes.s16);
    if (widget.loadingMore) {
      return const Padding(padding: pad,
          child: Center(child: DiscreteCircleLoading(size: AppSizes.s24)));
    }
    final err = widget.loadMoreError;
    if (err == null) return null;
    return Padding(
      padding: pad,
      child: Column(children: [
        MyText(text: err, size: AppTextScale.label, color: kGreyTextColor,
            textAlign: TextAlign.center),
        MyText(text: 'Retry loading more', size: AppTextScale.body,
            weight: AppWeights.semibold, color: kSecondaryColor,
            paddingTop: AppSizes.s8, onTap: widget.onLoadMore),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kSecondaryColor,
      onRefresh: () async => widget.onRefresh(),
      child: StateView<List<T>>(
        state: widget.state,
        onRetry: widget.onRefresh,
        emptyAction: widget.emptyAction,
        emptyTitle: widget.emptyTitle,
        emptyBody: widget.emptyBody,
        // No header slot on purpose. One used to exist, and because it could
        // only be painted here — inside the Data arm — a screen that put its
        // filter chips in it lost them the moment a filter came back empty.
        // Chrome that must outlive the four states belongs in a Column above
        // this widget, never inside it.
        builder: (context, items) {
          final footer = _footer;
          return ListView.builder(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSizes.DEFAULT,
            itemCount: items.length + (footer == null ? 0 : 1),
            itemBuilder: (context, i) {
              if (i >= items.length) return footer!;
              return widget.itemBuilder(context, items[i]);
            },
          );
        },
      ),
    );
  }
}
