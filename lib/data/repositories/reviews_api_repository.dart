import 'package:autonect/data/core/api_client.dart';
import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/core/token_store.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/domain/review_context.dart';
import 'package:autonect/data/repositories/reviews_repository.dart';

class ReviewsApiRepository implements ReviewsRepository {
  /// [tokens] is accepted but not retained — see CatalogApiRepository for why
  /// every buyer repository takes the same pair.
  ReviewsApiRepository(this._c, TokenStore tokens);

  final ApiClient _c;

  static const int _maxLimit = 100;

  /// `text` is omitted when blank: the schema is `min(1).optional()`, so an
  /// empty string is a 400 where an absent key is "no written review".
  @override
  Future<ApiResult<Review>> create({
    required ReviewContext context,
    required int rating,
    String? text,
  }) => _c.send(
    method: 'POST',
    path: '/v1/reviews',
    body: {
      // Exactly one key, chosen by the context type. The server's zod refine
      // rejects both-set and neither-set, and its CHECK constraint rejects
      // them again at the row.
      context.bodyEntry.key: context.bodyEntry.value,
      'rating': rating,
      if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
    },
    decode: (d) => Review.fromJson((d as Map).cast<String, dynamic>()),
  );

  /// PUBLIC: no requireAuth on the route, so it goes out unauthenticated. That
  /// also keeps a reviews tab from burning a refresh rotation on a 401.
  ///
  /// `sendEnvelope`, because `average` and `counts` ride in `meta` beside the
  /// pagination fields and a data-only decoder would drop them silently.
  @override
  Future<ApiResult<ReviewsPage>> forTarget({
    required String targetId,
    int page = 1,
    int limit = 20,
  }) => _c.sendEnvelope(
    method: 'GET',
    path: '/v1/reviews',
    authenticated: false,
    query: {
      'targetId': targetId,
      'page': '${page < 1 ? 1 : page}',
      'limit': '${limit.clamp(1, _maxLimit)}',
    },
    decode: ReviewsPage.decoder,
  );
}
