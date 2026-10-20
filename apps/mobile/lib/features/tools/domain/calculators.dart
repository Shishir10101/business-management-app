/// Everyday business calculators: EMI, interest, and profit.
///
/// Deliberately dependency-free and side-effect-free so the logic is unit
/// testable without a widget pump. Inputs are rupees as doubles: these are
/// scratchpad tools, not ledger data, so the "money is never a float" rule
/// that governs persistence does not apply here. Nothing this module
/// computes is ever stored or transmitted.
library;

/// A single calculator result line: a label plus a formatted rupee value.
class CalcResult {
  const CalcResult(this.label, this.value);

  final String label;
  final double value;
}

/// Equated Monthly Instalment for a reducing-balance loan.
///
/// Uses the standard formula EMI = P·r·(1+r)ⁿ / ((1+r)ⁿ − 1), where r is the
/// monthly rate and n the number of months. A zero rate is handled
/// separately because the formula divides by zero there.
class EmiCalculator {
  const EmiCalculator._();

  static EmiBreakdown calculate({
    required double principal,
    required double annualRatePercent,
    required int months,
  }) {
    if (months <= 0 || principal <= 0) {
      return const EmiBreakdown(
        monthlyEmi: 0,
        totalPayment: 0,
        totalInterest: 0,
      );
    }

    final monthlyRate = annualRatePercent / 12 / 100;

    final double emi;
    if (monthlyRate == 0) {
      emi = principal / months;
    } else {
      final growth = _pow(1 + monthlyRate, months);
      emi = principal * monthlyRate * growth / (growth - 1);
    }

    final totalPayment = emi * months;
    return EmiBreakdown(
      monthlyEmi: emi,
      totalPayment: totalPayment,
      totalInterest: totalPayment - principal,
    );
  }
}

/// The three numbers a borrower actually cares about.
class EmiBreakdown {
  const EmiBreakdown({
    required this.monthlyEmi,
    required this.totalPayment,
    required this.totalInterest,
  });

  final double monthlyEmi;
  final double totalPayment;
  final double totalInterest;
}

/// Simple and compound interest on a lump sum.
class InterestCalculator {
  const InterestCalculator._();

  /// I = P · r · t / 100
  static double simple({
    required double principal,
    required double annualRatePercent,
    required double years,
  }) {
    if (principal <= 0 || years <= 0) return 0;
    return principal * annualRatePercent * years / 100;
  }

  /// A = P · (1 + r/n)^(n·t), where n is compounding periods per year.
  static double compound({
    required double principal,
    required double annualRatePercent,
    required double years,
    int compoundingPerYear = 1,
  }) {
    if (principal <= 0 || years <= 0 || compoundingPerYear <= 0) return 0;
    final rate = annualRatePercent / 100 / compoundingPerYear;
    final periods = compoundingPerYear * years;
    return principal * (_pow(1 + rate, periods.round()) - 1);
  }
}

/// Profit, margin and markup from a cost and a selling price.
///
/// Margin and markup are different questions and both get asked:
/// margin = profit ÷ selling price, markup = profit ÷ cost.
class ProfitCalculator {
  const ProfitCalculator._();

  static ProfitBreakdown calculate({
    required double cost,
    required double sellingPrice,
  }) {
    final profit = sellingPrice - cost;
    return ProfitBreakdown(
      profit: profit,
      // Guard the divide: a zero cost or price makes the ratios meaningless
      // rather than infinite.
      marginPercent: sellingPrice == 0 ? 0 : profit / sellingPrice * 100,
      markupPercent: cost == 0 ? 0 : profit / cost * 100,
    );
  }
}

class ProfitBreakdown {
  const ProfitBreakdown({
    required this.profit,
    required this.marginPercent,
    required this.markupPercent,
  });

  final double profit;
  final double marginPercent;
  final double markupPercent;
}

/// Integer power, used instead of `dart:math`'s `pow` so the result stays a
/// plain `double` and callers never have to unwrap a `num`.
double _pow(double base, int exponent) {
  var result = 1.0;
  for (var i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
