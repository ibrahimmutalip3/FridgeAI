import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_ai/models/scan_result.dart';

void main() {
  group('ScanResult.fromAiJson', () {
    test('parses a well-formed detection response', () {
      final result = ScanResult.fromAiJson(const {
        'ingredients': [
          {'name': 'Eggs', 'quantity': '6', 'category': 'dairy'},
          {'name': 'Tomatoes', 'quantity': '3', 'category': 'vegetables'},
        ],
        'note': 'Looks like a well-stocked fridge!',
      });

      expect(result.success, isTrue);
      expect(result.ingredients, hasLength(2));
      expect(result.ingredients.first.name, 'Eggs');
      expect(result.rawNote, 'Looks like a well-stocked fridge!');
      expect(result.errorMessage, isNull);
    });

    test('fails gracefully when "ingredients" is missing', () {
      final result = ScanResult.fromAiJson(const <String, dynamic>{'note': 'nothing here'});
      expect(result.success, isFalse);
      expect(result.ingredients, isEmpty);
      expect(result.errorMessage, isNotNull);
    });

    test('fails gracefully when "ingredients" is an empty list', () {
      final result = ScanResult.fromAiJson(const {'ingredients': <dynamic>[]});
      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('fails gracefully when "ingredients" is the wrong type', () {
      final result = ScanResult.fromAiJson(const {'ingredients': 'not a list'});
      expect(result.success, isFalse);
    });

    test('skips malformed entries but keeps valid ones', () {
      final result = ScanResult.fromAiJson(const {
        'ingredients': [
          {'name': 'Milk', 'quantity': '1 bottle'},
          'not a map',
          42,
        ],
      });
      expect(result.success, isTrue);
      expect(result.ingredients, hasLength(1));
      expect(result.ingredients.first.name, 'Milk');
    });

    test('never throws on a completely malformed payload', () {
      expect(() => ScanResult.fromAiJson(const <String, dynamic>{}), returnsNormally);
      expect(() => ScanResult.fromAiJson(const {'ingredients': null}), returnsNormally);
    });
  });

  group('ScanResult.empty', () {
    test('produces an unsuccessful result carrying the given message', () {
      final result = ScanResult.empty('Something went wrong.');
      expect(result.success, isFalse);
      expect(result.errorMessage, 'Something went wrong.');
      expect(result.ingredients, isEmpty);
    });
  });
}
