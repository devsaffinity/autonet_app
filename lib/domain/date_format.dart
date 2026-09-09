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
