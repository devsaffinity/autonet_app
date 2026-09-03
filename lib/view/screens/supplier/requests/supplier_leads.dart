import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/view/screens/buyer/request/request_status_tracking.dart'
    show MySearchBar;
import 'package:autonect/view/screens/supplier/requests/supplier_lead_card.dart';
import 'package:autonect/view/screens/supplier/widgets/supplier_chips.dart';
import 'package:autonect/view/widget/general_appbar.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Incoming buyer part requests. The supplier mirror of the buyer's
/// RequestStatusTrackingPage — same app bar, same MySearchBar, same card shell.
class SupplierLeadsPage extends StatefulWidget {
  const SupplierLeadsPage({super.key});

  @override
  State<SupplierLeadsPage> createState() => _SupplierLeadsPageState();
}

class _SupplierLeadsPageState extends State<SupplierLeadsPage> {
  /// The exact four axes the backend indexes requests on.
  static const List<String> _filters = [
    'Engine',
    'Transmission',
    'London',
    'South East',
    'New',
    'Used',
    'Urgent',
  ];
  final Set<String> _activeFilters = {};

  // Placeholder feed. Shaped as a List<Map> like every other screen in the app
  // so the future API layer swaps it in one place.
  final List<Map<String, dynamic>> _leads = [
    {
      'brand': 'TOYOTA',
      'model': 'Yaris 2020',
      'plate': 'LM20 XKR',
      'buyer': 'Sarah Johnson',
      'category': 'Transmission',
      'region': 'London',
      'urgency': 'Urgent',
      'posted': '12m ago',
      'state': LeadState.locked,
    },
    {
      'brand': 'FORD',
      'model': 'Mustang GT',
      'plate': 'YP19 TTD',
      'buyer': 'Michael Chen',
      'category': 'Brakes',
      'region': 'South East',
      'urgency': 'Standard',
      'posted': '1h ago',
      'state': LeadState.unlocked,
    },
    {
      'brand': 'BMW',
      'model': 'M3 2019',
      'plate': 'BD68 OWL',
      'buyer': 'James Wilson',
      'category': 'Electrical',
      'region': 'Wales',
      'urgency': 'Standard',
      'posted': '3h ago',
      'state': LeadState.offered,
    },
  ];

  void _toggleFilter(String f) => setState(
    () => _activeFilters.contains(f)
        ? _activeFilters.remove(f)
        : _activeFilters.add(f),
  );

  /// Local stand-in for the server-side unlock: flips the card out of its
  /// masked state. The real call spends credits and returns the full request.
  void _unlock(int index) =>
      setState(() => _leads[index]['state'] = LeadState.unlocked);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(hasBackButton: false, title: 'Leads'),
      body: SingleChildScrollView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MySearchBar(),
            MyText(
              text: 'Filter by category, region, condition or urgency',
              size: 12,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              paddingBottom: 10,
            ),
            SupplierChoiceChips(
              options: _filters,
              selected: _activeFilters,
              onToggle: _toggleFilter,
            ),
            const SizedBox(height: 18),
            MyText(
              text: 'Showing ${_leads.length} leads',
              size: 14,
              weight: FontWeight.w400,
              color: kGreyTextColor,
              paddingBottom: 10,
            ),
            ...List.generate(
              _leads.length,
              (i) => SupplierLeadCard(
                lead: _leads[i],
                onUnlock: () => _unlock(i),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
