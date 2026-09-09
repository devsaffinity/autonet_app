import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

/// Noon, in minutes. The comp splits the day into Morning and Afternoon, and
/// this is the line between them.
const int _kNoonMinutes = 12 * 60;

/// The narrowest a slot chip may be. '09:00' plus its padding, with room to
/// stay tappable — below this the grid drops to one column rather than
/// clipping the time itself.
const double _kMinChip = 120;

/// The comp's Morning / Afternoon slot grid.
///
/// Slots come from the server, which is what makes this honest: a slot that
/// somebody already booked, or that has simply passed, arrives with
/// `available: false` and is rendered unpickable rather than being offered
/// and then refused on submit.
class SlotPicker extends StatelessWidget {
  const SlotPicker({
    super.key,
    required this.slots,
    required this.selected,
    required this.onSelect,
  });

  final List<BookingSlot> slots;
  final BookingSlot? selected;
  final ValueChanged<BookingSlot> onSelect;

  /// Splits on the LABEL, not the instant.
  ///
  /// `time` is 'HH:MM' on a London clock as the server computed it; deriving
  /// morning from `scheduledAt.hour` would read the device's zone and could
  /// put a 09:00 BST slot in the afternoon for a traveller.
  static int _minutesOf(BookingSlot s) {
    final parts = s.time.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final morning = slots.where((s) => _minutesOf(s) < _kNoonMinutes).toList();
    final afternoon = slots.where((s) => _minutesOf(s) >= _kNoonMinutes).toList();
    // TWO PER ROW, measured — not a fixed chip width.
    //
    // The comp draws two chips filling the content width, and a hard 148
    // only happened to do that on the phone it was checked on: it left a
    // ragged right edge on a wide handset and dropped to ONE per row on a
    // narrow one, which reads as a broken grid rather than a chosen layout.
    // LayoutBuilder rather than MediaQuery because this widget does not know
    // what padding its parent already spent.
    return LayoutBuilder(builder: (_, constraints) {
      final full = constraints.maxWidth;
      // Unbounded happens inside a Row or a horizontal list. Nothing does
      // that today, but a NaN width is a hard layout assertion rather than a
      // degraded layout, so it is worth one line to fall back.
      final width = full.isFinite ? (full - AppSizes.s12) / 2 : _kMinChip;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Each half is omitted when empty rather than printing a heading
          // over nothing — a provider's grid may be entirely afternoon.
          if (morning.isNotEmpty) ..._band('Morning', morning, width),
          if (morning.isNotEmpty && afternoon.isNotEmpty)
            const SizedBox(height: AppSizes.s16),
          if (afternoon.isNotEmpty) ..._band('Afternoon', afternoon, width),
        ],
      );
    });
  }

  List<Widget> _band(String title, List<BookingSlot> band, double width) => [
    MyText(text: title, size: AppTextScale.body, weight: AppWeights.semibold,
        color: kBlackColor),
    const SizedBox(height: AppSizes.s8),
    // Wrap, not a fixed 2-column grid: the slot count is the server's to
    // decide, and an odd one leaves a hole in a grid. The width is measured
    // so the wrap lands on two per row, which is what the comp draws.
    Wrap(
      spacing: AppSizes.s12,
      runSpacing: AppSizes.s12,
      children: [for (final s in band) _chip(s, width)],
    ),
  ];

  Widget _chip(BookingSlot slot, double width) {
    final isSelected = selected?.scheduledAt == slot.scheduledAt;
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: slot.available,
      label: slot.available ? slot.time : '${slot.time}, unavailable',
      child: GestureDetector(
        onTap: slot.available ? () => onSelect(slot) : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // Never below the floor: at a huge text scale two chips genuinely
          // do not fit, and one column of readable chips beats two columns
          // of clipped ones.
          width: width < _kMinChip ? _kMinChip : width,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? kSecondaryColor.withValues(alpha: .12)
                : kWhiteColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            border: Border.all(
              color: isSelected ? kSecondaryColor : kFieldBorderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: ExcludeSemantics(
            child: MyText(
              text: slot.time,
              size: AppTextScale.label,
              weight: isSelected ? AppWeights.semibold : AppWeights.regular,
              // A taken slot is greyed, not hidden: seeing that 11:30 exists
              // but is gone tells a buyer something an absent chip does not.
              color: !slot.available
                  ? kGreyTextColor.withValues(alpha: .5)
                  : isSelected
                      ? kSecondaryColor
                      : kBlackColor,
              decoration: slot.available
                  ? TextDecoration.none
                  : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}
