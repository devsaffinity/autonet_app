import 'package:autonect/domain/reg_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normaliseReg', () {
    test('uppercases and strips whitespace, as the server does first', () {
      expect(normaliseReg('lr19 abc'), 'LR19ABC');
      expect(normaliseReg('  lm19   xyz '), 'LM19XYZ');
      expect(normaliseReg('AB12CDE'), 'AB12CDE');
    });
  });

  group('isValidReg', () {
    test('accepts what the server accepts after normalisation', () {
      expect(isValidReg('lr19 abc'), isTrue);
      expect(isValidReg('AB'), isTrue, reason: 'two chars is the minimum');
      expect(isValidReg('ABCD1234'), isTrue, reason: 'eight is the maximum');
    });

    test('rejects empty, over-long and punctuated input', () {
      expect(isValidReg(''), isFalse);
      expect(isValidReg('A'), isFalse);
      expect(isValidReg('ABCD12345'), isFalse, reason: 'nine chars');
      expect(isValidReg('AB-12'), isFalse, reason: 'hyphen is not [A-Z0-9]');
      expect(isValidReg('A.B12'), isFalse, reason: 'dot is not [A-Z0-9]');
    });
  });
}
