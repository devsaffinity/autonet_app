/// `lib/domain/` — a layer the standard's §4 directory listing does not name.
///
/// WHY IT EXISTS: §4 says 'a widget that imports core/ directly is a defect'
/// AND mandates one-way `view -> controller -> repository -> core`. The
/// four-state type must be visible to BOTH widgets and controllers, so placing
/// it in `data/core/` breaks the first rule and placing it in `view/widget/`
/// breaks the second (a controller would then import the view layer).
///
/// The layer is PURE DART. It may import `lib/data/models/**` and
/// `lib/data/core/api_error.dart` and nothing else — no `package:flutter/*`,
/// no `package:get/*`, no HTTP. Every test over it runs with no widget pump.
library;

import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/domain/failure_copy.dart';

/// The four states DoD requires of every list screen.
///
/// Sealed is the whole point: a `switch` in a widget that forgets [Failed] is a
/// COMPILE ERROR, which is the only mechanism that actually enforces
/// 'every list screen handles four states'.
///
/// Named [Data]/[Failed] rather than Success/Error so they do not collide with
/// `ApiResult`'s existing `Ok`/`Err` at a call site that holds both.
sealed class ViewState<T> {
  const ViewState();
}

final class Loading<T> extends ViewState<T> {
  const Loading();
}

/// A successful load that returned nothing. [title] and [body] are optional so
/// a screen can say 'No offers yet' rather than show a generic blank.
final class Empty<T> extends ViewState<T> {
  const Empty([this.title, this.body]);

  final String? title;
  final String? body;
}

/// Widgets read [message] / [retryable] and NEVER [error]; that is what keeps
/// `data/core/` out of the view layer's imports.
final class Failed<T> extends ViewState<T> {
  const Failed(this.error);

  final ApiError error;

  String get message => userMessageFor(error);

  bool get retryable => isRetryable(error);

  /// The one failure a screen must not merely display — the shell logs out.
  bool get isSessionExpired => error.code == ApiErrorCode.sessionExpired;
}

final class Data<T> extends ViewState<T> {
  const Data(this.value);

  final T value;
}
