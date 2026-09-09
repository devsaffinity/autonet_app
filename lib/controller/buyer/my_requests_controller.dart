import 'dart:async';

import 'package:autonect/controller/base/paged_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:autonect/data/models/part_request.dart';
import 'package:autonect/data/models/request_enums.dart';
import 'package:autonect/data/repositories/requests_repository.dart';
import 'package:autonect/domain/select_option.dart';
import 'package:get/get.dart';

/// `GET /v1/requests` with an optional status chip.
class MyRequestsController extends PagedController<PartRequest> {
  MyRequestsController(this._repo, {super.toast, super.showBusy, super.hideBusy});

  final RequestsRepository _repo;

  static MyRequestsController ensure() =>
      Get.isRegistered<MyRequestsController>()
      ? Get.find<MyRequestsController>()
      : Get.put(MyRequestsController(Get.find<RequestsRepository>()));

  /// null is the 'All' chip, and the repository then OMITS the query key
  /// rather than sending it blank.
  final Rxn<RequestStatus> filter = Rxn<RequestStatus>();

  /// The chip row, label included, so the widget needs no enum copy of its own.
  static const List<SelectOption<RequestStatus?>> filterOptions = [
    SelectOption<RequestStatus?>(null, 'All'),
    SelectOption<RequestStatus?>(RequestStatus.open, 'Open'),
    SelectOption<RequestStatus?>(RequestStatus.closed, 'Closed'),
    SelectOption<RequestStatus?>(RequestStatus.cancelled, 'Cancelled'),
  ];

  /// The search box. Server-side over partName / partNumber / regNumber, so it
  /// searches EVERY page of the buyer's requests rather than the rows already
  /// fetched — which is the whole point of putting it above a paged list.
  final RxString query = ''.obs;

  Timer? _queryTimer;

  /// Call from onChanged. Debounced at 350ms: a word typed at speed is one
  /// request per keystroke otherwise, and this list is paged, so each of those
  /// also resets the cursor.
  ///
  /// Goes through [PagedController.refreshForFilter] for the same reason the
  /// chips do: the query IS a filter, so the previous query's rows must be
  /// blanked rather than left under a search box that no longer describes them.
  void setQuery(String value) {
    _queryTimer?.cancel();
    if (value.trim() == query.value) return;
    _queryTimer = Timer(const Duration(milliseconds: 350), () {
      query.value = value.trim();
      refreshForFilter();
    });
  }

  @override
  void onClose() {
    _queryTimer?.cancel();
    super.onClose();
  }

  /// [PagedController.refreshForFilter], never `refreshFirst`: a chip change
  /// must blank the previous filter's rows, and it must supersede an in-flight
  /// read rather than be dropped by it.
  Future<void> setFilter(RequestStatus? status) {
    filter.value = status;
    return refreshForFilter();
  }

  @override
  Future<ApiResult<Paged<PartRequest>>> fetchPage(int page) =>
      _repo.listMine(page: page, status: filter.value, q: query.value);

  @override
  String idOf(PartRequest item) => item.id;
}
