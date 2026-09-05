import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/repositories/requests_repository.dart';
import 'package:autonect/domain/request_draft.dart';

class RequestsApiRepository implements RequestsRepository {
  /// [tokens] is accepted but not retained — see CatalogApiRepository for why
  /// every buyer repository takes the same pair.
  RequestsApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  /// PAGINATION.MAX_LIMIT is 100 and the server rejects anything above it with
  /// a 400 — it does not clamp. Clamping here turns a caller's bad constant
  /// into a smaller page rather than a broken screen.
  static const int _maxLimit = 100;

  static PartRequest _one(Object? d) =>
      PartRequest.fromJson((d as Map).cast<String, dynamic>());

  @override
  Future<ApiResult<UploadTicket>> createImageUploadTicket(String contentType) =>
      _c.send(
        method: 'POST',
        path: '/v1/requests/image-url',
        body: {'contentType': contentType},
        decode: (d) =>
            UploadTicket.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// 200, not 201 — never branch on the status code here.
  @override
  Future<ApiResult<PartRequest>> create(RequestDraft draft) => _c.send(
    method: 'POST',
    path: '/v1/requests',
    body: draft.toBody(),
    decode: _one,
  );

  /// THE `status` KEY IS OMITTED ENTIRELY WHEN NULL, and that is the single
  /// most likely 400 in this phase. `listRequestsQuerySchema` filters with a
  /// bare `z.enum().optional()` while page/limit go through `blankToUndefined`,
  /// so `?status=`, `?status=all` and `?status=open` all 400 where an absent
  /// key is simply "no filter".
  @override
  Future<ApiResult<Paged<PartRequest>>> listMine({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
  }) => _c.sendEnvelope(
    method: 'GET',
    path: '/v1/requests',
    query: {
      'page': '${page < 1 ? 1 : page}',
      'limit': '${limit.clamp(1, _maxLimit)}',
      if (status != null) 'status': status.wire,
    },
    decode: Paged.decoder(PartRequest.fromJson),
  );

  @override
  Future<ApiResult<PartRequest>> byId(String id) =>
      _c.send(method: 'GET', path: '/v1/requests/$id', decode: _one);

  /// Sends the ACTION verb, never the status it produces: 'CLOSE'/'CANCEL' are
  /// what `closeRequestBodySchema` accepts, and 'CLOSED' is a 400.
  ///
  /// This route never 404s — an unknown id, a foreign id and an already-closed
  /// request are all the same 409 'Request is not open (or not yours)'. Copy
  /// must say 'no longer open', not 'not found'.
  @override
  Future<ApiResult<PartRequest>> closeOrCancel(String id, CloseAction action) =>
      _c.send(
        method: 'PATCH',
        path: '/v1/requests/$id',
        body: {'action': action.wire},
        decode: _one,
      );
}
