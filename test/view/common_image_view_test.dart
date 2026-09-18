import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommonImageView effectiveCacheKey', () {
    test('strips ephemeral S3 presigned query parameters to object identity', () {
      final widget = CommonImageView(
        url: 'https://autonect-dev.s3.eu-west-2.amazonaws.com/avatars/user-1/uuid-aaa?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20260918T070000Z&X-Amz-Signature=sig1',
      );

      expect(
        widget.effectiveCacheKey,
        'https://autonect-dev.s3.eu-west-2.amazonaws.com/avatars/user-1/uuid-aaa',
      );
    });

    test('overrides caller user-id cacheKey on signed S3 URLs to prevent stale cache', () {
      final widget = CommonImageView(
        url: 'https://autonect-dev.s3.eu-west-2.amazonaws.com/avatars/user-1/uuid-aaa?X-Amz-Signature=sig1',
        cacheKey: 'user-1',
      );

      // Must NOT be 'user-1' — user ID never changes on profile update, which would freeze stale avatar
      expect(
        widget.effectiveCacheKey,
        'https://autonect-dev.s3.eu-west-2.amazonaws.com/avatars/user-1/uuid-aaa',
      );
    });

    test('matches cache key across different presigned signatures for the same image', () {
      final read1 = CommonImageView(
        url: 'https://autonect-dev.s3.eu-west-2.amazonaws.com/avatars/user-1/uuid-aaa?X-Amz-Date=20260918T070000Z&X-Amz-Signature=sig1',
      );
      final read2 = CommonImageView(
        url: 'https://autonect-dev.s3.eu-west-2.amazonaws.com/avatars/user-1/uuid-aaa?X-Amz-Date=20260918T071000Z&X-Amz-Signature=sig2',
      );

      expect(read1.effectiveCacheKey, read2.effectiveCacheKey);
    });

    test('automatically changes cache key when avatar UUID changes on update', () {
      final oldAvatar = CommonImageView(
        url: 'https://autonect-dev.s3.eu-west-2.amazonaws.com/avatars/user-1/uuid-old?X-Amz-Signature=sig1',
      );
      final newAvatar = CommonImageView(
        url: 'https://autonect-dev.s3.eu-west-2.amazonaws.com/avatars/user-1/uuid-new?X-Amz-Signature=sig2',
      );

      expect(oldAvatar.effectiveCacheKey, isNot(equals(newAvatar.effectiveCacheKey)));
    });

    test('preserves plain static URL without query params', () {
      final widget = CommonImageView(url: 'https://example.com/images/cat.png');
      expect(widget.effectiveCacheKey, 'https://example.com/images/cat.png');
    });

    test('honors explicit cacheKey when URL is not a presigned URL', () {
      final widget = CommonImageView(
        url: 'https://example.com/images/cat.png',
        cacheKey: 'requests/123/part.png',
      );
      expect(widget.effectiveCacheKey, 'requests/123/part.png');
    });

    test('returns null or fallback key when url is null or empty', () {
      expect(CommonImageView(url: null).effectiveCacheKey, isNull);
      expect(CommonImageView(url: '').effectiveCacheKey, isNull);
      expect(CommonImageView(url: null, cacheKey: 'custom').effectiveCacheKey, 'custom');
    });
  });
}
