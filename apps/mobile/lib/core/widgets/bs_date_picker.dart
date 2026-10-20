import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/nepali_date_utils.dart';

/// Opens a Bikram Sambat date picker and returns the picked date as an AD
/// [DateTime] — the app's canonical wire format — or `null` when dismissed.
///
/// The picker speaks BS natively: year, month and day are chosen in BS, with
/// the day count following the real BS month length, because for a Nepali
/// user the BS date *is* the date. AD never leaves this boundary; everything
/// downstream keeps storing and transmitting AD.
///
/// [firstDate] / [lastDate] are AD bounds (like `showDatePicker`); they are
/// converted to BS and used to clamp the year wheel. Out-of-range bounds
/// degrade to a ±5 year window around the initial date rather than throwing —
/// `nepali_utils` asserts outside BS 1970-2250 and a picker must never take
/// a page down.
Future<DateTime?> showBsDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
  bool nepaliDigits = false,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _BsDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      nepaliDigits: nepaliDigits,
    ),
  );
}

/// Opens a Bikram Sambat date-RANGE picker and returns the picked range as
/// AD [DateTimeRange]s, or null when dismissed.
///
/// Two steps on one dialog — pick the From date, then the To date — so the
/// six wheels (three per endpoint) never crowd a phone screen. The To step
/// starts on the From date; Confirm stays disabled while To precedes From.
Future<DateTimeRange?> showBsDateRangePicker({
  required BuildContext context,
  required DateTime initialFrom,
  required DateTime initialTo,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
  bool nepaliDigits = false,
}) {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (context) => _BsDateRangePickerDialog(
      initialFrom: initialFrom,
      initialTo: initialTo,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
      nepaliDigits: nepaliDigits,
    ),
  );
}

// ---------------------------------------------------------------------------
// Single-date picker
// ---------------------------------------------------------------------------

class _BsDatePickerDialog extends StatefulWidget {
  const _BsDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    required this.nepaliDigits,
  });

  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? title;
  final bool nepaliDigits;

  @override
  State<_BsDatePickerDialog> createState() => _BsDatePickerDialogState();
}

class _BsDatePickerDialogState extends State<_BsDatePickerDialog> {
  static const _wheelHeight = 190.0;

  late List<int> _years;
  late int _year;
  late int _month;
  late int _day;
  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;

