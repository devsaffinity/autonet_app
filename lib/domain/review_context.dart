/// What a review answers: a delivered ORDER, or a completed BOOKING.
///
/// Sealed, and carrying exactly one id, because the server enforces exactly
/// one with a CHECK constraint — `num_nonnulls(orderId, bookingId) = 1`.
/// Two nullable strings on a method signature can express 'both' and 'neither'
/// and both are 400s; this type cannot express either, so the impossible
/// request is unwritable rather than merely unlikely.
///
/// Same reasoning as ApiResult and ViewState: the compiler enforces the shape
/// the API actually has.
sealed class ReviewContext {
  const ReviewContext();

  /// The body key this context contributes. The repository sends exactly this
  /// one, so a new context type cannot be added without deciding its key.
  MapEntry<String, String> get bodyEntry;
}

/// A parts order — reviewable once DELIVERED.
final class OrderReview extends ReviewContext {
  const OrderReview(this.orderId);

  final String orderId;

  @override
  MapEntry<String, String> get bodyEntry => MapEntry('orderId', orderId);
}

/// An electrician callout — reviewable once COMPLETED.
///
/// This context could not exist until `Review.orderId` became nullable: an
/// Order only comes from accepting a parts offer, so before that an
/// electrician could never be reviewed and their rating could never leave
/// zero.
final class BookingReview extends ReviewContext {
  const BookingReview(this.bookingId);

  final String bookingId;

  @override
  MapEntry<String, String> get bodyEntry => MapEntry('bookingId', bookingId);
}
