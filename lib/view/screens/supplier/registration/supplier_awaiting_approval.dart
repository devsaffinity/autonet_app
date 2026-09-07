import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/constants/support.dart';
import 'package:autonect/controller/conttroller.dart';
import 'package:autonect/data/models/me_profile.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Where a registered but unapproved supplier lives.
///
/// A full screen rather than the design's dismissible sheet: an unapproved
/// supplier has nowhere to be dismissed TO. Every route in their shell answers
/// 403 NOT_APPROVED, so a close button that returned them to the app would
/// drop them somewhere nothing works. The close control signs out instead,
/// which is the only exit that leads anywhere coherent.
class SupplierAwaitingApprovalPage extends StatelessWidget {
  /// Optional so this can be a NAMED route: `landingRoute` and the guard place
  /// a supplier here from a cold start, where there is no profile to hand over.
  /// Only the rejection copy depends on it.
  const SupplierAwaitingApprovalPage({super.key, this.profile});

  final MeProfile? profile;

  KycStatus? get _status => profile?.supplierProfile?.kycStatus;

  bool get _rejected => _status == KycStatus.rejected;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Nothing behind this to pop to: it is entered with offAll.
      canPop: false,
      child: Scaffold(
        backgroundColor: kPrimaryColor,
        body: SafeArea(
          child: Padding(
            padding: AppSizes.DEFAULT,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MyText(
                      text: _rejected ? 'Not approved' : 'Under Review',
                      size: AppTextScale.body,
                      color: kBlackColor,
                      weight: AppWeights.medium,
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: 'Sign out',
                      child: IconButton(
                        // Signs out rather than closing: there is no app behind
                        // this screen until an admin approves the account.
                        onPressed: () => RoleController.to.signOut(),
                        tooltip: 'Sign out',
                        icon: const Icon(Icons.close_rounded,
                            size: AppSizes.s24, color: kBlackColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.s20),
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
                      ? 'Your submission was reviewed and could not be '
                            'approved. Update your documents and submit them '
                            'again.'
                      : 'Your supplier profile is currently being reviewed by '
                            'our quality assurance team to ensure authenticity '
                            'and operational standards.',
                  size: AppTextScale.body,
                  color: kGreyTextColor,
                  lineHeight: 1.6,
                ),
                const SizedBox(height: AppSizes.s24),
                _whatsNextCard(),
                const Spacer(),
                // Labelled as the design draws it, and it genuinely tries to go
                // home: it re-reads /v1/me first, and landingRoute opens the
                // shell the moment the server says approved. Approval happens
                // elsewhere and there is no push channel, so this re-read is
                // the ONLY way an approval ever reaches the app — which is why
                // the one button both checks and navigates rather than making
                // the supplier find a separate refresh.
                MyButton(
                  buttonText: 'Back to Home',
                  onTap: _backToHome,
                ),
                if (kSupportEmail.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.s12),
                  MyButton(
                    buttonText: 'Contact Support',
                    backgroundColor: kPrimaryColor,
                    outlineColor: kSecondaryColor,
                    fontColor: kSecondaryColor,
                    onTap: _contactSupport,
                  ),
                ],
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
      color: kPrimaryColor,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: kGreyTextColor.withValues(alpha: .2)),
      boxShadow: [
        BoxShadow(
          color: kBlackColor.withValues(alpha: .05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
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
          // No "24-48 business hours". Nothing in the system measures or
          // escalates that, the review queue has no consumer (there is no admin
          // client in either repo), and the confirmation email reaches nobody
          // until MAIL_FROM moves off Resend's sandbox sender. Promising a
          // window nothing enforces turns every slow review into a broken
          // promise.
          text: _rejected
              ? 'Re-upload your verification documents from your profile and '
                    'the review team will take another look.'
              : "You'll receive a confirmation email once your credentials "
                    'have been verified. You can also tap Check again at any '
                    'time.',
          size: AppTextScale.label,
          color: kGreyTextColor,
          lineHeight: 1.6,
        ),
      ],
    ),
  );

  /// Re-reads the server and leaves if it may.
  ///
  /// `refreshProviderAccess` navigates when landingRoute stops pointing here.
  /// When it does not, the supplier is still under review and would otherwise
  /// see a button that appeared to do nothing — so this says so explicitly.
  Future<void> _backToHome() async {
    final role = RoleController.to;
    await role.refreshProviderAccess();
    if (role.providerApproved.value == true) return;
    Get.snackbar(
      'Still under review',
      'Your account has not been approved yet. We will email you when it is.',
      backgroundColor: kWhiteColor,
    );
  }

  /// No url_launcher in this project, so a mailto: cannot be opened. Copying
  /// the address is the most a client can honestly offer.
  Future<void> _contactSupport() async {
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    Get.snackbar(
      'Support',
      '$kSupportEmail copied to your clipboard',
      backgroundColor: kWhiteColor,
    );
  }
}
