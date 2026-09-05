/// THE single source of failure copy and retry affordance for the whole app.
///
/// It lives in `lib/domain/` rather than in a controller because both the
/// controllers (which route a failure) and `ViewState.Failed` (which a widget
/// reads) need it, and neither of those layers may import the other.
library;

import 'package:autonect/data/core/api_error.dart';

/// What `ApiController.run` returns when it DROPS a re-entrant call.
///
/// It lives HERE, beside the two functions that decide how a failure reads,
/// because it is the one 'failure' that is not one: nothing was sent, nothing
/// broke, and the identical request succeeds the moment the in-flight one
/// finishes. It carries [ApiErrorCode.unknown] — there is no wire code for
/// 'never left the device' — which is exactly why [isRetryable] must special-
/// case it rather than read the code.
const ApiError droppedReentry = ApiError(
  code: ApiErrorCode.unknown,
  message: 'Please wait for the current action to finish.',
);

/// Friendly copy for the client-only codes; the server's own prose for
/// everything that came off the wire.
///
/// WHY defer to the server: the backend writes its 4xx messages for the end
/// user ('Request is not open (or not yours)', 'Order cannot be cancelled at
/// PREPARING'), and re-writing them here would create a second copy deck that
/// drifts the moment a message changes.
String userMessageFor(ApiError e) {
  switch (e.code) {
    case ApiErrorCode.network:
      return 'No internet connection. Check your network and try again.';
    case ApiErrorCode.timeout:
      return 'That took longer than expected. Please try again.';
    case ApiErrorCode.malformedResponse:
      return 'We could not read the response from the server. Please try again.';
    case ApiErrorCode.sessionExpired:
      return 'Your session expired. Please log in again.';
    default:
      final m = e.message.trim();
      return m.isEmpty ? 'Something went wrong. Please try again.' : m;
  }
}

/// Whether to OFFER a retry button at all.
///
/// True only where repeating the identical request can plausibly succeed.
/// Every 4xx is excluded on purpose: a 'Try again' button on a 403 or a 409
/// teaches the user that the button lies, and a 400 fails identically until the
/// input changes.
///
/// NOTE on [ApiErrorCode.rateLimited]: it is retryable, but the caller MUST
/// suppress the button for ~30s before showing it. The global limiter is
/// 300 requests / 60s, so an immediate blind retry deepens the very condition
/// it is trying to escape.
bool isRetryable(ApiError e) {
  // THE LAST LINE OF DEFENCE. Every idempotent read now supersedes rather than
  // being dropped, so this should be unreachable from a read — but a caller
  // that paints a dropped re-entry as Failed must never produce a dead panel
  // with no way out, whatever else changes above it. Identity, not equality:
  // this is the one instance `run` hands back, unwrapped, unmodified.
  if (identical(e, droppedReentry)) return true;
  switch (e.code) {
    case ApiErrorCode.network:
    case ApiErrorCode.timeout:
    case ApiErrorCode.internal:
    case ApiErrorCode.rateLimited:
      return true;
    default:
      return false;
  }
}
