import 'package:autonect/data/repositories/profile_repository.dart';
import 'package:autonect/data/repositories/notifications_repository.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/data/models/app_notification.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/blob_uploader.dart';
import 'package:autonect/data/core/http_transport.dart';
import 'package:autonect/data/models/message_ack.dart';
import 'package:autonect/data/models/offer.dart';
import 'package:autonect/data/models/order.dart';
import 'package:autonect/data/models/order_enums.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/conversation.dart';
import 'package:autonect/data/models/provider_dashboard.dart';
import 'package:autonect/data/models/provider_schedule.dart';
import 'package:autonect/data/models/part_category.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/domain/review_context.dart';
import 'package:autonect/data/models/upload_ticket.dart';
import 'package:autonect/data/models/vehicle.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/data/repositories/chat_repository.dart';
import 'package:autonect/data/models/service_provider.dart';
import 'package:autonect/data/repositories/providers_repository.dart';
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
  Future<ApiResult<Paged<PartRequest>>> listMine({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
    String? q,
  }) async {
    // Blank is logged as absent, because the api repository OMITS the key
    // when it is blank — a fake that recorded ':q=' would assert a query string
    // the real one never sends.
    final query = q?.trim() ?? '';
    calls.add('listMine:$page:$limit:${status?.wire}${query.isEmpty ? '' : ':q=$query'}');
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
  ApiResult<Paged<Offer>>? buyerOffersResult;
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
  Future<ApiResult<Paged<Offer>>> buyerOffers({int page = 1, int limit = 20}) async {
    calls.add('buyerOffers:$page:$limit');
    return buyerOffersResult ?? _none('buyerOffers');
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
  Future<ApiResult<Review>> create({
    required ReviewContext context,
    required int rating,
    String? text,
  }) async {
    final entry = context.bodyEntry;
    calls.add('review:${entry.key}=${entry.value}:$rating');
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

/// Home reads both of these on mount — the notification badge and the avatar —
/// so any test that pumps the buyer shell must register them or the whole
/// IndexedStack throws before a single assertion runs.
class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({this.unread = 0, this.items = const []});

  final int unread;
  final List<AppNotification> items;

  @override
  Future<ApiResult<NotificationPage>> list({int page = 1, int limit = 20}) async =>
      Ok(NotificationPage(
        items: items,
        unread: unread,
        total: items.length,
        page: page,
        hasMore: false,
      ));

  @override
  Future<ApiResult<int>> markRead(String id) async => const Ok(1);

  @override
  Future<ApiResult<int>> markAllRead() async => Ok(unread);

  @override
  Future<ApiResult<int>> remove(String id) async => const Ok(1);

  @override
  Future<ApiResult<int>> removeAll() async => Ok(items.length);
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.avatarUrl});

  final String? avatarUrl;

  /// Overrides the default BUYER profile. Needed by any test about a
  /// PROVIDER screen, which reads electricianProfile off this.
  ApiResult<MeProfile>? meResult;

  @override
  Future<ApiResult<MeProfile>> me() async => meResult ?? Ok(MeProfile.fromJson({
    'id': 'u1',
    'email': 'buyer@example.com',
    'role': 'BUYER',
    'name': 'Test Buyer',
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  }));

  @override
  Future<ApiResult<MeProfile>> registerSupplierBusiness(
    SupplierBusinessDraft draft,
  ) async => me();

  /// Records the draft so a wizard test can assert what was actually sent —
  /// the wizard used to submit nothing at all, which is precisely the
  /// regression worth pinning.
  ElectricianRegistrationDraft? electricianDraft;

  @override
  Future<ApiResult<MeProfile>> registerElectrician(
    ElectricianRegistrationDraft draft,
  ) async {
    electricianDraft = draft;

    return me();
  }

  @override
  Future<ApiResult<UploadTicket>> createAvatarUploadTicket(
    String contentType,
  ) async => const Ok(
    UploadTicket(key: 'avatars/u1/x', url: 'https://s3/x', expiresInSec: 300),
  );

  @override
  Future<ApiResult<MeProfile>> setAvatar(String avatarKey) async => me();

  Map<String, dynamic>? lastUpdatedProfile;

  @override
  Future<ApiResult<MeProfile>> updateProfile({
    String? name,
    String? location,
    String? contact,
    String? avatarKey,
  }) async {
    lastUpdatedProfile = {
      'name': name,
      'location': location,
      'contact': contact,
      'avatarKey': avatarKey,
    };
    return me();
  }
}

class FakeProvidersRepository implements ProvidersRepository {
  final List<String> calls = [];
  ApiResult<Paged<ServiceProvider>>? listResult;
  ApiResult<ServiceProvider>? byIdResult;

  @override
  Future<ApiResult<Paged<ServiceProvider>>> list({
    int page = 1,
    int limit = 20,
    Region? region,
    String? brand,
    BookingServiceType? service,
    String? q,
  }) async {
    // Blank filters are logged as absent, because the api repository omits
    // them — recording ':q=' would assert a query string it never sends.
    final query = q?.trim() ?? '';
    calls.add('providers:$page:$limit:${region?.wire}'
        '${brand == null ? '' : ':brand=$brand'}'
        '${service == null ? '' : ':service=${service.wire}'}'
        '${query.isEmpty ? '' : ':q=$query'}');
    return listResult ?? _none('providers.list');
  }

  @override
  Future<ApiResult<ServiceProvider>> byId(String id) async {
    calls.add('provider:$id');
    return byIdResult ?? _none('providers.byId');
  }
}

