import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/view/screens/electrician/registration/service_provider_registration.dart'
    show AccessTier;
import 'package:autonect/view/screens/supplier/widgets/supplier_blocks.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_widgets.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Step 4 of 5 — one upload card per backend `KycDocType`
/// (ID / BUSINESS_REGISTRY / TAX / LICENSE).
class SupplierKycStep extends StatelessWidget {
  final VoidCallback onNext;
  const SupplierKycStep({super.key, required this.onNext});

  static const List<Map<String, String>> _docs = [
    {
      'icon': Assets.imagesKycA,
      'title': 'Identity Document (ID)',
      'sub': 'Passport or National ID Card',
    },
    {
      'icon': Assets.imagesKycB,
      'title': 'Business Registry',
      'sub': 'Companies House certificate',
    },
    {
      'icon': Assets.imagesKycB,
      'title': 'Tax Certificate',
      'sub': 'VAT or tax registration proof',
    },
    {
      'icon': Assets.imagesKycB,
      'title': 'Trading Licence',
      'sub': 'Operating permit for your region',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text:
                      "To ensure a secure environment for the Autonect network, please provide valid business documentation and personal identification.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 20,
                  paddingTop: 24,
                ),
                ..._docs.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SupplierCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SupplierTitleRow(
                            icon: d['icon']!,
                            title: d['title']!,
                            subTitle: d['sub']!,
                          ),
                          const SizedBox(height: 15),
                          CommonImageView(svgPath: Assets.imagesUploadDocButton),
                        ],
                      ),
                    ),
                  ),
                ),
                const SupplierNoteCard(
                  icon: Icons.warning_amber_sharp,
                  title: 'Privacy First',
                  body:
                      "Your data is encrypted and used solely for identity verification in our partner ecosystem.",
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        SupplierBottomButton(label: 'Continue', onTap: onNext),
      ],
    );
  }
}

/// Step 5 of 5 — plan selection. Renders the already-public `AccessTier()`
/// pricing widget rather than cloning a second pricing table.
class SupplierPlanStep extends StatelessWidget {
  final VoidCallback onFinish;
  const SupplierPlanStep({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text:
                      "Credits are what unlock buyer contact details on a lead. Pick the allowance that matches your volume — you can change it any time.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  paddingBottom: 24,
                  paddingTop: 24,
                ),
                AccessTier(),
                const SizedBox(height: 30),
                MyButton(
                  fontWeight: FontWeight.w700,
                  buttonText: 'Finish Setup',
                  onTap: onFinish,
                ),
                const SizedBox(height: 10),
                MyButton(
                  fontWeight: FontWeight.w700,
                  fontColor: kBlackColor,
                  outlineColor: kSecondaryColor,
                  backgroundColor: kWhiteColor,
                  buttonText: 'Skip for Now',
                  onTap: onFinish,
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
