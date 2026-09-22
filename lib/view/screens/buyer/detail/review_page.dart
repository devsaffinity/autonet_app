import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/review_controller.dart';
import 'package:autonect/data/models/booking.dart' show SubmittedReview;
import 'package:autonect/domain/review_context.dart';
import 'package:autonect/view/widget/counted_text_field.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/star_rating_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// `POST /v1/reviews` — one review per DELIVERED order or COMPLETED booking,
/// and there is no edit and no delete endpoint behind it, so the copy says so
/// before submitting.
///
/// [context] decides which: the same screen reviews a supplier and an
/// electrician, because to a buyer it is the same act and the server takes
/// the same body but for one key.
class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.context,
    required this.supplierName,
    this.existingReview,
    this.isReviewed = false,
    this.onDone,
  });

  /// Convenience for the order journey, which is every existing call site.
  ReviewPage.forOrder({
    super.key,
    required String orderId,
    required this.supplierName,
    this.existingReview,
    this.isReviewed = false,
    this.onDone,
  }) : context = OrderReview(orderId);

  final ReviewContext context;
  final String supplierName;
  final SubmittedReview? existingReview;
  final bool isReviewed;

  /// What to do once it is published.
  ///
  /// Null keeps the ORDER journey's behaviour — clearing the stack back to
  /// the shell, because reviewing is the end of that road. A booking is
  /// reviewed from a list the buyer is still standing in, so that screen
  /// passes a plain pop instead.
  final VoidCallback? onDone;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  /// The text field HAD no controller at all, so `text` could never be sent.
  final TextEditingController _text = TextEditingController();
  late final ReviewController c = ReviewController.ensure();

  @override
  void initState() {
    super.initState();
    c.clearErrors();
    if (widget.existingReview != null || widget.isReviewed) {
      c.markAlreadyReviewed(widget.existingReview);
      if (widget.existingReview != null) {
        c.setRating(widget.existingReview!.rating);
        _text.text = widget.existingReview!.text ?? '';
      }
    } else {
      c.setRating(0);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final text = _text.text.trim();
    final ok = await c.submit(
      context: widget.context,
      rating: c.rating.value,
      // Omitted when blank: `""` fails the server's min(1) and 400s.
      text: text.isEmpty ? null : text,
    );
    if (!mounted || !ok) return;
    // There is no edit and no delete endpoint, so the confirmation says so.
    displayToast(msg: 'Thanks — your review is published and is now final.');
    final onDone = widget.onDone;
    if (onDone != null) {
      onDone();
      return;
    }
    // The end of the ORDER journey clears the stack, so per the routing rule
    // it is a NAMED navigation.
    Get.offAllNamed(AppLinks.buyerShell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Review', centerdTitle: false),
      body: Obx(() {
        final isReviewed = c.alreadyReviewed.value;
        final formError = c.formError.value;
        final ratingError = c.fieldErrorFor('rating');
        final textError = c.fieldErrorFor('text');

        return ListView(padding: AppSizes.DEFAULT, children: [
          if (isReviewed)
            Container(
              margin: const EdgeInsets.only(top: AppSizes.s12, bottom: AppSizes.s20),
              padding: const EdgeInsets.all(AppSizes.s16),
              decoration: BoxDecoration(
                color: kSecondaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: kSecondaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: kSecondaryColor, size: 22),
                  const SizedBox(width: AppSizes.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MyText(
                          text: 'Review Already Submitted',
                          size: AppTextScale.subtitle,
                          weight: AppWeights.bold,
                          color: kBlackColor,
                        ),
                        const SizedBox(height: AppSizes.s4),
                        MyText(
                          text: widget.context is OrderReview
                              ? 'You have already reviewed this order. Reviews cannot be edited or removed.'
                              : 'You have already reviewed this booking. Reviews cannot be edited or removed.',
                          size: AppTextScale.label,
                          color: kGreyTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            MyText(text: 'Rate your experience', size: AppTextScale.subtitle,
                weight: AppWeights.bold, color: kBlackColor,
                paddingTop: AppSizes.s20),
            MyText(text: 'How did ${widget.supplierName} do?',
                size: AppTextScale.body, color: kGreyTextColor,
                paddingTop: AppSizes.s4, paddingBottom: AppSizes.s20),
          ],
          StarRatingInput(
            rating: c.rating.value,
            onChanged: isReviewed ? null : c.setRating,
            enabled: !isReviewed,
          ),
          if (!isReviewed && ratingError != null)
            MyText(text: ratingError, size: AppTextScale.label, color: kRedColor,
                paddingTop: AppSizes.s8),
          MyText(
            text: isReviewed ? 'Your review' : 'Write a review (optional)',
            size: AppTextScale.body,
            weight: AppWeights.semibold,
            color: kBlackColor,
            paddingTop: AppSizes.s20,
            paddingBottom: AppSizes.s8,
          ),
          CountedTextField(
            controller: _text,
            maxLength: 1000,
            maxLines: 5,
            hintText: isReviewed ? 'No comment provided' : 'What went well? What could be better?',
            errorText: isReviewed ? null : textError,
            isReadOnly: isReviewed,
          ),
          if (!isReviewed) ...[
            MyText(text: 'Reviews cannot be edited or removed once published.',
                size: AppTextScale.label, color: kGreyTextColor),
            if (formError != null)
              MyText(text: formError, size: AppTextScale.body, color: kRedColor,
                  paddingTop: AppSizes.s12),
          ],
        ]);
      }),
      bottomNavigationBar: Padding(
        padding: AppSizes.DEFAULT,
        child: Obx(() {
          final isReviewed = c.alreadyReviewed.value;
          if (isReviewed) {
            return MyButton(
              buttonText: widget.context is OrderReview ? 'Back to Order' : 'Back to Bookings',
              onTap: () {
                final onDone = widget.onDone;
                if (onDone != null) {
                  onDone();
                  return;
                }
                Get.back(result: true);
              },
            );
          }
          return MyButton(
            buttonText: 'Confirm Review',
            enabled: c.canSubmit,
            loading: c.busy.value,
            onTap: _submit,
          );
        }),
      ),
    );
  }
}
