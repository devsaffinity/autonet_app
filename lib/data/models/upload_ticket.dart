import 'package:autonect/data/models/auth_user.dart' show jsonString;

/// `POST /v1/requests/image-url` — exactly the wire shape returned by
/// StorageProvider.createUploadUrl.
///
/// No issue time is baked in: the uploader owns the clock, which keeps expiry
/// logic testable without a fake DateTime inside the model.
class UploadTicket {
  const UploadTicket({
    required this.key,
    required this.url,
    required this.expiresInSec,
  });

  /// The S3 object key. Single-use: RequestImage.s3Key is @unique, so replaying
  /// a key on a second create is a P2002 → 409.
  final String key;
  final String url;
  final int expiresInSec;

  factory UploadTicket.fromJson(Map<String, dynamic> j) => UploadTicket(
    key: jsonString(j, 'key'),
    url: jsonString(j, 'url'),
    expiresInSec: (j['expiresInSec'] as num?)?.toInt() ?? 0,
  );
}
