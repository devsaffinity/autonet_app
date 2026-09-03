import 'package:autonect/config/routes/routes.dart';
import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReviewPage extends StatefulWidget {
  /// What is being reviewed. Defaults keep an argument-less `ReviewPage()`
  /// working for any caller that does not know the order yet.
  final String sellerName, partName;

  const ReviewPage({
    super.key,
    this.sellerName = 'AutoParts Hub',
    this.partName = 'your order',
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _selectedRating = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: "Review", centerdTitle: false),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // ── Rate Your Experience
            Center(
              child: MyText(
                text: 'Rate Your Experience',
                size: 16,
                weight: FontWeight.w700,
                color: kBlackColor,
              ),
            ),
            Center(
              child: MyText(
                paddingTop: 4,
                text: '${widget.partName} from ${widget.sellerName}',
                size: 13,
                weight: FontWeight.w400,
                color: kGreyTextColor,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // ── Star Rating Row
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < _selectedRating;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        filled ? Icons.star : Icons.star_border,
                        color: filled
                            ? const Color(0xffFFBB00)
                            : const Color(0xffDDDDDD),
                        size: 42,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 28),

            // ── Write Review label
            MyText(
              text: 'Write Review (Optional)',
              size: 13,
              weight: FontWeight.w600,
              color: kBlackColor,
              paddingBottom: 8,
            ),

            // ── Review text area
            MyTextField(
              hintText:
                  'Share your experience. What did you like? Was there anything that could be improved?',
              maxLines: 6,
              marginBottom: 20,
              radius: 9,
            ),

            // ── Confirm Review button
            MyButton(
              buttonText: 'Confirm Review',
              onTap: () {
                // `Get.close(6)` only landed on the shell when this page was
                // reached through the full six-deep offer funnel; from any
                // shorter path it over-popped. The end of the order journey is
                // a stack-clearing navigation, so per the routing rule it is
                // named.
                Get.offAllNamed(AppLinks.buyerShell);
              },
            ),
          ],
        ),
      ),
    );
  }
}
