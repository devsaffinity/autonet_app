import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/review_controller.dart';
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
    this.onDone,
  });

  /// Convenience for the order journey, which is every existing call site.
  ReviewPage.forOrder({
    super.key,
    required String orderId,
    required this.supplierName,
    this.onDone,
  }) : context = OrderReview(orderId);

  final ReviewContext context;
  final String supplierName;

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
    // ZERO, not the four this screen used to seed: a buyer who taps nothing
    // must not publish a rating they never chose. The controller is shared with
    // the offer-detail Reviews tab, so a previous visit's value is cleared too.
    c.setRating(0);
    c.clearErrors();
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
      body: ListView(padding: AppSizes.DEFAULT, children: [
        MyText(text: 'Rate your experience', size: AppTextScale.subtitle,
            weight: AppWeights.bold, color: kBlackColor,
            paddingTop: AppSizes.s20),
        MyText(text: 'How did ${widget.supplierName} do?',
            size: AppTextScale.body, color: kGreyTextColor,
            paddingTop: AppSizes.s4, paddingBottom: AppSizes.s20),
        Obx(() => StarRatingInput(
            rating: c.rating.value, onChanged: c.setRating)),
        Obx(() {
          final e = c.fieldErrorFor('rating');
          return e == null
              ? const SizedBox.shrink()
              : MyText(text: e, size: AppTextScale.label, color: kRedColor,
                  paddingTop: AppSizes.s8);
        }),
        MyText(text: 'Write a review (optional)', size: AppTextScale.body,
            weight: AppWeights.semibold, color: kBlackColor,
            paddingTop: AppSizes.s20, paddingBottom: AppSizes.s8),
        Obx(() => CountedTextField(controller: _text, maxLength: 1000,
            maxLines: 5, hintText: 'What went well? What could be better?',
            errorText: c.fieldErrorFor('text'))),
        MyText(text: 'Reviews cannot be edited or removed once published.',
            size: AppTextScale.label, color: kGreyTextColor),
        Obx(() {
          final e = c.formError.value;
          return e == null
              ? const SizedBox.shrink()
              : MyText(text: e, size: AppTextScale.body, color: kRedColor,
                  paddingTop: AppSizes.s12);
        }),
      ]),
      bottomNavigationBar: Padding(
        padding: AppSizes.DEFAULT,
        // Inert until 1..5 is chosen — the server's rating is an int 1..5 and
        // there is no such thing as a zero-star review.
        child: Obx(() => MyButton(buttonText: 'Confirm Review',
            enabled: c.canSubmit, loading: c.busy.value, onTap: _submit)),
      ),
    );
  }
}
