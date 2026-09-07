import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Where a registered but unapproved supplier lives.
///
/// It is the whole screen, not a dismissible sheet as the comp draws it: an
/// unapproved supplier has no home to dismiss to. Every route in their shell
/// answers 403 NOT_APPROVED, so a close button would drop them into an app
/// where nothing works. There is no back affordance for the same reason — the
/// only ways out are signing out, or being approved.
class SupplierAwaitingApprovalPage extends StatelessWidget {
  const SupplierAwaitingApprovalPage({super.key, required this.profile});

  final MeProfile profile;

  KycStatus? get _status => profile.supplierProfile?.kycStatus;

  bool get _rejected => _status == KycStatus.rejected;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Nothing behind this to pop to: it is pushed with offAll.
      canPop: false,
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        body: SafeArea(
          child: Padding(
            padding: AppSizes.DEFAULT,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.s24),
                MyText(
                  text: _rejected ? 'Not approved' : 'Under Review',
                  size: AppTextScale.label,
                  color: kGreyTextColor,
                  weight: AppWeights.medium,
                ),
                const SizedBox(height: AppSizes.s8),
                MyText(
                  text: _rejected
                      ? 'We could not verify your details'
                      : 'Wait for Admin Approval',
                  size: AppTextScale.display,
                  weight: AppWeights.bold,
                  color: kBlackColor,
                ),
                const SizedBox(height: AppSizes.s12),
                MyText(
                  text: _rejected
                      ? 'Your submission was reviewed and could not be approved. '
                            'Update your documents and submit them again.'
                      : 'Your supplier profile is currently being reviewed by our '
                            'quality assurance team to ensure authenticity and '
                            'operational standards.',
                  size: AppTextScale.body,
                  color: kGreyTextColor,
                  lineHeight: 1.5,
                ),
                const SizedBox(height: AppSizes.s24),
                _whatsNextCard(),
                const Spacer(),
                // Refresh, not "Back to Home": there is no home to go back to
                // until the server says approved, and this is the only thing
                // that can move them off this screen. Approval arrives by an
                // admin acting elsewhere, and the app has no push channel, so
                // an explicit re-read is the only way to learn about it.
                MyButton(
                  buttonText: 'Check again',
                  onTap: () => RoleController.to.refreshProviderAccess(),
                ),
                const SizedBox(height: AppSizes.s12),
                MyButton(
                  buttonText: 'Sign out',
                  backgroundColor: kPrimaryColor,
                  outlineColor: kGreyTextColor,
                  fontColor: kBlackColor,
                  onTap: () => RoleController.to.signOut(),
                ),
                const SizedBox(height: AppSizes.s12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _whatsNextCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSizes.s16),
    decoration: BoxDecoration(
      color: kLightOrangeColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.mail_outline_rounded,
                size: AppSizes.s20, color: kSecondaryColor),
            const SizedBox(width: AppSizes.s8),
            MyText(
              text: "What's next?",
              size: AppTextScale.body,
              weight: AppWeights.bold,
              color: kBlackColor,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.s8),
        MyText(
          // Deliberately says "should" and gives no SLA. The comp promised
          // "24-48 business hours", which nothing in the system measures,
          // enforces or escalates - and the confirmation email only sends once
          // MAIL_FROM is off Resend's sandbox sender, which today delivers to
          // nobody but the API key owner.
          text: _rejected
              ? 'Re-upload your verification documents from your profile, and '
                    'the review team will take another look.'
              : "You'll get an email once your details have been verified. You "
                    'can also tap Check again at any time.',
          size: AppTextScale.label,
          color: kGreyTextColor,
          lineHeight: 1.5,
        ),
      ],
    ),
  );
}
