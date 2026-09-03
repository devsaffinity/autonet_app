/// autonect-backend/src/common/http/pagination.ts. Written now, unused now;
/// the buyer phase inherits it.
///
/// Tolerant parsing (unlike AuthUser): a pagination field drift must degrade,
/// not fail the whole list.
class PageMeta {
  const PageMeta({
    required this.page,
    required this.limit,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  final int page;
  final int limit;
  final int pageSize;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  static int _i(Object? v, [int d = 0]) => v is int ? v : int.tryParse('$v') ?? d;

  factory PageMeta.fromJson(Map<String, dynamic> j) => PageMeta(
    page: _i(j['page'], 1),
    limit: _i(j['limit'], 20),
    pageSize: _i(j['pageSize'], _i(j['limit'], 20)),
    total: _i(j['total']),
    totalPages: _i(j['totalPages']),
    hasNextPage: j['hasNextPage'] == true,
    hasPreviousPage: j['hasPreviousPage'] == true,
  );

  static const empty = PageMeta(
    page: 1,
    limit: 20,
    pageSize: 20,
    total: 0,
    totalPages: 0,
    hasNextPage: false,
    hasPreviousPage: false,
  );
}
