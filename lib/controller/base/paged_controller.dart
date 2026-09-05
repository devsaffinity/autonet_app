import 'dart:async';

import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/page_meta.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Every buyer list screen's pagination, once. DoD forbids "silent
/// first-page-only", and the guard in [loadMore] is what makes that
/// unrepresentable rather than merely unlikely.
///
/// THE INVARIANT every guard below serves: THE RENDERED ROWS ALWAYS
/// CORRESPOND TO THE CURRENT FILTER, and the paging cursor ([_page], [_meta])
/// always describes the rendered rows.
///
/// Page 1 and page 2+ are BOTH read asynchronously and either can answer after
/// the buyer has moved the chip or pulled to refresh, so both tag their
/// dispatch with [_generation] and both throw a stale answer away WHOLE — rows,
/// cursor and error alike. Discarding only the rows would still leave [_page]
/// counting a page the list never showed, which no amount of further scrolling
/// can repair.
abstract class PagedController<T> extends ApiController {
  PagedController({super.toast, super.showBusy, super.hideBusy});

  final Rx<ViewState<List<T>>> state = Rx<ViewState<List<T>>>(Loading<List<T>>());

  /// Separate from [busy]: the footer spinner is not the modal dialog, and a
  /// page-2 fetch must not gate the pull-to-refresh latch.
  final RxBool loadingMore = false.obs;

  /// A page-2+ failure NEVER becomes [Failed]. Blanking a good list because
  /// page 3 timed out costs the user everything they had already scrolled.
  final Rxn<ApiError> loadMoreError = Rxn<ApiError>();

  PageMeta _meta = PageMeta.empty;
  int _page = 1;

  /// The newest read the user has asked for, page 1 and page 2+ alike. Same
  /// idiom as ApiClient's token generation: a response tagged with an older
  /// generation is DISCARDED on arrival, because its rows were fetched for a
  /// filter the buyer has since left and rendering them under the new chip
  /// would be the screen lying about where its rows came from.
  int _generation = 0;

  /// The page-1 read currently in flight, or null between reads.
  ///
  /// [ApiController.run] DROPS a second call while one is in flight. That is
  /// the right guard for a double-tapped submit button and the wrong one for a
  /// chip row: the drop surfaces a non-retryable 'please wait' and no fetch is
  /// ever issued for the chip now highlighted. So the paged path QUEUES behind
  /// the in-flight read rather than entering [ApiController.run] busy — run's
  /// own global contract is untouched.
  Future<void>? _inFlight;

  bool get hasMore => _meta.hasNextPage;

  Future<ApiResult<Paged<T>>> fetchPage(int page);

  /// De-duplication key. Ordering is createdAt-desc, so a row created between
  /// two page reads shifts every later row down one and would otherwise appear
  /// twice.
  String idOf(T item);

  List<T> get _loaded => switch (state.value) {
    Data<List<T>>(:final value) => value,
    _ => const [],
  };

  /// Rows and cursor are blanked TOGETHER. A cursor left describing rows that
  /// are no longer on screen is exactly the corruption this class exists to
  /// prevent, so there is no path that clears one without the other.
  void _blank() {
    state.value = Loading<List<T>>();
    _meta = PageMeta.empty;
    _page = 1;
  }

  /// Page 1. Always [silent]: the list's own ViewState renders progress, and a
  /// modal dialog over a skeleton is two loading indicators for one wait.
  ///
  /// THE LAST CALLER WINS. An earlier read still in flight is waited out and
  /// its answer thrown away; a caller that is itself superseded while waiting
  /// hands the re-issue to the newer one and never fetches at all, so N taps
  /// cost at most two round trips and settle on the Nth tap's rows.
  Future<void> refreshFirst() async {
    final generation = ++_generation;
    // This bump also supersedes any page-2+ read in flight — pull-to-refresh
    // resets the cursor to page 1, so a page-2 answer merging in behind it
    // would corrupt the cursor just as a chip change would. Its footer spinner
    // and its error belong to that discarded read, so they go now rather than
    // when it answers: nothing else will clear them, since its own completion
    // path is about to become a no-op.
    loadingMore.value = false;
    loadMoreError.value = null;
    if (state.value is! Data<List<T>>) _blank();

    while (_inFlight != null) {
      await _inFlight;
      // A newer tap landed while we waited; it will do the re-issue, and its
      // filter — not ours — is the one on screen.
      if (generation != _generation) return;
    }

    final done = Completer<void>();
    _inFlight = done.future;
    try {
      await run<Paged<T>, void>(null, () => fetchPage(1), (r) {
        if (generation != _generation) return;
        switch (r) {
          case Err(:final error):
            state.value = Failed<List<T>>(error);
          case Ok(:final value):
            _meta = value.meta;
            _page = 1;
            // `total` is authoritative and is computed in the same transaction
            // as the page; an empty `items` on a non-zero total means the page
            // index ran past the end, which is a different bug and not an
            // empty list.
            state.value = value.meta.total == 0
                ? Empty<List<T>>()
                : Data<List<T>>(value.items);
        }
      }, silent: true);
    } finally {
      // BOTH branches: a throw that left this latch set would wedge every
      // later refresh in the wait loop above forever.
      _inFlight = null;
      done.complete();
    }
  }

  /// Page 1 after the filter chip moved.
  ///
  /// Unlike pull-to-refresh this BLANKS the list first. Keeping the previous
  /// filter's rows under the newly highlighted chip — even for the length of
  /// one round trip — is the screen telling the buyer something untrue about
  /// which filter produced them.
  @protected
  Future<void> refreshForFilter() {
    _blank();
    return refreshFirst();
  }

  /// Page 2+, appended to the rows already on screen.
  Future<void> loadMore() async {
    if (busy.value || loadingMore.value || !hasMore) return;
    // Not an optimisation: while a page-1 read is in flight, or while the list
    // is blank, there are no rendered rows for a page 2 to extend — appending
    // to nothing would invent a list the cursor does not describe.
    if (_inFlight != null || state.value is! Data<List<T>>) return;

    final generation = _generation;
    final page = _page + 1;
    loadingMore.value = true;
    loadMoreError.value = null;
    try {
      final r = await fetchPage(page);
      // Superseded while in flight: a newer page-1 read owns the list, its
      // cursor and its error slot now. Return BEFORE touching any of the three.
      if (generation != _generation) return;
      switch (r) {
        case Err(:final error):
          loadMoreError.value = error;
        case Ok(:final value):
          _meta = value.meta;
          _page = page;
          state.value = Data<List<T>>(_merge(_loaded, value.items));
      }
    } finally {
      // ONLY the read that still owns the list clears the latch. The newer
      // [refreshFirst] already cleared it at the bump, and a newer loadMore may
      // have set it again since — a stale response clearing it there would let
      // two page reads run at once. A stuck-true spinner is impossible either
      // way: every path that abandons a loadMore clears the latch first.
      if (generation == _generation) loadingMore.value = false;
    }
  }

  List<T> _merge(List<T> existing, List<T> incoming) {
    final seen = {for (final e in existing) idOf(e)};
    return [
      ...existing,
      for (final i in incoming)
        if (seen.add(idOf(i))) i,
    ];
  }
}
