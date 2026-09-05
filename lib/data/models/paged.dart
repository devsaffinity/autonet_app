import 'package:autonect/data/core/api_envelope.dart';
import 'package:autonect/data/models/page_meta.dart';

/// One page of a list endpoint: the items AND the meta needed to decide whether
/// to ask for another. The pair travels together because a list of items with no
/// stop condition is what makes infinite scroll loop forever.
class Paged<T> {
  const Paged(this.items, this.meta);

  final List<T> items;
  final PageMeta meta;

  bool get hasMore => meta.hasNextPage;

  bool get isEmpty => items.isEmpty;

  /// The ONE paged decoder. `meta` is absent on any endpoint that forgets it, in
  /// which case PageMeta.empty reports hasNextPage:false — loadMore stops rather
  /// than paging forever against a server that never said there was more.
  static EnvelopeDecoder<Paged<T>> decoder<T>(
    T Function(Map<String, dynamic>) fromJson,
  ) => (data, meta) => Paged<T>(
    (data as List)
        .map((e) => fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false),
    meta == null ? PageMeta.empty : PageMeta.fromJson(meta),
  );
}
