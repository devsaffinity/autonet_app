import 'package:autonect/data/core/api_envelope.dart' show EnvelopeDecoder;
import 'package:autonect/data/models/auth_user.dart' show jsonString;
import 'package:autonect/data/models/page_meta.dart';

/// The `{id, name}` author projection. [name] is nullable — render a fallback.
class ReviewAuthor {
  const ReviewAuthor({required this.id, this.name, this.avatarUrl});

  final String id;
  final String? name;
  final String? avatarUrl;

  factory ReviewAuthor.fromJson(Map<String, dynamic> j) => ReviewAuthor(
        id: jsonString(j, 'id'),
        name: j['name'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
      );
}

/// The reviewed supplier's single reply. A buyer client can read it but never
/// write one: `POST /v1/reviews/{id}/reply` is SUPPLIER/ELECTRICIAN-only.
class ReviewReply {
  const ReviewReply({
    required this.id,
    required this.reviewId,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  final String id, reviewId, authorId, text;
  final DateTime createdAt;

  factory ReviewReply.fromJson(Map<String, dynamic> j) => ReviewReply(
    id: jsonString(j, 'id'),
    reviewId: jsonString(j, 'reviewId'),
    authorId: jsonString(j, 'authorId'),
    text: jsonString(j, 'text'),
    createdAt: DateTime.parse(jsonString(j, 'createdAt')),
  );
}

/// `POST /v1/reviews` returns the bare row (no author, no reply);
/// `GET /v1/reviews` includes both, so they are nullable here.
class Review {
  const Review({
    required this.id,
    required this.targetId,
    required this.authorId,
    this.orderId,
    this.bookingId,
    required this.rating,
    required this.status,
    required this.createdAt,
    this.text,
    this.author,
    this.reply,
  });

  final String id, targetId, authorId;

  /// EXACTLY ONE of these is set — the server enforces it with a CHECK.
  ///
  /// orderId became nullable when reviews learned to answer a completed
  /// BOOKING as well as a delivered order, which is what finally let an
  /// electrician be rated. Decoding it as a required String threw a
  /// FormatException on the first booking review and took the whole reviews
  /// list down with it, on the supplier screens too.
  final String? orderId, bookingId;

  /// True when this review is about an electrician callout rather than a
  /// parts order. The profile screen shows both the same way; this exists so
  /// a caller that needs to tell them apart does not test for null itself.
  bool get isForBooking => bookingId != null;
  final int rating;
  final String? text;

  /// PUBLISHED | HIDDEN — kept as the raw wire string because the buyer app
  /// only ever receives PUBLISHED rows and never branches on the others.
  final String status;
  final DateTime createdAt;
  final ReviewAuthor? author;
  final ReviewReply? reply;

  factory Review.fromJson(Map<String, dynamic> j) {
    final author = j['author'];
    final reply = j['reply'];
    return Review(
      id: jsonString(j, 'id'),
      targetId: jsonString(j, 'targetId'),
      authorId: jsonString(j, 'authorId'),
      orderId: j['orderId'] as String?,
      bookingId: j['bookingId'] as String?,
      rating: (j['rating'] as num?)?.toInt() ?? 0,
      text: j['text'] as String?,
      status: jsonString(j, 'status'),
      createdAt: DateTime.parse(jsonString(j, 'createdAt')),
      author: author is Map ? ReviewAuthor.fromJson(author.cast<String, dynamic>()) : null,
      reply: reply is Map ? ReviewReply.fromJson(reply.cast<String, dynamic>()) : null,
    );
  }
}

/// The star breakdown `GET /v1/reviews` puts alongside the pagination fields in
/// `meta`. Typed here so no `Map<String, dynamic>` crosses the repository
/// boundary just to carry two extra numbers.
class ReviewsSummary {
  const ReviewsSummary({required this.average, required this.counts});

  final double average;

  /// Always all five stars, zero-filled: reviews.service.ts seeds 1..5 before
  /// merging the groupBy. Keys arrive as JSON STRINGS "1".."5".
  final Map<int, int> counts;

  factory ReviewsSummary.fromMeta(Map<String, dynamic>? meta) {
    final raw = meta?['counts'];
    final counts = <int, int>{for (var star = 1; star <= 5; star++) star: 0};
    if (raw is Map) {
      raw.forEach((k, v) {
        final star = int.tryParse('$k');
        if (star != null && counts.containsKey(star)) {
          counts[star] = (v as num?)?.toInt() ?? 0;
        }
      });
    }
    return ReviewsSummary(
      average: (meta?['average'] as num?)?.toDouble() ?? 0,
      counts: counts,
    );
  }
}

/// One page of `GET /v1/reviews?targetId&page&limit`, decoded from BOTH halves
/// of the envelope — the summary lives in `meta`, which a data-only decoder
/// would silently drop.
class ReviewsPage {
  const ReviewsPage({
    required this.items,
    required this.meta,
    required this.summary,
  });

  final List<Review> items;
  final PageMeta meta;
  final ReviewsSummary summary;

  static EnvelopeDecoder<ReviewsPage> get decoder => (data, meta) => ReviewsPage(
    items: data is List
        ? data
              .map((e) => Review.fromJson((e as Map).cast<String, dynamic>()))
              .toList(growable: false)
        : const <Review>[],
    meta: meta == null ? PageMeta.empty : PageMeta.fromJson(meta),
    summary: ReviewsSummary.fromMeta(meta),
  );
}
