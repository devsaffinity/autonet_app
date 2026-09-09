import 'package:autonect/data/models/booking_enums.dart';

/// One bucket of the earnings chart.
class EarningsPoint {
  const EarningsPoint({required this.label, required this.totalPence});

  /// `YYYY-MM-DD` for the week series, `YYYY-MM` for the month series. Kept as
  /// the server sent it; the screen formats it, and parsing it back into a
  /// DateTime here would only invite a timezone to get involved.
  final String label;
  final int totalPence;
}

/// What one kind of callout has earned — the design's 'income streams'.
class ServiceEarnings {
  const ServiceEarnings({
    required this.serviceType,
    required this.completedCount,
    required this.totalPence,
  });

  /// Null when the server names a service this build does not know. The row is
  /// dropped rather than rendered as 'null', because a new enum value shipping
  /// server-side must not put a broken row on an old client.
  final BookingServiceType? serviceType;
  final int completedCount;
  final int totalPence;
}

/// A provider's earnings, as RECORDED WORK — never a balance.
///
/// The buyer pays the provider directly. Autonect holds no money, takes no
/// commission, and has no payout rail, so nothing here is owed to anybody by
/// anybody. Copy that renders it must say 'work completed', never 'balance'
/// or 'available': a provider who read this as a payable figure would be
/// waiting for money that is not coming.
class ProviderDashboard {
  const ProviderDashboard({
    required this.completedCount,
    required this.upcomingCount,
    required this.pendingCount,
    required this.workCompletedPence,
    required this.thisMonthPence,
    required this.averageJobPence,
    required this.unpricedCompletedCount,
    required this.byServiceType,
    required this.last7Days,
    required this.last6Months,
  });

  final int completedCount;

  /// Confirmed or in progress, still ahead of them.
  final int upcomingCount;

  /// Work offered and not yet answered — the design's 'active leads'.
  final int pendingCount;

  final int workCompletedPence;
  final int thisMonthPence;

  /// Null when nothing priced has completed. '£0 average' is a claim about the
  /// work; 'no completed jobs yet' is the truth, and only null can say it.
  final int? averageJobPence;

  /// COMPLETED jobs with no price recorded at all. They are NOT in
  /// [workCompletedPence], and the screen says so — a total that quietly
  /// omits work is worse than one that explains the gap.
  final int unpricedCompletedCount;

  final List<ServiceEarnings> byServiceType;
  final List<EarningsPoint> last7Days;
  final List<EarningsPoint> last6Months;

  bool get hasEarnings => workCompletedPence > 0;

  /// The seven-day series summed — the home screen's 'this week'.
  ///
  /// Derived rather than sent: it is the same numbers the chart already
  /// carries, and a separate field would be a second thing to keep in step.
  int get last7DaysPence =>
      last7Days.fold(0, (sum, point) => sum + point.totalPence);

  static ProviderDashboard fromJson(Map<String, dynamic> j) {
    List<EarningsPoint> series(String key, String labelKey) =>
        ((j[key] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .map(
              (e) => EarningsPoint(
                label: e[labelKey] as String? ?? '',
                totalPence: (e['totalPence'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList();

    return ProviderDashboard(
      completedCount: (j['completedCount'] as num?)?.toInt() ?? 0,
      upcomingCount: (j['upcomingCount'] as num?)?.toInt() ?? 0,
      pendingCount: (j['pendingCount'] as num?)?.toInt() ?? 0,
      workCompletedPence: (j['workCompletedPence'] as num?)?.toInt() ?? 0,
      thisMonthPence: (j['thisMonthPence'] as num?)?.toInt() ?? 0,
      averageJobPence: (j['averageJobPence'] as num?)?.toInt(),
      unpricedCompletedCount:
          (j['unpricedCompletedCount'] as num?)?.toInt() ?? 0,
      byServiceType: ((j['byServiceType'] as List?) ?? const [])
          .map((e) => (e as Map).cast<String, dynamic>())
          .map(
            (e) => ServiceEarnings(
              serviceType: BookingServiceType.fromWire(
                e['serviceType'] as String?,
              ),
              completedCount: (e['completedCount'] as num?)?.toInt() ?? 0,
              totalPence: (e['totalPence'] as num?)?.toInt() ?? 0,
            ),
          )
          .where((s) => s.serviceType != null)
          .toList(),
      last7Days: series('last7Days', 'date'),
      last6Months: series('last6Months', 'month'),
    );
  }
}
