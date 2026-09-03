import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_images.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/view/widget/common_image_view_widget.dart';
import 'package:autonect/view/widget/custom_textfield.dart';
import 'package:autonect/view/widget/my_BSheet.dart';
import 'package:autonect/view/widget/my_button.dart';
import 'package:autonect/view/widget/my_drop_down_btn.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddPartRequestPage extends StatefulWidget {
  const AddPartRequestPage({super.key});

  @override
  State<AddPartRequestPage> createState() => _AddPartRequestPageState();
}

class _AddPartRequestPageState extends State<AddPartRequestPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1

  String? _urgency;
  String? _condition;

  void _next() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      if (_currentStep == 3) {
        Get.bottomSheet(
          RequestSendBSheet(
            // Proceed used to only close the sheet, leaving the buyer parked on
            // a finished wizard with nowhere to go. Close the sheet, then leave
            // the wizard back to whatever opened it (Home or the Requests tab).
            onProceed: () {
              Get.back();
              Get.back();
            },
          ),
          isScrollControlled: true,
        );
      }
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        surfaceTintColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: _back,
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: kBlackColor,
            size: 18,
          ),
        ),
        title: Column(
          children: [
            MyText(
              text: 'New Part Request',
              size: 16,
              weight: FontWeight.w600,
              color: kBlackColor,
            ),
            MyText(
              text: _currentStep == 0
                  ? '1/3 DVLA Check'
                  : _currentStep == 1
                  ? '2/3 Part Details'
                  : '3/3 Confirm & Submit',
              size: 12,
              weight: FontWeight.w400,
              color: kSecondaryColor,
            ),
          ],
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? kSecondaryColor
                          : kBlackColor.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildStep1(), _buildStep2(), _buildStep3()],
      ),
    );
  }

  // ───────────────────────────────────────────────
  // STEP 1 — Registration + Vehicle Details
  // ───────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Enter Your Registration',
                  size: 16,
                  weight: FontWeight.w600,
                  paddingBottom: 10,
                  paddingTop: 24,
                ),

                // ── License plate box
                Align(
                  alignment: AlignmentGeometry.center,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 36),
                    width: Get.width / 1.8,
                    decoration: AppStyling().myDecoration(
                      color: kTertiaryColor,
                      borderColor: kTransperentColor,
                      radius: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Blue flag strip
                        Container(
                          width: 30,
                          height: 48,
                          decoration: AppStyling().myDecoration(
                            color: kSecondaryColor,
                            borderColor: kTransperentColor,
                            radius: 5,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              MyText(
                                text: '🇬🇧\nGB',
                                size: 11,
                                color: kWhiteColor,
                                weight: FontWeight.w700,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: kBlackColor,
                              letterSpacing: 5,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'AB12 EH3',
                              hintStyle: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: kGreyTextColor,
                                letterSpacing: 5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                MyButton(buttonText: 'Find Vehicle', onTap: () {}),

                // const SizedBox(height: 22),
                Padding(
                  padding: EdgeInsetsGeometry.only(top: 48, bottom: 15),
                  child: Divider(thickness: 1, color: kSecondaryColor),
                ),

                // ── Vehicle Details header
                Align(
                  alignment: AlignmentGeometry.center,
                  child: MyText(
                    text: 'Vehicle Details',
                    size: 16,
                    weight: FontWeight.w700,
                    color: kSecondaryColor,
                  ),
                ),
                const SizedBox(height: 14),

                MyTextField(labelText: 'Make', hintText: 'Ferrari', radius: 9),
                MyTextField(labelText: 'Model', hintText: 'Model', radius: 9),
                MyTextField(labelText: 'Year', hintText: 'Year', radius: 9),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        _BottomButton(label: 'Next', onTap: _next),
      ],
    );
  }

  // ───────────────────────────────────────────────
  // STEP 2 — Part Details + Upload
  // ───────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                MyTextField(
                  labelText: 'Part Name',
                  hintText: 'Transmission',
                  radius: 9,
                ),
                MyTextField(labelText: 'Part Number', radius: 9),

                MyDropDown(
                  title: 'Set Urgency',
                  hint: 'Urgent',
                  itemsList: const ['Urgent', 'Normal', 'Low'],
                  selectedValue: _urgency,
                  onChanged: (v) => setState(() => _urgency = v),
                ),

                MyDropDown(
                  title: 'Condition',
                  hint: 'New',
                  itemsList: const ['New', 'Used', 'Refurbished'],
                  selectedValue: _condition,
                  onChanged: (v) => setState(() => _condition = v),
                ),

                MyTextField(
                  labelText: 'Description',
                  hintText: 'Describe the part details',
                  radius: 9,
                  maxLines: 4,
                ),

                // ── Upload Photo
                MyText(
                  text: 'Upload Photo',
                  size: 16,
                  weight: FontWeight.w600,
                  paddingBottom: 8,
                ),
                Container(
                  width: double.infinity,

                  decoration: AppStyling().myDecoration(
                    color: kTransperentColor,
                    borderColor: kBlackColor.withValues(alpha: .5),
                    radius: 9,
                  ),
                  child: MyRippleEffect(
                    splashColor: kSecondaryColor.withValues(alpha: .2),
                    radius: 9,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CommonImageView(
                            imagePath: Assets.imagesUploadArrowIcon,
                            width: 64,
                          ),
                          const SizedBox(height: 6),
                          MyText(
                            text: 'Click to upload',
                            size: 14,
                            weight: FontWeight.w400,
                            color: kGreyTextColor,
                          ),
                          MyText(
                            text:
                                'Upload images of the part you are looking for,\nonly .jpg, .png file',
                            size: 12,
                            weight: FontWeight.w400,
                            color: kGreyTextColor,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        _BottomButton(label: 'Next', onTap: _next),
      ],
    );
  }

  // ───────────────────────────────────────────────
  // STEP 3 — Review & Send Request
  // ───────────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _SummaryCard(),
                const SizedBox(height: 20),

                // ── What happens next
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kSecondaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kSecondaryColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: 'What happens next?',
                        size: 16,
                        weight: FontWeight.w600,
                        color: kSecondaryColor,
                        paddingBottom: 10,
                      ),
                      _Bullet(
                        text:
                            'Sellers in your area will review your request and send offers',
                      ),
                      _Bullet(text: 'You\'ll be notified when offers arrive'),
                      _Bullet(
                        text:
                            'Compare offers and select the best deal for your needs',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        _BottomButton(label: 'Send Request', onTap: _next),
      ],
    );
  }
}