class FakeBookingsRepository implements BookingsRepository {
  final List<String> calls = [];
  ApiResult<Booking>? createResult;
  ApiResult<DayAvailability>? availabilityResult;
  ApiResult<Paged<Booking>>? listResult;
  ApiResult<Booking>? byIdResult;
  ApiResult<Booking>? cancelResult;
  ApiResult<Booking>? advanceResult;
  ApiResult<Booking>? quoteResult;
  ApiResult<ProviderSchedule>? scheduleResult;
  ApiResult<ProviderDashboard>? dashboardResult;
  ApiResult<ProviderSchedule>? setScheduleResult;

  @override
  Future<ApiResult<Booking>> create({
    required String electricianId,
    required BookingServiceType serviceType,
    required Region region,
    required DateTime scheduledAt,
    String? description,
    String? regNumber,
    String? location,
    int? durationMins,
  }) async {
    calls.add('create:$electricianId:${serviceType.wire}:'
        '${scheduledAt.toUtc().toIso8601String()}'
        '${durationMins == null ? '' : ':mins=$durationMins'}'
        '${location == null ? '' : ':loc=$location'}');
    return createResult ?? _none('bookings.create');
  }

  @override
  Future<ApiResult<DayAvailability>> availability({
    required String providerId,
    required String date,
  }) async {
    calls.add('availability:$providerId:$date');
    return availabilityResult ?? _none('bookings.availability');
  }

  @override
  Future<ApiResult<ProviderDashboard>> dashboard() async {
    calls.add('dashboard');
    return dashboardResult ?? _none('bookings.dashboard');
  }

  @override
  Future<ApiResult<ProviderSchedule>> schedule() async {
    calls.add('schedule:get');
    return scheduleResult ?? _none('bookings.schedule');
  }

  @override
  Future<ApiResult<ProviderSchedule>> setSchedule(
    Map<int, Set<AvailabilityBand>> byWeekday,
  ) async {
    // Logged in weekday order with bands in enum order, so an assertion reads
    // the same whatever order the screen happened to touch the days in.
    final days = (byWeekday.keys.toList()..sort())
        .map(
          (w) =>
              '$w=${AvailabilityBand.values.where(byWeekday[w]!.contains).map((b) => b.wire).join('+')}',
        )
        .join(',');
    calls.add('schedule:put:$days');
    return setScheduleResult ?? _none('bookings.setSchedule');
  }

  @override
  Future<ApiResult<Paged<Booking>>> listMine({
    int page = 1,
    int limit = 20,
    BookingStatus? status,
  }) async {
    calls.add('bookings:$page:$limit:${status?.wire}');
    return listResult ?? _none('bookings.listMine');
  }

  @override
  Future<ApiResult<Booking>> byId(String id) async {
    calls.add('booking:$id');
    return byIdResult ?? _none('bookings.byId');
  }

  @override
  Future<ApiResult<Booking>> cancel({
    required String id,
    required String note,
  }) async {
    calls.add('cancel:$id:$note');
    return cancelResult ?? _none('bookings.cancel');
  }

  @override
  Future<ApiResult<Booking>> quote({
    required String id,
    int? quotedPence,
    int? finalPence,
    String? note,
  }) async {
    calls.add('quote:$id'
        '${quotedPence == null ? '' : ':quoted=$quotedPence'}'
        '${finalPence == null ? '' : ':final=$finalPence'}');
    return quoteResult ?? _none('bookings.quote');
  }

  @override
  Future<ApiResult<Booking>> advance({
    required String id,
    required BookingStatus status,
    String? note,
  }) async {
    calls.add('advance:$id:${status.wire}');
    return advanceResult ?? _none('bookings.advance');
  }
}

/// Chat. Threads are anchored to a CONTEXT and the server derives the
/// participants, so the fake records the context it was asked for rather than
/// any recipient — there is no recipient to record.
class FakeChatRepository implements ChatRepository {
  final List<String> calls = [];
  ApiResult<Conversation>? openResult;
  ApiResult<CursorPage<Conversation>>? inboxResult;
  ApiResult<CursorPage<ChatMessage>>? messagesResult;
  ApiResult<ChatMessage>? sendResult;
  ApiResult<int>? markReadResult;

  /// Drained before [messagesResult], so a poll or a post-send re-read can
  /// answer differently from the first read.
  final List<ApiResult<CursorPage<ChatMessage>>> messagesQueue = [];

  int get messageReads => calls.where((c) => c.startsWith('messages:')).length;

  @override
  Future<ApiResult<Conversation>> openForBooking(String bookingId) async {
    calls.add('open:BOOKING:$bookingId');
    return openResult ?? _none('chat.openForBooking');
  }

  @override
  Future<ApiResult<Conversation>> openForOffer(String offerId) async {
    calls.add('open:OFFER:$offerId');
    return openResult ?? _none('chat.openForOffer');
  }

  @override
  Future<ApiResult<CursorPage<Conversation>>> inbox({
    String? cursor,
    int limit = 30,
  }) async {
    calls.add('inbox:${cursor ?? '-'}:$limit');
    return inboxResult ?? _none('chat.inbox');
  }

  @override
  Future<ApiResult<CursorPage<ChatMessage>>> messages(
    String conversationId, {
    String? cursor,
    int limit = 30,
  }) async {
    calls.add('messages:$conversationId:${cursor ?? '-'}');
    if (messagesQueue.isNotEmpty) return messagesQueue.removeAt(0);
    return messagesResult ?? _none('chat.messages');
  }

  @override
  Future<ApiResult<ChatMessage>> send({
    required String conversationId,
    required String body,
  }) async {
    calls.add('send:$conversationId:$body');
    return sendResult ?? _none('chat.send');
  }

  @override
  Future<ApiResult<int>> markRead(String conversationId) async {
    calls.add('read:$conversationId');
    return markReadResult ?? const Ok(0);
  }
}
