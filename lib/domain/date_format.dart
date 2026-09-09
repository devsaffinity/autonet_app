/// dd/MM/yyyy, zero-padded, UK ordering.
///
/// Hand-rolled because the project has no `intl` dependency, deliberately. If
/// one is ever added, this is the call site to replace — not a second format
/// invented alongside it.
///
/// Lives in domain/ rather than beside a card because more than one card shows
/// a date, and the second one copying the padding logic is how two formats end
/// up on one screen.
String formatDayMonthYear(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month/${d.year}';
}

/// `HH:MM`, 24-hour, zero-padded.
///
/// Callers pass a LOCAL DateTime — `scheduledAt` arrives as UTC and the clock
/// a buyer will be standing next to is their own, so `.toLocal()` belongs at
/// the call site where that intent is visible rather than hidden in here.
String formatClock(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Month names, for the one place a date is spelled out rather than numbered.
///
/// A second copy of the list that month_calendar.dart owns would be one more
/// place for 'Septmber' to hide, so the calendar imports this rather than
/// keeping its own — the header and the booking's selected-slot line are
/// reading the same month out loud and must never disagree.
const List<String> kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// '15 October 2026' — the long form, for the booking screen's selected slot.
///
/// UK ordering, day first. The comp writes 'October 15, 2024' because it was
/// drawn against a US locale, and every other date in this product is already
/// UK — dd/MM/yyyy above, twelve UK regions, GBP. One US-ordered date in the
/// middle of that is not fidelity to the design, it is an ambiguity: '10/09'
/// and 'October 9' have to mean the same day on the same screen.
String formatLongDate(DateTime d) =>
    '${d.day} ${kMonthNames[d.month - 1]} ${d.year}';
