import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_styling.dart';
import 'package:autonect/constants/loading_animation.dart';
import 'package:autonect/controller/buyer/profile_controller.dart';
import 'package:autonect/view/screens/supplier/widgets/access_tier.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Screen accessible from Electrician Profile Settings allowing providers to
/// review, choose, and upgrade their Access Tier at any time after registration.
class ElectricianAccessTierPage extends StatefulWidget {
  const ElectricianAccessTierPage({super.key});

  @override
  State<ElectricianAccessTierPage> createState() =>
      _ElectricianAccessTierPageState();
}

class _ElectricianAccessTierPageState extends State<ElectricianAccessTierPage> {
  final ProfileController _profile = ProfileController.ensure();
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _profile.load();
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'PRO':
        return 'Pro (Monthly)';
      case 'PAY_PER_LEAD':
        return 'Pay-Per-Lead';
      default:
        return 'Free';
    }
  }

  Future<void> _onSelectTier(String newTier) async {
    final current = _profile.me?.electricianProfile?.tier ?? 'FREE';
    final targetLabel = _tierLabel(newTier);

    if (newTier == current) {
      displayToast(msg: 'You are currently on the $targetLabel plan');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: kPrimaryColor,
        title: MyText(
          text: 'Switch to $targetLabel',
          size: 18,
          weight: FontWeight.w700,
          color: kBlackColor,
        ),
        content: MyText(
          text:
              'Would you like to switch your provider access tier to $targetLabel?',
          size: 14,
          weight: FontWeight.w400,
          color: kGreyTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: MyText(
              text: 'Cancel',
              size: 14,
              weight: FontWeight.w600,
              color: kGreyTextColor,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kSecondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: MyText(
              text: 'Confirm',
              size: 14,
              weight: FontWeight.w700,
              color: kWhiteColor,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      final success = await _profile.updateElectricianTier(newTier);
      if (success) {
        displayToast(msg: 'Switched to $targetLabel plan');
      } else {
        displayToast(msg: 'Failed to update access tier');
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(title: 'Access Tier', hasBackButton: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s20,
              vertical: AppSizes.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  final current =
                      _profile.me?.electricianProfile?.tier ?? 'FREE';
                  final label = _tierLabel(current);
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: AppStyling().myShadowDecoration(
                      color: kPrimaryColor,
                      radius: 14,
                      borderColor: kTransperentColor,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: kSecondaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText(
                                text: 'Current Active Tier',
                                size: 12,
                                weight: FontWeight.w500,
                                color: kGreyTextColor,
                              ),
                              const SizedBox(height: 2),
                              MyText(
                                text: label,
                                size: 16,
                                weight: FontWeight.w700,
                                color: kBlackColor,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xff34C759).withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: MyText(
                            text: 'ACTIVE',
                            size: 11,
                            weight: FontWeight.w700,
                            color: const Color(0xff34C759),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                MyText(
                  text: 'Select Your Plan',
                  size: 18,
                  weight: FontWeight.w800,
                  color: kBlackColor,
                ),
                const SizedBox(height: 6),
                MyText(
                  text:
                      "Configure how you'd like to receive leads and manage your service portfolio on the AutoVolt network.",
                  size: 12,
                  weight: FontWeight.w400,
                  color: kGreyTextColor,
                  lineHeight: 1.4,
                  paddingBottom: 20,
                ),
                Obx(() {
                  final current =
                      _profile.me?.electricianProfile?.tier ?? 'FREE';
                  return AccessTier(
                    currentTier: current,
                    onPlanSelected: _onSelectTier,
                  );
                }),
              ],
            ),
          ),
          if (_updating)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: kSecondaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
