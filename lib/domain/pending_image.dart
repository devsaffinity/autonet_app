/// One image slot in the new-request wizard, from picked file to S3 key.
library;

enum ImageUploadStatus { queued, uploading, uploaded, failed }

class PendingImage {
  PendingImage({
    required this.localId,
    required this.path,
    required this.sizeBytes,
    required this.contentType,
    this.bytes,
    this.status = ImageUploadStatus.queued,
    this.s3Key,
    this.errorMessage,
  });

  final String localId;
  final String path;

  /// Deliberately NOT persisted — up to 5 MB per image, and the file at [path]
  /// is still on disk when the draft is restored.
  List<int>? bytes;

  final int sizeBytes;
  final String contentType;
  ImageUploadStatus status;

  /// Persisting this is the entire point of the draft. S3 keys are single-use
  /// (`RequestImage.s3Key @unique` -> P2002 -> 409), so losing it after the OS
  /// reclaims the wizard forces a full re-upload of every image.
  String? s3Key;
  String? errorMessage;

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'path': path,
    'sizeBytes': sizeBytes,
    'contentType': contentType,
    'status': status.name,
    if (s3Key != null) 's3Key': s3Key,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory PendingImage.fromJson(Map<String, dynamic> j) => PendingImage(
    localId: (j['localId'] as String?) ?? '',
    path: (j['path'] as String?) ?? '',
    sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
    contentType: (j['contentType'] as String?) ?? '',
    status: _statusFrom(j['status'] as String?),
    s3Key: j['s3Key'] as String?,
    errorMessage: j['errorMessage'] as String?,
  );

  /// A persisted `uploading` means the process died mid-PUT, so it comes back
  /// as `queued`: nothing is in flight after a restart.
  static ImageUploadStatus _statusFrom(String? v) {
    for (final s in ImageUploadStatus.values) {
      if (s.name == v) {
        return s == ImageUploadStatus.uploading ? ImageUploadStatus.queued : s;
      }
    }
    return ImageUploadStatus.queued;
  }
}
