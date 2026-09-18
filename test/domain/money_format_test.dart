import 'package:autonect/domain/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatPence', () {
    test('renders GBP from integer pence', () {
      expect(formatPence(0), '£0.00');
      expect(formatPence(5), '£0.05');
      expect(formatPence(99), '£0.99');
      expect(formatPence(100), '£1.00');
      expect(formatPence(3200), '£32.00');
    });

    test('groups thousands without package:intl', () {
      expect(formatPence(100000), '£1,000.00');
      expect(formatPence(123456), '£1,234.56');
      expect(formatPence(325000), '£3,250.00');
      expect(formatPence(123456789), '£1,234,567.89');
    });

    test('handles a negative amount rather than printing £-1.00', () {
      expect(formatPence(-100), '-£1.00');
    });
  });

  group('formatPriceTag', () {
    test('drops the pence on a whole-pound price', () {
      expect(formatPriceTag(14900), '£149');
      expect(formatPriceTag(1000), '£10');
      expect(formatPriceTag(0), '£0');
      expect(formatPriceTag(129900), '£1,299');
    });

    test('keeps the pence otherwise', () {
      expect(formatPriceTag(1299), '£12.99');
      expect(formatPriceTag(50), '£0.50');
    });
  });
}
