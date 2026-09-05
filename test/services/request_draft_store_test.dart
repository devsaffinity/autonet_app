import 'dart:convert';

import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/pending_image.dart';
import 'package:autonect/domain/request_draft.dart';
import 'package:autonect/services/request_draft_store.dart';
import 'package:autonect/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SessionStore.init();
  });

  RequestDraft draftWithKey() => RequestDraft(
    regNumber: 'LM19XYZ',
    categoryId: 'cat_brakes',
    categoryName: 'Brakes',
    region: Region.london,
    partName: 'Front brake discs',
    condition: PartCondition.either,
    urgency: RequestUrgency.standard,
    step: 2,
    images: [
      PendingImage(
        localId: 'a',
        path: '/tmp/a.jpg',
        sizeBytes: 1234,
        contentType: 'image/jpeg',
        status: ImageUploadStatus.uploaded,
        s3Key: 'requests/usr_buyer/aaa.jpg',
      ),
    ],
  );

  test('round-trips the draft, s3Key included', () {
    RequestDraftStore.save('usr_buyer', draftWithKey());
    final back = RequestDraftStore.load('usr_buyer')!;

    expect(back.regNumber, 'LM19XYZ');
    expect(back.categoryId, 'cat_brakes');
    expect(back.categoryName, 'Brakes');
    expect(back.region, Region.london);
    expect(back.condition, PartCondition.either);
    expect(back.step, 2);
    // THE point of the whole store: S3 keys are single-use, so losing one costs
    // a re-upload that the server would answer with a 409.
    expect(back.images.single.s3Key, 'requests/usr_buyer/aaa.jpg');
    expect(back.images.single.status, ImageUploadStatus.uploaded);
    expect(back.uploadedKeys, ['requests/usr_buyer/aaa.jpg']);
  });

  test('a draft older than the restore window is dropped, not returned', () {
    RequestDraftStore.save('usr_buyer', draftWithKey());
    final stale = RequestDraftStore.load('usr_buyer')!
      ..updatedAt = DateTime.now().subtract(const Duration(hours: 25));
    // Written straight through SessionStore: save() stamps the write time, so
    // it is the only way to plant an old row.
    SessionStore.setRequestDraftJson('usr_buyer', _encode(stale));

    expect(RequestDraftStore.load('usr_buyer'), isNull);
    // And it is deleted, not merely hidden.
    expect(SessionStore.requestDraftJson('usr_buyer'), isNull);
  });

  test('a draft just inside the window still restores', () {
    final fresh = draftWithKey()
      ..updatedAt = DateTime.now().subtract(const Duration(hours: 23));
    SessionStore.setRequestDraftJson('usr_buyer', _encode(fresh));
    expect(RequestDraftStore.load('usr_buyer'), isNotNull);
  });

  test('one draft per user id — B can never see A', () {
    RequestDraftStore.save('usr_a', draftWithKey());
    expect(RequestDraftStore.load('usr_b'), isNull);
    RequestDraftStore.save('usr_b', draftWithKey()..partName = 'Wing mirror');
    expect(RequestDraftStore.load('usr_a')!.partName, 'Front brake discs');
    expect(RequestDraftStore.load('usr_b')!.partName, 'Wing mirror');
  });

  test('the draft SURVIVES a forced sign-out', () {
    RequestDraftStore.save('usr_buyer', draftWithKey());
    SessionStore.clearSession();
    // A revoked refresh token is not the buyer abandoning half a request, and
    // the per-user key means the next account on this device cannot see it.
    expect(RequestDraftStore.load('usr_buyer'), isNotNull);
    expect(SessionStore.loggedIn, isFalse);
  });

  test('clear removes the row', () {
    RequestDraftStore.save('usr_buyer', draftWithKey());
    RequestDraftStore.clear('usr_buyer');
    expect(RequestDraftStore.load('usr_buyer'), isNull);
  });

  test('unreadable JSON degrades to null and is swept', () {
    SessionStore.setRequestDraftJson('usr_buyer', '{not json');
    expect(RequestDraftStore.load('usr_buyer'), isNull);
    expect(SessionStore.requestDraftJson('usr_buyer'), isNull);
  });
}

String _encode(RequestDraft d) => jsonEncode(d.toJson());
