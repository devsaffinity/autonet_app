import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/view/screens/supplier/dash_board/supplier_credits.dart';
import 'package:autonect/view/screens/supplier/orders/supplier_orders.dart';
import 'package:autonect/view/screens/supplier/profile/profile.dart';
import 'package:autonect/view/screens/supplier/requests/supplier_leads.dart';
import 'package:autonect/view/widget/my_ripple_effect.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:autonect/view/widget/role_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Horizontal Quick Actions row matching Figma (Browse Requests, Orders, Reviews, Earnings).
class SupplierQuickManagement extends StatelessWidget {
  const SupplierQuickManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: 'Quick Actions',
          size: 16,
          weight: FontWeight.w700,
          color: kBlackColor,
          paddingBottom: 12,
        ),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.manage_search_rounded,
                label: 'Browse\nRequests',
                onTap: () {
                  final shell = RoleShell.maybeOf(context);
                  if (shell != null) {
                    shell.goTo(1);
                  } else {
                    Get.to(() => const SupplierLeadsPage());
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.inventory_2_outlined,
                label: 'Orders',
                onTap: () => Get.to(() => const SupplierOrdersPage()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.rate_review_outlined,
                label: 'Reviews',
                onTap: () => Get.to(() => const SupplierProfilePage()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Earnings',
                onTap: () => Get.to(() => const SupplierCreditsPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MyRippleEffect(
      radius: 12,
      onTap: onTap,
      child: Container(
        height: 82,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEEEEEE),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: kSecondaryColor,
            ),
            const SizedBox(height: 5),
            MyText(
              text: label,
              size: 11,
              weight: FontWeight.w600,
              color: kBlackColor,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
