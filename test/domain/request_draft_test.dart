import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/domain/pending_image.dart';
import 'package:autonect/domain/request_draft.dart';
import 'package:flutter_test/flutter_test.dart';

RequestDraft validDraft() => RequestDraft(
  regNumber: 'lm19 xyz',
  categoryId: 'cat_brakes',
  categoryName: 'Brakes',
  region: Region.london,
  partName: 'Front brake discs',
  condition: PartCondition.either,
  urgency: RequestUrgency.standard,
);

PendingImage image(String id, ImageUploadStatus status, {String? key}) =>
    PendingImage(
      localId: id,
      path: '/tmp/$id.jpg',
      sizeBytes: 1024,
      contentType: 'image/jpeg',
      status: status,
      s3Key: key,
    );

void main() {
  group('validate', () {
    test('a complete draft has no errors', () {
      expect(validDraft().validate(), isEmpty);
    });

    test('keys are the SERVER\'S OWN paths, so server errors merge in', () {
      final d = RequestDraft(regNumber: 'x', partName: 'a');
      expect(
        d.validate().keys.toSet(),
        {'regNumber', 'categoryId', 'region', 'partName', 'condition', 'urgency'},
      );
    });

    test('partNumber is only bounded when it is non-blank', () {
      final d = validDraft()..partNumber = '   ';
      expect(d.validate(), isEmpty);
      d.partNumber = 'x' * 81;
      expect(d.validate().keys, contains('partNumber'));
    });

    test('length ceilings mirror the zod schema', () {
      final d = validDraft()..partName = 'x' * 151;
      expect(d.validate().keys, contains('partName'));
      d.partName = 'Discs';
      d.description = 'x' * 2001;
      expect(d.validate().keys, contains('description'));
    });

    test('vehicleModel is required only when the lookup demanded it', () {
      final d = validDraft();
      expect(d.validate(), isEmpty);
      d.manualModelRequired = true;
      expect(d.validate().keys, contains('vehicleModel'));
      d.vehicleModel = '320d';
      expect(d.validate(), isEmpty);
    });
  });

  group('toBody', () {
    test('normalises the reg and emits the wire enums the UI cannot type', () {
      final body = validDraft().toBody();
      expect(body['regNumber'], 'LM19XYZ');
      expect(body['condition'], 'EITHER');
      expect(body['urgency'], 'STANDARD');
      expect(body['region'], 'LONDON');
      expect(body['categoryId'], 'cat_brakes');
    });

    test('OMITS partNumber and description when blank', () {
      final d = validDraft()
        ..partNumber = '   '
        ..description = '';
      final body = d.toBody();
      expect(body.containsKey('partNumber'), isFalse);
      expect(body.containsKey('description'), isFalse);
    });

    test('sends trimmed partNumber and description when present', () {
      final d = validDraft()
        ..partNumber = '  34116794300 '
        ..description = ' Pair, front axle ';
      final body = d.toBody();
      expect(body['partNumber'], '34116794300');
      expect(body['description'], 'Pair, front axle');
    });

    test('ALWAYS sends imageKeys, including as an empty list', () {
      expect(validDraft().toBody()['imageKeys'], <String>[]);
    });

    test('only uploaded images contribute a key', () {
      final d = validDraft()
        ..images = [
          image('a', ImageUploadStatus.uploaded, key: 'requests/u/a.jpg'),
          image('b', ImageUploadStatus.failed, key: 'requests/u/b.jpg'),
          image('c', ImageUploadStatus.queued),
          image('d', ImageUploadStatus.uploaded, key: 'requests/u/d.jpg'),
        ];
      expect(d.toBody()['imageKeys'], [
        'requests/u/a.jpg',
        'requests/u/d.jpg',
      ]);
    });

    test('vehicleModel goes ONLY when the human typed it', () {
      final d = validDraft()..vehicleModel = '320d';
      expect(d.toBody().containsKey('vehicleModel'), isFalse,
          reason: 'it would overwrite the shared vehicle row');
      d.manualModelRequired = true;
      expect(d.toBody()['vehicleModel'], '320d');
    });

    test('an invalid draft throws rather than posting a guaranteed 400', () {
      expect(RequestDraft().toBody, throwsStateError);
    });
  });

  group('persistence', () {
    test('a round trip keeps the S3 keys that make backgrounding free', () {
      final d = validDraft()
        ..partNumber = '34116794300'
        ..description = 'Pair'
        ..manualModelRequired = true
        ..vehicleModel = '320d'
        ..step = 2
        ..images = [
          image('a', ImageUploadStatus.uploaded, key: 'requests/u/a.jpg'),
          image('b', ImageUploadStatus.queued),
        ];
      final restored = RequestDraft.fromJson(d.toJson());
      expect(restored.regNumber, d.regNumber);
      expect(restored.categoryId, 'cat_brakes');
      expect(restored.categoryName, 'Brakes');
      expect(restored.region, Region.london);
      expect(restored.condition, PartCondition.either);
      expect(restored.urgency, RequestUrgency.standard);
      expect(restored.manualModelRequired, isTrue);
      expect(restored.vehicleModel, '320d');
      expect(restored.step, 2);
      expect(restored.images.map((i) => i.s3Key).toList(), [
        'requests/u/a.jpg',
        null,
      ]);
      expect(restored.toBody(), d.toBody());
    });

    test('an in-flight upload comes back queued — nothing survives a restart',
        () {
      final json = image('a', ImageUploadStatus.uploading).toJson();
      expect(PendingImage.fromJson(json).status, ImageUploadStatus.queued);
    });

    test('image bytes are never persisted', () {
      final img = image('a', ImageUploadStatus.queued)..bytes = [1, 2, 3];
      expect(img.toJson().containsKey('bytes'), isFalse);
      expect(PendingImage.fromJson(img.toJson()).bytes, isNull);
    });

    test('a stale draft is not restorable', () {
      final now = DateTime.utc(2026, 9, 4, 12);
      final fresh = validDraft()..updatedAt = now.subtract(const Duration(hours: 23));
      final stale = validDraft()..updatedAt = now.subtract(const Duration(hours: 25));
      expect(fresh.isRestorableAt(now), isTrue);
      expect(stale.isRestorableAt(now), isFalse);
    });
  });
}
