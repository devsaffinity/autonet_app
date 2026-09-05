import 'package:autonect/data/core/api_envelope.dart';
import 'package:autonect/data/core/api_error.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/paged.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for any list item: the real models land in later partitions, but
/// the paging contract they all rely on is proven here.
class PagedItem {
  const PagedItem(this.id);
  final String id;
  static PagedItem fromJson(Map<String, dynamic> j) => PagedItem(j['id'] as String);
}

ApiResult<Paged<PagedItem>> page(String body) =>
    decodeEnvelopeWithMeta<Paged<PagedItem>>(200, body, Paged.decoder(PagedItem.fromJson));

void main() {
  const fullMeta = '"meta":{"page":1,"limit":20,"pageSize":20,"total":30,'
      '"totalPages":2,"hasNextPage":true,"hasPreviousPage":false}';

  test('decodes items AND meta from the same envelope', () {
    final r = page('{"success":true,"data":[{"id":"a"},{"id":"b"}],$fullMeta}');
    final p = r.valueOrNull!;
    expect(p.items.map((e) => e.id), ['a', 'b']);
    expect(p.meta.page, 1);
    expect(p.meta.total, 30);
    expect(p.hasMore, isTrue);
  });

  test('meta absent falls back to PageMeta.empty rather than throwing', () {
    final p = page('{"success":true,"data":[{"id":"a"}]}').valueOrNull!;
    expect(p.items.length, 1);
    expect(p.meta.page, 1);
    expect(p.hasMore, isFalse);
  });

  test('an empty first page terminates loadMore', () {
    // total:0 -> totalPages:0 -> hasNextPage:false. If this ever reported true,
    // an empty list would page forever.
    const meta = '"meta":{"page":1,"limit":20,"pageSize":20,"total":0,'
        '"totalPages":0,"hasNextPage":false,"hasPreviousPage":false}';
    final p = page('{"success":true,"data":[],$meta}').valueOrNull!;
    expect(p.items, isEmpty);
    expect(p.isEmpty, isTrue);
    expect(p.meta.totalPages, 0);
    expect(p.hasMore, isFalse);
  });

  test('data that is not a List is malformed, not a crash', () {
    final r = page('{"success":true,"data":{"id":"a"},$fullMeta}');
    expect(r.errorOrNull?.code, ApiErrorCode.malformedResponse);
  });

  test('an item that is not a Map is malformed', () {
    expect(page('{"success":true,"data":["a"],$fullMeta}').errorOrNull?.code,
        ApiErrorCode.malformedResponse);
  });

  test('a reviews-shaped meta reaches the decoder intact, string keys and all', () {
    // GET /v1/reviews puts average/counts alongside the paging fields, and
    // counts is keyed by rating as a STRING. ReviewsSummary decodes it in a
    // later partition; the envelope must not flatten or re-key it on the way.
    const body = '{"success":true,"data":[],"meta":{"page":1,"limit":20,'
        '"pageSize":20,"total":3,"totalPages":1,"hasNextPage":false,'
        '"hasPreviousPage":false,"average":4.5,"counts":{"1":0,"5":3}}}';
    Map<String, dynamic>? seen;
    final r = decodeEnvelopeWithMeta<int>(200, body, (data, meta) {
      seen = meta;
      return (data as List).length;
    });
    expect(r.valueOrNull, 0);
    expect(seen!['average'], 4.5);
    expect((seen!['counts'] as Map)['5'], 3);
    expect((seen!['counts'] as Map).keys, containsAll(<String>['1', '5']));
  });
}
