import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/blob_uploader.dart';
import 'package:autonect/data/core/http_transport.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/models/vehicle.dart';
import 'package:autonect/data/repositories/catalog_repository.dart';
import 'package:autonect/data/repositories/orders_repository.dart';
import 'package:autonect/data/repositories/requests_repository.dart';
import 'package:autonect/data/repositories/reviews_repository.dart';
import 'package:autonect/data/repositories/vehicles_repository.dart';
import 'package:autonect/domain/request_draft.dart';

/// In-memory buyer repositories: a controller test runs with no ApiClient and
/// no transport. Every fake records `calls`, because most of what these tests
/// assert is not what came back but WHETHER the network was touched — a
/// duplicate create is a second supplier broadcast, a replayed S3 key is a 409.
/// A `*Queue` is drained before its single-value counterpart, so a second read
/// of the same route can answer differently from the first.
ApiResult<T> _none<T>(String what) => Err<T>(ApiError.malformed('no $what scripted'));

class FakeRequestsRepository implements RequestsRepository {
  final List<String> calls = [];
  ApiResult<PartRequest>? createResult;
  ApiResult<PartRequest>? byIdResult;
  ApiResult<PartRequest>? closeResult;
  ApiResult<Paged<PartRequest>>? listResult;
  final List<ApiResult<Paged<PartRequest>>> listQueue = [];

  /// Left null, every call mints a FRESH single-use key — the property the
  /// retry test has to be able to observe.
  ApiResult<UploadTicket>? ticketResult;
  int _seq = 0;

  int get ticketCalls => calls.where((c) => c.startsWith('ticket:')).length;
  int get createCalls => calls.where((c) => c.startsWith('create:')).length;

  @override
  Future<ApiResult<UploadTicket>> createImageUploadTicket(String contentType) async {
    calls.add('ticket:$contentType');
    if (ticketResult != null) return ticketResult!;
    final n = _seq++;
    return Ok(UploadTicket(key: 'key$n', url: 'https://s3.test/put/$n', expiresInSec: 300));
  }

  @override
  Future<ApiResult<PartRequest>> create(RequestDraft draft) async {
    calls.add('create:${draft.partName}');
    return createResult ?? _none('create');
  }

  @override
  Future<ApiResult<Paged<PartRequest>>> listMine({int page = 1, int limit = 20, RequestStatus? status}) async {
    calls.add('listMine:$page:$limit:${status?.wire}');
    if (listQueue.isNotEmpty) return listQueue.removeAt(0);
    return listResult ?? _none('listMine');
  }

  @override
  Future<ApiResult<PartRequest>> byId(String id) async {
    calls.add('byId:$id');
    return byIdResult ?? _none('byId');
  }

  @override
  Future<ApiResult<PartRequest>> closeOrCancel(String id, CloseAction action) async {
    calls.add('close:$id:${action.wire}');
    return closeResult ?? _none('closeOrCancel');
  }
}

class FakeOrdersRepository implements OrdersRepository {
  final List<String> calls = [];
  ApiResult<List<Offer>>? offersResult;
  ApiResult<Order>? acceptResult;
  ApiResult<Paged<Order>>? listResult;
  ApiResult<Order>? byIdResult;
  ApiResult<Order>? changeStatusResult;
  final List<ApiResult<Order>> byIdQueue = [];
  final List<ApiResult<Paged<Order>>> listQueue = [];

  int get byIdCalls => calls.where((c) => c.startsWith('byId:')).length;
  int get patchCalls => calls.where((c) => c.startsWith('patch:')).length;

  @override
  Future<ApiResult<List<Offer>>> offersForRequest(String requestId) async {
    calls.add('offers:$requestId');
    return offersResult ?? _none('offersForRequest');
  }

  @override
  Future<ApiResult<Order>> acceptOffer({required String offerId, String? deliveryLocation}) async {
    calls.add('accept:$offerId:$deliveryLocation');
    return acceptResult ?? _none('acceptOffer');
  }

  @override
  Future<ApiResult<Paged<Order>>> list({int page = 1, int limit = 20, OrderStatus? status}) async {
    calls.add('list:$page:$limit:${status?.wire}');
    if (listQueue.isNotEmpty) return listQueue.removeAt(0);
    return listResult ?? _none('list');
  }

  @override
  Future<ApiResult<Order>> byId(String id) async {
    calls.add('byId:$id');
    if (byIdQueue.isNotEmpty) return byIdQueue.removeAt(0);
    return byIdResult ?? _none('byId');
  }

  @override
  Future<ApiResult<Order>> changeStatus({required String orderId, required OrderStatus status, String? note}) async {
    calls.add('patch:$orderId:${status.wire}:$note');
    return changeStatusResult ?? _none('changeStatus');
  }
}

class FakeReviewsRepository implements ReviewsRepository {
  final List<String> calls = [];
  ApiResult<Review>? createResult;
  ApiResult<ReviewsPage>? forTargetResult;

  @override
  Future<ApiResult<Review>> create({required String orderId, required int rating, String? text}) async {
    calls.add('review:$orderId:$rating');
    return createResult ?? _none('create');
  }

  @override
  Future<ApiResult<ReviewsPage>> forTarget({required String targetId, int page = 1, int limit = 20}) async {
    calls.add('forTarget:$targetId:$page');
    return forTargetResult ?? _none('forTarget');
  }
}

class FakeCatalogRepository implements CatalogRepository {
  final List<String> calls = [];
  ApiResult<List<PartCategory>>? result;

  @override
  Future<ApiResult<List<PartCategory>>> categories({bool forceRefresh = false}) async {
    calls.add('categories:$forceRefresh');
    return result ?? _none('categories');
  }
}

class FakeVehiclesRepository implements VehiclesRepository {
  final List<String> calls = [];
  ApiResult<VehicleLookup>? result;

  @override
  Future<ApiResult<VehicleLookup>> lookup(String regNumber) async {
    calls.add('lookup:$regNumber');
    return result ?? _none('lookup');
  }
}

/// BlobUploader is a concrete class rather than a seam, so the fake overrides
/// its one method and never lets a transport near a socket.
class FakeBlobUploader extends BlobUploader {
  FakeBlobUploader() : super(const _UnusedTransport());

  final List<String> puts = [];

  /// 1-based index of the PUT that should fail — "image 3's upload fails".
  int? failOnPutNumber;

  @override
  Future<ApiResult<MessageAck>> put({required String url, required List<int> bytes, required String contentType}) async {
    puts.add(url);
    if (puts.length == failOnPutNumber) {
      return const Err(ApiError(code: ApiErrorCode.internal, statusCode: 500, message: 'Upload was rejected (HTTP 500)'));
    }
    return const Ok(MessageAck('Uploaded'));
  }
}

class _UnusedTransport implements HttpTransport {
  const _UnusedTransport();

  @override
  Future<HttpResponse> send(HttpRequest request) =>
      throw StateError('FakeBlobUploader must not reach the transport');
}
