import 'package:autonect/constants/app_colors.dart';
import 'package:autonect/constants/app_sizes.dart';
import 'package:autonect/constants/app_text_styles.dart';
import 'package:autonect/data/models/booking.dart';
import 'package:autonect/data/models/booking_enums.dart';
import 'package:autonect/domain/money_format.dart';
import 'package:autonect/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Result of the quote dialog: pence, and which field it belongs in.
class QuoteResult {
  const QuoteResult({required this.pence, required this.isFinal});

  final int pence;

  /// True once the job is COMPLETED — the server only accepts `finalPence`
  /// there, and rejects it everywhere else.
  final bool isFinal;
}

/// Asks the provider for a price, in POUNDS, and returns PENCE.
///
/// The conversion is the whole reason this is a shared function rather than an
/// inline `showDialog`. Money is integer pence end to end — a provider types
/// '89.50' and the server must receive 8950, and doing that arithmetic twice
/// in two screens is how one of them ends up off by a factor of a hundred.
///
/// Returns null when cancelled or when the input is unusable, so the caller
/// never has to distinguish 'dismissed' from 'typed nonsense'.
Future<QuoteResult?> showQuoteDialog(Booking booking) async {
  final isFinal = booking.status == BookingStatus.completed;
  final existing = booking.quotedPence;
  final field = TextEditingController(
    // Seeded with the current quote so revising is an edit, not a retype.
    text: existing == null ? '' : (existing / 100).toStringAsFixed(2),
  );

  final confirmed = await Get.dialog<bool>(
    AlertDialog(
      title: MyText(
        text: isFinal ? 'Final price' : 'Quote this job',
        size: AppTextScale.subtitle,
        weight: AppWeights.bold,
        color: kBlackColor,
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        MyText(
          text: isFinal
              // The distinction the buyer is owed: what they were told, and
              // what they were charged.
              ? 'What the job actually came to. The buyer sees this beside '
                  'your original quote.'
              : 'The buyer is waiting on this — their booking reads '
                  '"Awaiting quote" until you set it.',
          size: AppTextScale.body,
          color: kGreyTextColor,
        ),
        const SizedBox(height: AppSizes.s12),
        TextField(
          controller: field,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            // Digits and at most one decimal point. Letters and a second point
            // are the two ways a price field silently becomes unparseable.
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(prefixText: '£ ', hintText: '0.00'),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: MyText(text: 'Cancel', size: AppTextScale.body,
              color: kGreyTextColor),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: MyText(text: 'Save', size: AppTextScale.body,
              color: kSecondaryColor, weight: AppWeights.semibold),
        ),
      ],
    ),
  );

  final raw = field.text.trim();
  field.dispose();
  if (confirmed != true || raw.isEmpty) return null;

  final pounds = double.tryParse(raw);
  // Rejected here rather than sent: the server caps at £10,000 and a NaN
  // would arrive as a 400 that tells the provider nothing useful.
  if (pounds == null || pounds < 0 || pounds > 10000) return null;

  return QuoteResult(pence: (pounds * 100).round(), isFinal: isFinal);
}

/// The figure as the buyer will read it — used in the confirmation toast, so
/// a provider sees the rounded value that was actually stored.
String quoteConfirmation(QuoteResult result) =>
    '${result.isFinal ? 'Final price' : 'Quote'} set to '
    '${formatPence(result.pence)}';
