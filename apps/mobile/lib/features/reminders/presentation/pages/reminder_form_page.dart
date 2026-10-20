import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/calendar_provider.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/utils/nepali_date_utils.dart';
import '../../../../core/widgets/app_date_field.dart';
import '../../../../core/widgets/khata_snackbars.dart';
import '../../data/repositories/reminder_repository_impl.dart';
import '../../domain/entities/reminder_entity.dart';
import '../providers/reminder_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Create or edit a reminder. Saving reschedules, which reopens a completed
/// reminder — the server treats an update as "this is live again".
class ReminderFormPage extends ConsumerStatefulWidget {
  const ReminderFormPage({super.key, this.reminderId});

  /// Null when creating.
  final int? reminderId;

  @override
  ConsumerState<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends ConsumerState<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dueAt = _nextWholeHour();
  ReminderRepeat _repeat = ReminderRepeat.none;
  bool _saving = false;
  bool _loading = false;

  bool get _isEdit => widget.reminderId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final reminder = await ref
          .read(reminderRepositoryProvider)
          .getReminder(widget.reminderId!);
      if (!mounted) return;
      setState(() {
        _titleController.text = reminder.title;
        _notesController.text = reminder.notes ?? '';
        _dueAt = reminder.dueAt;
        _repeat = reminder.repeat;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showErrorSnackBar(context, '$e');
    }
  }

  /// Sensible default: the next hour boundary, so a fresh reminder is not
  /// instantly overdue.
  static DateTime _nextWholeHour() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editReminder : l10n.newReminder),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: l10n.titleRequired,
                      hintText: l10n.reminderTitleHint,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? l10n.reminderTitleRequired
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(labelText: l10n.notes),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: Text(l10n.dueDate),
                    subtitle: Text(_formatDate(_dueAt)),
                    onTap: _pickDate,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(l10n.dueTime),
                    subtitle: Text(_formatTime(_dueAt)),
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ReminderRepeat>(
                    value: _repeat,
                    decoration: InputDecoration(labelText: l10n.repeat),
                    items: ReminderRepeat.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.label(l10n)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _repeat = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_repeat != ReminderRepeat.none)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.recurringNote,
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? l10n.saving : l10n.saveReminder),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showAppDatePicker(
      context: context,
      calendar: ref.read(calendarProvider),
      initialDate: _dueAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      nepaliDigits: ref.read(localeProvider).languageCode == 'ne',
    );
    if (picked == null) return;
    setState(() {
      _dueAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dueAt.hour,
        _dueAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (picked == null) return;
    setState(() {
      _dueAt = DateTime(
        _dueAt.year,
        _dueAt.month,
        _dueAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repository = ref.read(reminderRepositoryProvider);
      final title = _titleController.text.trim();
      final notes = _notesController.text.trim();

      if (_isEdit) {
        await repository.updateReminder(
          widget.reminderId!,
          title: title,
          dueAt: _dueAt,
          notes: notes.isEmpty ? null : notes,
          repeat: _repeat,
        );
      } else {
        await repository.createReminder(
          title: title,
          dueAt: _dueAt,
          notes: notes.isEmpty ? null : notes,
          repeat: _repeat,
        );
      }

      refreshReminders(ref);
      if (mounted) {
        showInfoSnackBar(context, l10n.reminderSaved);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showErrorSnackBar(context, '$e');
      }
    }
  }

  String _formatDate(DateTime value) => formatDisplayDate(
        value,
        nepaliDigits: ref.read(localeProvider).languageCode == 'ne',
      );

  static String _formatTime(DateTime value) {
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final suffix = value.hour < 12 ? 'AM' : 'PM';
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $suffix';
  }
}