// Shared: Summary Card

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppStyling().myDecoration(
        color: kTransperentColor,
        borderColor: kBlackColor.withValues(alpha: .5),
        radius: 9,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(
                  icon: Assets.imagesPA,
                  label: 'Vehicle',
                  value: 'Toyota Yaris 2020',
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  icon: Assets.imagesPB,
                  label: 'Requested Part',
                  value: 'Transmission',
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  icon: Assets.imagesPC,
                  label: 'Condition',
                  value: 'New',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String icon;
  final String label, value;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonImageView(width: 50, height: 50, imagePath: icon),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(text: label, size: 16, weight: FontWeight.w600),
            MyText(
              text: value,
              size: 14,
              weight: FontWeight.w400,
              color: kGreyTextColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Container(
              height: 5,
              width: 5,
              decoration: const BoxDecoration(
                color: kSecondaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: MyText(text: text, size: 14, weight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BottomButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: kPrimaryColor,
      child: MyButton(buttonText: label, onTap: onTap),
    );
  }
}

// BOTTOM SHEET

class RequestSendBSheet extends StatelessWidget {
  /// What "Proceed" does. Optional so existing/other call sites keep the old
  /// close-the-sheet behaviour; AddPartRequestPage passes a callback that also
  /// leaves the wizard.
  final VoidCallback? onProceed;

  const RequestSendBSheet({super.key, this.onProceed});

  @override
  Widget build(BuildContext context) {
    return MyBSheet(
      btnText: "Proceed",
      onTap: onProceed ?? () => Get.back(),
      body: Column(
        children: [
          CommonImageView(width: 150, imagePath: Assets.imagesRequestPartIcon),

          MyText(
            textAlign: TextAlign.center,
            paddingBottom: 20,
            paddingTop: 24,
            text: "Request Sent to Sellers",
            size: 20,
            weight: FontWeight.w700,
          ),

          MyText(
            paddingBottom: 24,
            textAlign: TextAlign.center,
            text:
                "Your request has been sent to sellers you will receive offers soon",
            size: 16,
            weight: FontWeight.w400,
          ),
        ],
      ),
    );
  }
}
