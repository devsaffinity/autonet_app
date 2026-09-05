import 'dart:convert';

import 'package:autonect/domain/request_draft.dart';
import 'package:autonect/services/session_store.dart';

/// ONE unfinished wizard per user id, so an OS-reclaimed app does not cost the
/// buyer their photos.
///
/// The whole reason this exists is the persisted S3 key: keys are single-use
/// (`RequestImage.s3Key @unique` -> P2002 -> 409), so losing them means five
/// re-uploads on a connection that was already bad enough to background the
/// app. Everything else in the draft is a bonus.
///
/// Static like [SessionStore], and delegating every prefs read and write to it,
/// because this is storage plumbing rather than an injected collaborator — the
/// test seam is SharedPreferences.setMockInitialValues, the same one
/// SessionStore already uses.
class RequestDraftStore {
  RequestDraftStore._();

  /// Stamps [draft].updatedAt with the WRITE time, not the construction time:
  /// the 24-hour restore window measures how long ago the buyer last touched
  /// the wizard, not when the object happened to be built.
  static void save(String userId, RequestDraft draft) {
    draft.updatedAt = DateTime.now();
    SessionStore.setRequestDraftJson(userId, jsonEncode(draft.toJson()));
  }

  /// Null when there is nothing to restore, when the draft is older than
  /// [RequestDraft.maxRestoreAge], or when the stored JSON is unreadable. In
  /// each of the last two cases the row is also DELETED — a draft that can
  /// never be restored must not sit in storage forever.
  ///
  /// Restoration is silent by design: the human decided against a resume
  /// prompt, and a draft this fresh is the screen the buyer expected to return
  /// to anyway.
  static RequestDraft? load(String userId) {
    final raw = SessionStore.requestDraftJson(userId);
    if (raw == null || raw.isEmpty) return null;
    RequestDraft draft;
    try {
      draft = RequestDraft.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      clear(userId);
      return null;
    }
    if (!draft.isRestorableAt(DateTime.now())) {
      clear(userId);
      return null;
    }
    return draft;
  }

  /// Call on a successful create. Keeping a submitted draft would offer to
  /// restore a request that already exists, and its keys are spent.
  static void clear(String userId) =>
      SessionStore.setRequestDraftJson(userId, null);
}
