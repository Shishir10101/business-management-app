import 'package:flutter_test/flutter_test.dart';
import 'package:khata/features/tools/domain/calculators.dart';

/// The calculators are the app's pure-math surface, so they get real numeric
/// assertions rather than smoke tests.
void main() {
  group('EMI', () {
    test('matches the standard worked example', () {
      // Rs 100,000 at 12% for 12 months → EMI ≈ 8,884.88.
      final r = EmiCalculator.calculate(
        principal: 100000,
        annualRatePercent: 12,
        months: 12,
      );

      expect(r.monthlyEmi, closeTo(8884.88, 0.05));
      expect(r.totalPayment, closeTo(106618.55, 0.5));
      expect(r.totalInterest, closeTo(6618.55, 0.5));
    });

    test('a zero-interest loan is a straight division', () {
      final r = EmiCalculator.calculate(
        principal: 120000,
        annualRatePercent: 0,
        months: 12,
      );

      expect(r.monthlyEmi, 10000);
      expect(r.totalInterest, 0);
      expect(r.totalPayment, 120000);
    });

    test('longer terms lower the EMI but raise the total interest', () {
      final short = EmiCalculator.calculate(
        principal: 500000, annualRatePercent: 14, months: 24);
      final long = EmiCalculator.calculate(
        principal: 500000, annualRatePercent: 14, months: 60);

      expect(long.monthlyEmi, lessThan(short.monthlyEmi));
      expect(long.totalInterest, greaterThan(short.totalInterest));
    });

    test('degenerate input returns zeros instead of throwing', () {
      expect(
        EmiCalculator.calculate(
          principal: 0, annualRatePercent: 10, months: 12).monthlyEmi,
        0);
      expect(
        EmiCalculator.calculate(
          principal: 1000, annualRatePercent: 10, months: 0).monthlyEmi,
        0);
    });
  });

  group('interest', () {
    test('simple interest is linear in time', () {
      expect(
        InterestCalculator.simple(
          principal: 100000, annualRatePercent: 10, years: 2),
        closeTo(20000, 0.001));
      expect(
        InterestCalculator.simple(
          principal: 100000, annualRatePercent: 10, years: 3),
        closeTo(30000, 0.001));
    });

    test('compound interest beats simple over time', () {
      final simple = InterestCalculator.simple(
        principal: 100000, annualRatePercent: 10, years: 3);
      final compound = InterestCalculator.compound(
        principal: 100000, annualRatePercent: 10, years: 3);

      expect(compound, greaterThan(simple));
      expect(compound, closeTo(33100, 1));
    });

    test('more frequent compounding earns more', () {
      final annual = InterestCalculator.compound(
        principal: 100000, annualRatePercent: 12, years: 2, compoundingPerYear: 1);
      final quarterly = InterestCalculator.compound(
        principal: 100000, annualRatePercent: 12, years: 2, compoundingPerYear: 4);

      expect(quarterly, greaterThan(annual));
    });

    test('degenerate input returns zero', () {
      expect(
        InterestCalculator.simple(
          principal: 0, annualRatePercent: 10, years: 5),
        0);
      expect(
        InterestCalculator.compound(
          principal: 1000, annualRatePercent: 10, years: 0),
        0);
    });
  });

  group('profit', () {
    test('computes profit, margin and markup', () {
      final r = ProfitCalculator.calculate(cost: 80, sellingPrice: 100);

      expect(r.profit, 20);
      expect(r.marginPercent, closeTo(20, 0.0001));
      expect(r.markupPercent, closeTo(25, 0.0001));
    });

    test('a loss produces a negative profit and negative ratios', () {
      final r = ProfitCalculator.calculate(cost: 100, sellingPrice: 80);

      expect(r.profit, -20);
      expect(r.marginPercent, closeTo(-25, 0.0001));
      expect(r.markupPercent, closeTo(-20, 0.0001));
    });

    test('zero cost or price yields zero ratios rather than infinity', () {
      expect(ProfitCalculator.calculate(cost: 0, sellingPrice: 100).marginPercent,
          100);
      expect(ProfitCalculator.calculate(cost: 100, sellingPrice: 0).marginPercent,
          0);
      expect(ProfitCalculator.calculate(cost: 0, sellingPrice: 0).marginPercent, 0);
    });
  });
}
