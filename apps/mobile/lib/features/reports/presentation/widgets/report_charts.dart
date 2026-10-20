import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/format_utils.dart';
import '../../../../l10n/app_localizations.dart';
import 'report_widgets.dart';

/// Trend line chart for a report series. [valuesRupees] is plotted on the
/// y-axis; the y-axis is labelled in rupees via [unitSuffix].
class ReportLineChart extends StatelessWidget {
  final List<double> valuesRupees;
  final double height;

  const ReportLineChart({
    super.key,
    required this.valuesRupees,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    if (valuesRupees.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return SizedBox(
        height: height,
        child: Center(child: ReportEmptyLine(message: l10n.noDataInRange)),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < valuesRupees.length; i++)
        FlSpot(i.toDouble(), valuesRupees[i]),
    ];

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        child: LineChart(
          LineChartData(
            minY: 0,
            lineTouchData: LineTouchData(enabled: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              // Theme-aware: a hardcoded grey grid vanishes on a dark
              // surface, so derive it from the current ColorScheme.
              getDrawingHorizontalLine: (value) => FlLine(
                color: Theme.of(context).colorScheme.outlineVariant,
                strokeWidth: 0.8,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.25,
                preventCurveOverShooting: true,
                barWidth: 2.5,
                color: reportColorAt(0),
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: reportColorAt(0).withOpacity(0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pie chart for a category/source breakdown, with a legend underneath.
class ReportPieChart extends StatelessWidget {
  final List<PieSlice> slices;

  const ReportPieChart({super.key, required this.slices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    if (slices.isEmpty || total <= 0) {
      return ReportEmptyLine(
          message: AppLocalizations.of(context).nothingToBreakDown);
    }

    return Column(
      children: [
        RepaintBoundary(
          child: SizedBox(
            height: 170,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                sections: [
                  for (var i = 0; i < slices.length; i++)
                    PieChartSectionData(
                      value: slices[i].value,
                      color: slices[i].color,
                      radius: 16,
                      title: '',
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < slices.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: slices[i].color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slices[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '${((slices[i].value / total) * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Text(
                  formatPaisa(slices[i].paisa),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One slice of a [ReportPieChart]. [paisa] is the amount, [value] the share.
class PieSlice {
  final String label;
  final int paisa;
  final double value;
  final Color color;

  const PieSlice({
    required this.label,
    required this.paisa,
    required this.value,
    required this.color,
  });
}

/// Horizontal-ish bar chart for ranked figures (top products, expenses).
class ReportBarChart extends StatelessWidget {
  final List<double> valuesRupees;
  final double height;

  const ReportBarChart({
    super.key,
    required this.valuesRupees,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    if (valuesRupees.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return SizedBox(
        height: height,
        child: Center(child: ReportEmptyLine(message: l10n.noDataInRange)),
      );
    }

    final maxY = valuesRupees.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 1 : maxY * 1.15,
          barTouchData: BarTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade300, strokeWidth: 0.8),
          ),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          barGroups: [
            for (var i = 0; i < valuesRupees.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: valuesRupees[i],
                    color: reportColorAt(i),
                    width: 14,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
