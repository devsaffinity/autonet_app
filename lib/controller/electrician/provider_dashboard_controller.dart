import 'package:autonect/controller/base/api_controller.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/provider_dashboard.dart';
import 'package:autonect/data/repositories/bookings_repository.dart';
import 'package:autonect/domain/view_state.dart';
import 'package:get/get.dart';

/// The provider's earnings screen — `GET /v1/bookings/dashboard`.
///
/// RECORDED WORK, NOT A BALANCE. Autonect holds no money and takes no
/// commission; the buyer pays the provider directly. Nothing this controller
/// exposes is payable, and the screen's copy carries that.
class ProviderDashboardController extends ApiController {
  ProviderDashboardController(
    this._repo, {
    super.toast,
    super.showBusy,
    super.hideBusy,
  });

  final BookingsRepository _repo;

  static const StateSlot _slot = StateSlot('dashboard');

  static ProviderDashboardController ensure() =>
      Get.isRegistered<ProviderDashboardController>()
      ? Get.find<ProviderDashboardController>()
      : Get.put(ProviderDashboardController(Get.find<BookingsRepository>()));

  final Rx<ViewState<ProviderDashboard>> state =
      Rx<ViewState<ProviderDashboard>>(const Loading());

  /// 0 = the last seven days, 1 = the last six months — the chart's two tabs.
  final RxInt chartTab = 0.obs;

  void selectChartTab(int tab) => chartTab.value = tab;

  List<EarningsPoint> seriesFor(ProviderDashboard d) =>
      chartTab.value == 0 ? d.last7Days : d.last6Months;

  /// The tallest bar, used to scale the rest.
  ///
  /// Returns 0 when nothing was earned, and the chart then draws every bar at
  /// zero height rather than dividing by it. A chart that normalises an empty
  /// week against its own maximum draws seven full-height bars out of nothing,
  /// which is the most flattering possible lie.
  int peakPence(ProviderDashboard d) {
    var peak = 0;
    for (final point in seriesFor(d)) {
      if (point.totalPence > peak) peak = point.totalPence;
    }
    return peak;
  }

  double barHeightFor(ProviderDashboard d, EarningsPoint point) {
    final peak = peakPence(d);
    if (peak <= 0) return 0;
    return point.totalPence / peak;
  }

  Future<void> load() => runRead<ProviderDashboard>(
    _slot,
    _repo.dashboard,
    (r) {
      switch (r) {
        case Err(:final error):
          absorbSuperseded(error);
          state.value = Failed(error);
        case Ok(:final value):
          state.value = Data(value);
      }
    },
  );
}
