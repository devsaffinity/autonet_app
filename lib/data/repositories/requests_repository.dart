import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/domain/request_draft.dart';

/// The five `/v1/requests` routes, all BUYER-only.
abstract class RequestsRepository {
  /// [contentType] must ALREADY be one of `image/jpeg`, `image/png`,
  /// `image/webp`. The server's allowlist is case-sensitive and does not trim,
  /// so 'image/jpg' and 'IMAGE/JPEG' are 400s — ImagePickerService is what
  /// guarantees the value.
  ///
  /// Mint the ticket immediately before the PUT: the presigned URL lives about
  /// 300 seconds, and the key inside it is single-use.
  Future<ApiResult<UploadTicket>> createImageUploadTicket(String contentType);

  /// Returns HTTP **200**, not 201. Creating a request broadcasts to every
  /// matching supplier, so this must never be auto-retried.
  Future<ApiResult<PartRequest>> create(RequestDraft draft);

  /// [status] null means "no filter", and the key is then OMITTED from the
  /// query rather than sent blank — see the impl for why that is load-bearing.
  /// [q] searches the buyer OWN requests by part name, part number or
  /// registration. Empty or null means no filter.
  Future<ApiResult<Paged<PartRequest>>> listMine({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
    String? q,
  });

  Future<ApiResult<PartRequest>> byId(String id);

  /// THIS ROUTE NEVER RETURNS 404. A foreign id, an unknown id and an
  /// already-closed request all collapse to the same 409 'Request is not open
  /// (or not yours)', while GET on the very same id answers 404. Client copy
  /// must therefore be 'This request is no longer open', never 'not found'.
  Future<ApiResult<PartRequest>> closeOrCancel(String id, CloseAction action);
}
