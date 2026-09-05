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

  /// [PagedController.refreshForFilter], never `refreshFirst`: a chip change
  /// must blank the previous filter's rows, and it must supersede an in-flight
  /// read rather than be dropped by it.
  Future<void> setFilter(RequestStatus? status) {
    filter.value = status;
    return refreshForFilter();
  }

  @override
  Future<ApiResult<Paged<PartRequest>>> fetchPage(int page) =>
      _repo.listMine(page: page, status: filter.value);

  @override
  String idOf(PartRequest item) => item.id;
}
