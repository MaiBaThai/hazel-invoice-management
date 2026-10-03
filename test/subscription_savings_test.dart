import 'package:flutter_test/flutter_test.dart';
import 'package:nms/core/providers/subscription_provider.dart';

void main() {
  group('Subscription Savings & Pricing Calculations', () {
    test('Calculates US plan discount percentage accurately (Target ~42%)', () {
      // US: Monthly $9.99, Yearly $69.99
      final percent = SubscriptionProvider.calculateSavingsPercent(9.99, 69.99);
      expect(percent, isNotNull);
      // (9.99 * 12 - 69.99) / (9.99 * 12) = 49.89 / 119.88 = 41.6166% -> rounded to 42%
      expect(percent, equals(42));
    });

    test('Calculates VN plan discount percentage accurately (Target ~44%)', () {
      // VN: Monthly 299,000 đ, Yearly 1,999,000 đ
      final percent = SubscriptionProvider.calculateSavingsPercent(299000.0, 1999000.0);
      expect(percent, isNotNull);
      // (299000 * 12 - 1999000) / (299000 * 12) = 1,589,000 / 3,588,000 = 44.2865% -> rounded to 44%
      expect(percent, equals(44));
    });

    test('Returns null when no discount exists (annual >= 12x monthly)', () {
      final percentEqual = SubscriptionProvider.calculateSavingsPercent(10.0, 120.0);
      expect(percentEqual, isNull);

      final percentMoreExpensive = SubscriptionProvider.calculateSavingsPercent(10.0, 150.0);
      expect(percentMoreExpensive, isNull);
    });

    test('Returns null when prices are invalid or zero', () {
      expect(SubscriptionProvider.calculateSavingsPercent(0.0, 10.0), isNull);
      expect(SubscriptionProvider.calculateSavingsPercent(-5.0, 10.0), isNull);
    });

    test('Formats VND currency amounts with comma separators properly', () {
      expect(SubscriptionProvider.formatVnd(167000), equals('167,000'));
      expect(SubscriptionProvider.formatVnd(1999000), equals('1,999,000'));
      expect(SubscriptionProvider.formatVnd(299000), equals('299,000'));
      expect(SubscriptionProvider.formatVnd(500), equals('500'));
    });
  });
}
