import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/controller/supplier/supplier_home_controller.dart';
import 'package:autonect/view/screens/supplier/home/home_active_negotiations.dart';
import 'package:autonect/view/screens/supplier/home/home_cards.dart';
import 'package:autonect/view/screens/supplier/home/home_incoming_requests.dart';
import 'package:autonect/view/screens/supplier/home/home_quick_management.dart';
import 'package:autonect/view/screens/supplier/home/home_top_bar.dart';
import 'package:flutter/material.dart';

class SupplierHomePage extends StatefulWidget {
  const SupplierHomePage({super.key});

  @override
  State<SupplierHomePage> createState() => _SupplierHomePageState();
}

class _SupplierHomePageState extends State<SupplierHomePage> {
  late final SupplierHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SupplierHomeController.ensure();
    _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _controller.load,
          color: kSecondaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SupplierHomeTopBar(),
                SizedBox(height: 18),
                SupplierQuickManagement(),
                SizedBox(height: 18),
                SupplierHighlightsCard(),
                SizedBox(height: 24),
                SupplierIncomingRequestsSection(),
                SizedBox(height: 20),
                SupplierActiveNegotiationsSection(),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
