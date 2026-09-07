import 'package:autonect/data/models/me_profile.dart' show KycStatus;
import 'package:autonect/data/models/request_enums.dart' show enumFromWire;

/// Re-exported so a caller importing this file gets the status enum too.
export 'package:autonect/data/models/me_profile.dart' show KycStatus;


/// The three documents a SUPPLIER must upload, and the two an ELECTRICIAN must.
///
/// Wire values come straight from the backend `KycDocType` enum. The labels are
/// the design's card titles.
enum KycDocType {
  id('ID', 'ID Verification', "Government issued Passport or Driver's License"),
  businessRegistry(
    'BUSINESS_REGISTRY',
    'Business Registry',
    'Companies House certificate',
  ),
  tax('TAX', 'Tax Documents', 'VAT registration certificate'),
  license('LICENSE', 'Licence', 'Trade or installer licence');

  const KycDocType(this.wire, this.label, this.hint);
  final String wire;
  final String label;

  /// The card's grey subtitle. The design said "Articles of Incorporation" and
  /// "VAT / EIN Certification" — both US/Canadian instruments on a UK-only
  /// system, which would send a British supplier looking for paperwork that
  /// does not exist here.
  final String hint;

  static KycDocType? fromWire(String? v) =>
      enumFromWire(values, v, (e) => e.wire);
}

/// One row of `documents` in the KYC status payload.
class KycDocument {
  const KycDocument({
    required this.type,
    required this.uploaded,
    this.fileName,
    this.sizeBytes,
    this.mimeType,
    this.uploadedAt,
  });

  final KycDocType type;
  final bool uploaded;

  /// Null on documents uploaded before the server recorded metadata, so the
  /// screen falls back to the document type rather than rendering a blank row.
  final String? fileName;
  final int? sizeBytes;
  final String? mimeType;
  final DateTime? uploadedAt;

  /// '2.4 MB', matching the design. Null when the server has no size.
  String? get displaySize {
    final b = sizeBytes;
    if (b == null || b <= 0) return null;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static KycDocument? tryFromJson(Map<String, dynamic> j) {
    // An unknown document type is DROPPED rather than fatal: the server adding
    // a fourth type must not break the screen for everyone on an older build.
    final type = KycDocType.fromWire(j['type'] as String?);
    if (type == null) return null;
    final at = j['uploadedAt'];
    return KycDocument(
      type: type,
      uploaded: j['uploaded'] == true,
      fileName: j['fileName'] as String?,
      sizeBytes: (j['sizeBytes'] as num?)?.toInt(),
      mimeType: j['mimeType'] as String?,
      uploadedAt: at is String ? DateTime.tryParse(at) : null,
    );
  }
}

/// `GET /v1/kyc/status`, and the response of every KYC write.
class KycState {
  const KycState({
    required this.kycStatus,
    required this.approved,
    required this.requiredDocuments,
    required this.documents,
  });

  /// Null when the server sent a status this build does not know. Treated as
  /// not-submitted everywhere, never as approved.
  final KycStatus? kycStatus;
  final bool approved;
  final List<KycDocType> requiredDocuments;
  final List<KycDocument> documents;

  KycDocument? documentFor(KycDocType type) {
    for (final d in documents) {
      if (d.type == type) return d;
    }
    return null;
  }

  bool hasUploaded(KycDocType type) => documentFor(type)?.uploaded ?? false;

  /// Every required document present. The server decides SUBMITTED off exactly
  /// this rule, so the screen can show the same thing without a second read.
  bool get isComplete => requiredDocuments.every(hasUploaded);

  factory KycState.fromJson(Map<String, dynamic> j) {
    final required = j['requiredDocuments'];
    final docs = j['documents'];
    return KycState(
      kycStatus: KycStatus.fromWire(j['kycStatus'] as String?),
      approved: j['approved'] == true,
      requiredDocuments: required is List
          ? [for (final r in required) ?KycDocType.fromWire(r as String?)]
          : const [],
      documents: docs is List
          ? [
              for (final d in docs)
                ?KycDocument.tryFromJson((d as Map).cast<String, dynamic>()),
            ]
          : const [],
    );
  }
}

/// `POST /v1/kyc/upload-url` body.
class KycUploadRequest {
  const KycUploadRequest({
    required this.type,
    required this.contentType,
    required this.sizeBytes,
    required this.fileName,
  });

  final KycDocType type;
  final String contentType;
  final int sizeBytes;
  final String fileName;

  Map<String, Object?> toBody() => {
    'type': type.wire,
    'contentType': contentType,
    'sizeBytes': sizeBytes,
    'fileName': fileName,
  };
}

