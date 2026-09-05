/// GBP formatting from integer pence.
///
/// Hand-rolled on purpose: `package:intl` is NOT a dependency of this project
/// and must not become one for a single thousands separator. GBP only — the
/// backend is UK-only and stores every amount as integer pence.
library;

/// `0 -> '£0.00'`, `5 -> '£0.05'`, `325000 -> '£3,250.00'`.
///
/// Negatives are handled for completeness (`-£1.00`); no endpoint emits one
/// today, but silently printing '£-1.00' would be worse than handling it.
String formatPence(int pence) {
  final negative = pence < 0;
  final abs = negative ? -pence : pence;
  final digits = (abs ~/ 100).toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  final pennies = (abs % 100).toString().padLeft(2, '0');
  final sign = negative ? '-' : '';
  return '$sign£$grouped.$pennies';
}
