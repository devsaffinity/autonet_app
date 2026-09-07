import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/kyc_status.dart';
import 'package:autonect/data/models/upload_ticket.dart';

/// The KYC document endpoints.
///
/// Every write answers with the full [KycState], so a caller never needs a
/// follow-up read to learn whether the submission is now complete.
abstract class KycRepository {
  Future<ApiResult<KycState>> status();

  /// Step 1 of 3: a presigned PUT. The key is server-generated under the
  /// owner's prefix; the client never chooses it.
  Future<ApiResult<UploadTicket>> createUploadTicket(KycUploadRequest request);

  /// Step 3 of 3, after the bytes are in S3. The server re-reads the object and
  /// rejects anything that does not match what was signed for.
  Future<ApiResult<KycState>> confirmUpload(String key);

  /// Removes one document so it can be replaced. Demotes a SUBMITTED provider
  /// back to PENDING server-side, because the required set is no longer whole.
  Future<ApiResult<KycState>> removeDocument(KycDocType type);
}