  @override
  void initState() {
    super.initState();
    final initial =
        tryToBs(widget.initialDate) ?? tryToBs(DateTime.now())!;
    _year = initial.year;
    _month = initial.month;
    _day = initial.day;

    // Year wheel bounds: the AD bounds mapped to BS, else ±5 years. An AD
    // bound outside the BS table yields null and falls back to the window.
    final firstBs =
        widget.firstDate != null ? tryToBs(widget.firstDate!) : null;
    final lastBs = widget.lastDate != null ? tryToBs(widget.lastDate!) : null;
    final lo = firstBs?.year ?? _year - 5;
    final hi = lastBs?.year ?? _year + 5;
    _years = [for (var y = lo; y <= hi; y++) y];

    _yearController = FixedExtentScrollController(
      initialItem: _clamp(_years.indexOf(_year), _years.length),
    );
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(
      initialItem: _clamp(_day - 1, _daysInSelectedMonth()),
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  int _clamp(int index, int itemCount) =>
      index.clamp(0, itemCount - 1).toInt();

  int _daysInSelectedMonth() => bsDaysInMonth(_year, _month) ?? 30;

  void _onYearChanged(int index) {
    setState(() {
      _year = _years[index];
      _clampDay();
    });
  }

  void _onMonthChanged(int index) {
    setState(() {
      _month = index + 1;
      _clampDay();
    });
  }

  void _onDayChanged(int index) {
    setState(() => _day = index + 1);
  }

  /// A BS month is 29-32 days, so changing year or month can invalidate the
  /// day. Clamp in state and pull the wheel along with it.
  void _clampDay() {
    final days = _daysInSelectedMonth();
    if (_day > days) {
      _day = days;
      _dayController.jumpToItem(_day - 1);
    }
  }

  void _selectToday() {
    final today = tryToBs(DateTime.now());
    if (today == null) return;
    setState(() {
      _year = _clampYear(today.year);
      _month = today.month;
      _day = _clampDayFor(_year, _month, today.day);
      _yearController.jumpToItem(_years.indexOf(_year));
      _monthController.jumpToItem(_month - 1);
      _dayController.jumpToItem(_day - 1);
    });
  }

  int _clampYear(int year) => year.clamp(_years.first, _years.last).toInt();

  int _clampDayFor(int year, int month, int day) {
    final days = bsDaysInMonth(year, month) ?? 30;
    return day.clamp(1, days).toInt();
  }

  void _confirm() {
    final ad = tryToAd(_year, _month, _day);
    if (ad == null) return;
    Navigator.of(context).pop(ad);
  }

  String _digits(int value) =>
      widget.nepaliDigits ? toDevanagariDigits(value.toString()) : '$value';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final valid = tryToAd(_year, _month, _day) != null;

    return AlertDialog(
      title: Text(widget.title ?? l10n.dateLabel),
      content: SizedBox(
        width: 300,
        height: _wheelHeight,
        child: Row(
          children: [
            _BsWheel(
              controller: _yearController,
              itemCount: _years.length,
              label: (i) => _digits(_years[i]),
              onChanged: _onYearChanged,
              theme: theme,
            ),
            _BsWheel(
              controller: _monthController,
              itemCount: 12,
              label: (i) =>
                  bsMonthName(i + 1, nepali: widget.nepaliDigits),
              onChanged: _onMonthChanged,
              theme: theme,
            ),
            _BsWheel(
              controller: _dayController,
              itemCount: _daysInSelectedMonth(),
              label: (i) => _digits(i + 1),
              onChanged: _onDayChanged,
              theme: theme,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _selectToday,
          child: Text(l10n.today),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: valid ? _confirm : null,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Range picker (two steps: From, then To)
// ---------------------------------------------------------------------------

class _BsDateRangePickerDialog extends StatefulWidget {
  const _BsDateRangePickerDialog({
    required this.initialFrom,
    required this.initialTo,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    required this.nepaliDigits,
  });

  final DateTime initialFrom;
  final DateTime initialTo;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? title;
  final bool nepaliDigits;

  @override
  State<_BsDateRangePickerDialog> createState() =>
      _BsDateRangePickerDialogState();
}

class _BsDateRangePickerDialogState
    extends State<_BsDateRangePickerDialog> {
  static const _wheelHeight = 190.0;

  /// true while editing the From endpoint.
  bool _editingFrom = true;

  late List<int> _years;
  late int _fromY;
  late int _fromM;
  late int _fromD;
  late int _toY;
  late int _toM;
  late int _toD;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  @override
  void initState() {
    super.initState();
    final from = tryToBs(widget.initialFrom) ?? tryToBs(DateTime.now())!;
    final to = tryToBs(widget.initialTo) ?? from;
    _fromY = from.year;
    _fromM = from.month;
    _fromD = from.day;
    // To never precedes From on open.
    _toY = to.isBefore(from) ? from.year : to.year;
    _toM = to.isBefore(from) ? from.month : to.month;
    _toD = to.isBefore(from) ? from.day : to.day;

    final firstBs =
        widget.firstDate != null ? tryToBs(widget.firstDate!) : null;
    final lastBs = widget.lastDate != null ? tryToBs(widget.lastDate!) : null;
    final lo = firstBs?.year ?? _fromY - 5;
    final hi = lastBs?.year ?? _fromY + 5;
    _years = [for (var y = lo; y <= hi; y++) y];

    _yearController =
        FixedExtentScrollController(initialItem: _clamp(_years.indexOf(_fromY)));
    _monthController =
        FixedExtentScrollController(initialItem: _fromM - 1);
    _dayController =
        FixedExtentScrollController(initialItem: _clamp(_fromD - 1));
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  int _clamp(int index, [int itemCount = 32]) =>
      index.clamp(0, itemCount - 1).toInt();

  int get _editingYear => _editingFrom ? _fromY : _toY;
  int get _editingMonth => _editingFrom ? _fromM : _toM;
  int get _editingDay => _editingFrom ? _fromD : _toD;

  int _daysInSelectedMonth() =>
      bsDaysInMonth(_editingYear, _editingMonth) ?? 30;

  void _setEditing(
      {required int year, required int month, required int day}) {
    if (_editingFrom) {
      _fromY = year;
      _fromM = month;
      _fromD = day;
    } else {
      _toY = year;
      _toM = month;
      _toD = day;
    }
  }

  void _onYearChanged(int index) {
    setState(() {
      final days = bsDaysInMonth(_years[index], _editingMonth) ?? 30;
      _setEditing(
        year: _years[index],
        month: _editingMonth,
        day: _editingDay > days ? days : _editingDay,
      );
    });
  }

  void _onMonthChanged(int index) {
    setState(() {
      final month = index + 1;
      final days = bsDaysInMonth(_editingYear, month) ?? 30;
      _setEditing(
        year: _editingYear,
        month: month,
        day: _editingDay > days ? days : _editingDay,
      );
    });
  }

  void _onDayChanged(int index) {
    setState(() => _setEditing(
          year: _editingYear,
          month: _editingMonth,
          day: index + 1,
        ));
  }

  void _switchStep() {
    setState(() {
      _editingFrom = !_editingFrom;
      final y = _editingYear;
      final m = _editingMonth;
      final d = _editingDay;
      _yearController.jumpToItem(_clamp(_years.indexOf(y)));
      _monthController.jumpToItem(m - 1);
      _dayController.jumpToItem(_clamp(d - 1));
    });
  }

  DateTime? get _fromAd => tryToAd(_fromY, _fromM, _fromD);
  DateTime? get _toAd => tryToAd(_toY, _toM, _toD);

  bool get _valid =>
      _fromAd != null && _toAd != null && !_toAd!.isBefore(_fromAd!);

  void _confirm() {
    final from = _fromAd;
    final to = _toAd;
    if (from == null || to == null || to.isBefore(from)) return;
    Navigator.of(context).pop(DateTimeRange(start: from, end: to));
  }

  String _digits(int value) =>
      widget.nepaliDigits ? toDevanagariDigits(value.toString()) : '$value';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title ?? l10n.dateLabel),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.fromDate),
                  icon: const Icon(Icons.calendar_today, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.toDate),
                  icon: const Icon(Icons.event, size: 16),
                ),
              ],
              selected: {_editingFrom},
              onSelectionChanged: (_) => _switchStep(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _wheelHeight,
              child: Row(
                children: [
                  _BsWheel(
                    controller: _yearController,
                    itemCount: _years.length,
                    label: (i) => _digits(_years[i]),
                    onChanged: _onYearChanged,
                    theme: theme,
                  ),
                  _BsWheel(
                    controller: _monthController,
                    itemCount: 12,
                    label: (i) => bsMonthName(
                        i + 1,
                        nepali: widget.nepaliDigits),
                    onChanged: _onMonthChanged,
                    theme: theme,
                  ),
                  _BsWheel(
                    controller: _dayController,
                    itemCount: _daysInSelectedMonth(),
                    label: (i) => _digits(i + 1),
                    onChanged: _onDayChanged,
                    theme: theme,
                  ),
                ],
              ),
            ),
            if (!_valid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.endBeforeStart,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _switchStep,
          child: Text(_editingFrom ? l10n.next : l10n.back),
        ),
        TextButton(
          onPressed: _valid ? _confirm : null,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared wheel
// ---------------------------------------------------------------------------

/// One scrollable column of the BS picker. Shared by the single-date and
/// range dialogs so both speak the same BS calendar UI.
class _BsWheel extends StatelessWidget {
  const _BsWheel({
    required this.controller,
    required this.itemCount,
    required this.label,
    required this.onChanged,
    required this.theme,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) label;
  final ValueChanged<int> onChanged;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        diameterRatio: 1.3,
        perspective: 0.004,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (context, index) => Center(
            child: Text(
              label(index),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
