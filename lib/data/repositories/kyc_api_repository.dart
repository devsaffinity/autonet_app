import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/kyc_status.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/repositories/kyc_repository.dart';

class KycApiRepository implements KycRepository {
  /// [tokens] is accepted but not retained, so main.dart constructs every
  /// repository identically.
  KycApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  @override
  Future<ApiResult<KycState>> status() =>
      _c.send(method: 'GET', path: '/v1/kyc/status', decode: _state);

  @override
  Future<ApiResult<UploadTicket>> createUploadTicket(
    KycUploadRequest request,
  ) => _c.send(
    method: 'POST',
    path: '/v1/kyc/upload-url',
    body: request.toBody(),
    decode: (d) => UploadTicket.fromJson((d as Map).cast<String, dynamic>()),
  );

  @override
  Future<ApiResult<KycState>> confirmUpload(String key) => _c.send(
    method: 'POST',
    path: '/v1/kyc/confirm',
    body: {'key': key},
    decode: _state,
  );

  @override
  Future<ApiResult<KycState>> removeDocument(KycDocType type) => _c.send(
    method: 'DELETE',
    // The WIRE value, not the enum name: the server validates the path segment
    // against its own KycDocType enum, so 'businessRegistry' would 400.
    path: '/v1/kyc/documents/${type.wire}',
    decode: _state,
  );

  static KycState _state(Object? d) =>
      KycState.fromJson((d as Map).cast<String, dynamic>());
}
