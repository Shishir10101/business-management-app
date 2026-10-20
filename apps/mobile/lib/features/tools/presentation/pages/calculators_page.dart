import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/calculators.dart';

/// Everyday business calculators — the tools a shopkeeper reaches for when a
/// customer asks "what will the instalment be?" or "am I making money on this?"
///
/// Pure presentation: all the arithmetic lives in [calculators.dart], which is
/// unit tested on its own.
class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage({super.key});

  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.toolsTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.emiCalculator),
            Tab(text: l10n.interestCalculator),
            Tab(text: l10n.profitCalculator),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _EmiTab(),
          _InterestTab(),
          _ProfitTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared input + result widgets
// ---------------------------------------------------------------------------

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // Numeric only: these are money/rate fields, and letters would just be
      // rejected by the parsers downstream.
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value, {this.emphasise = false});

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(
            value,
            style: emphasise
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// Rupees with thousands separators, two decimals.
String _rs(double value) =>
    'Rs ${value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';

double? _parse(TextEditingController c) => double.tryParse(c.text.trim());

// ---------------------------------------------------------------------------
// EMI
// ---------------------------------------------------------------------------

class _EmiTab extends StatefulWidget {
  const _EmiTab();

  @override
  State<_EmiTab> createState() => _EmiTabState();
}

class _EmiTabState extends State<_EmiTab> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _months = TextEditingController();
  EmiBreakdown? _result;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _months.dispose();
    super.dispose();
  }

  void _calculate() {
    final l10n = AppLocalizations.of(context);
    final p = _parse(_principal);
    final r = _parse(_rate);
    final m = int.tryParse(_months.text.trim());
    if (p == null || r == null || m == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.enterValidAmount)));
      return;
    }
    setState(() => _result = EmiCalculator.calculate(
          principal: p,
          annualRatePercent: r,
          months: m,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CalcForm(
      fields: [
        _AmountField(controller: _principal, label: l10n.loanAmount),
        _AmountField(controller: _rate, label: l10n.annualInterestRate, suffix: '%'),
        _AmountField(controller: _months, label: l10n.loanTermMonths),
      ],
      onCalculate: _calculate,
      results: [
        if (_result != null) ...[
          _ResultRow(l10n.monthlyEmi, _rs(_result!.monthlyEmi), emphasise: true),
          _ResultRow(l10n.totalPayment, _rs(_result!.totalPayment)),
          _ResultRow(l10n.totalInterest, _rs(_result!.totalInterest)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Interest
// ---------------------------------------------------------------------------

class _InterestTab extends StatefulWidget {
  const _InterestTab();

  @override
  State<_InterestTab> createState() => _InterestTabState();
}

class _InterestTabState extends State<_InterestTab> {
  final _principal = TextEditingController();
  final _rate = TextEditingController();
  final _years = TextEditingController();
  bool _compound = false;

  @override
  void dispose() {
    _principal.dispose();
    _rate.dispose();
    _years.dispose();
    super.dispose();
  }

  void _calculate() {
    final l10n = AppLocalizations.of(context);
    final p = _parse(_principal);
    final r = _parse(_rate);
    final y = _parse(_years);
    if (p == null || r == null || y == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.enterValidAmount)));
      return;
    }
    setState(() {
      _interest = _compound
          ? InterestCalculator.compound(
              principal: p, annualRatePercent: r, years: y)
          : InterestCalculator.simple(
              principal: p, annualRatePercent: r, years: y);
      _principalValue = p;
    });
  }

  double? _interest;
  double _principalValue = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _CalcForm(
      fields: [
        _AmountField(controller: _principal, label: l10n.principal),
        _AmountField(controller: _rate, label: l10n.annualInterestRate, suffix: '%'),
        _AmountField(controller: _years, label: l10n.years),
        SwitchListTile(
          title: Text(l10n.compoundInterest),
          value: _compound,
          onChanged: (v) => setState(() => _compound = v),
          contentPadding: EdgeInsets.zero,
        ),
      ],
      onCalculate: _calculate,
      results: [
        if (_interest != null) ...[
          _ResultRow(
            _compound ? l10n.compoundInterest : l10n.simpleInterest,
            _rs(_interest!),
            emphasise: true,
          ),
          _ResultRow(l10n.maturityAmount, _rs(_principalValue + _interest!)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profit
// ---------------------------------------------------------------------------

class _ProfitTab extends StatefulWidget {
  const _ProfitTab();

  @override
  State<_ProfitTab> createState() => _ProfitTabState();
}

class _ProfitTabState extends State<_ProfitTab> {
  final _cost = TextEditingController();
  final _selling = TextEditingController();
  ProfitBreakdown? _result;

  @override
  void dispose() {
    _cost.dispose();
    _selling.dispose();
    super.dispose();
  }

  void _calculate() {
    final l10n = AppLocalizations.of(context);
    final c = _parse(_cost);
    final s = _parse(_selling);
    if (c == null || s == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.enterValidAmount)));
      return;
    }
    setState(() => _result = ProfitCalculator.calculate(cost: c, sellingPrice: s));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _CalcForm(
      fields: [
        _AmountField(controller: _cost, label: l10n.costPrice),
        _AmountField(controller: _selling, label: l10n.sellingPrice),
      ],
      onCalculate: _calculate,
      results: [
        if (_result != null) ...[
          _ResultRow(
            l10n.profit,
            _rs(_result!.profit),
            emphasise: true,
          ),
          _ResultRow(l10n.profitMargin,
              '${_result!.marginPercent.toStringAsFixed(2)}%'),
          _ResultRow(l10n.markup, '${_result!.markupPercent.toStringAsFixed(2)}%'),
          if (_result!.profit < 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.lossWarning,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form shell
// ---------------------------------------------------------------------------

class _CalcForm extends StatelessWidget {
  const _CalcForm({
    required this.fields,
    required this.onCalculate,
    required this.results,
  });

  final List<Widget> fields;
  final VoidCallback onCalculate;
  final List<Widget> results;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...fields,
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onCalculate,
          icon: const Icon(Icons.calculate_outlined),
          label: Text(l10n.calculate),
        ),
        if (results.isNotEmpty) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: results,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
