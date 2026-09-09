import 'package:autonect/data/core/api_result.dart';
import 'package:autonect/data/models/review.dart';
import 'package:autonect/domain/review_context.dart';

/// Two of the three `/v1/reviews` routes. `POST /v1/reviews/{id}/reply` is
/// deliberately absent: it is SUPPLIER/ELECTRICIAN-only, so a buyer client
/// carrying it could only ever produce a 403.
abstract class ReviewsRepository {
  /// One review per DELIVERED order or COMPLETED booking.
  ///
  /// [context] is a sealed type carrying exactly one id, because the server
  /// enforces exactly one with a CHECK constraint — two nullable strings here
  /// could express 'both' and 'neither', and both are 400s.
  ///
  /// [rating] is 1..5; [text] is omitted when blank, because `""` fails the
  /// server's `min(1)`.
  ///
  /// Both failure modes arrive as 409 CONFLICT and are told apart only by the
  /// message — classify with `classifyConflict`, never by status code.
  Future<ApiResult<Review>> create({
    required ReviewContext context,
    required int rating,
    String? text,
  });

  /// PUBLIC — sent unauthenticated. The star breakdown rides in the envelope's
  /// `meta` beside the pagination fields, which is why this decodes the whole
  /// envelope rather than just `data`.
  Future<ApiResult<ReviewsPage>> forTarget({
    required String targetId,
    int page = 1,
    int limit = 20,
  });
}
