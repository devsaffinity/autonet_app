import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offer_review.dart';
import 'package:autonect/view/screens/supplier/offers/supplier_offer_steps.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Create AND edit an offer.
///
/// The backend enforces `@@unique([requestId, supplierId])` on Offer, so a
/// supplier can only ever hold one offer per request — a second create path
/// would be unbuildable against the API. Passing [existingOffer] swaps the CTA
/// to 'Update Offer'; everything else is identical.
class SupplierCreateOfferPage extends StatefulWidget {
  final Map<String, dynamic>? existingOffer;
  const SupplierCreateOfferPage({super.key, this.existingOffer});

  @override
  State<SupplierCreateOfferPage> createState() =>
      _SupplierCreateOfferPageState();
}

class _SupplierCreateOfferPageState extends State<SupplierCreateOfferPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  static const List<String> _stepLabels = ['Pricing', 'Delivery', 'Review'];

  bool get _isEdit => widget.existingOffer != null;

  void _next() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

  void _submit() {
    Get.bottomSheet(
      OfferSentBSheet(
        title: _isEdit ? 'Offer Updated' : 'Offer Sent to Buyer',
        onContinue: () {
          Get.back();
          Get.back();
        },
      ),
      isScrollControlled: true,
    );
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
        title: MyText(
          text: _isEdit ? 'Edit Offer' : 'Send Offer',
          size: 18,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText(
                      text: 'Step ${_currentStep + 1} of 3',
                      size: 12,
                      weight: FontWeight.w700,
                      color: kSecondaryColor,
                    ),
                    MyText(
                      text: _stepLabels[_currentStep],
                      size: 12,
                      weight: FontWeight.w500,
                      color: kGreyTextColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? kSecondaryColor
                              : kSecondaryColor.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SupplierOfferPricingStep(onNext: _next),
          SupplierOfferDeliveryStep(onNext: _next),
          SupplierOfferReviewStep(
            ctaLabel: _isEdit ? 'Update Offer' : 'Send Offer',
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}
