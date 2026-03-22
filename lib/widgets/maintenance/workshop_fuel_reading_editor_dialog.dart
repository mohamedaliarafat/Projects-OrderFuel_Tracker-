import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/providers/workshop_fuel_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:provider/provider.dart';

Future<bool?> showWorkshopFuelReadingEditorDialog(
  BuildContext context, {
  required String stationId,
  String? stationName,
  Map<String, dynamic>? existingReading,
  double? suggestedPreviousReading,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _WorkshopFuelReadingEditorDialog(
      stationId: stationId,
      stationName: stationName,
      existingReading: existingReading,
      suggestedPreviousReading: suggestedPreviousReading,
    ),
  );
}

class _WorkshopFuelReadingEditorDialog extends StatefulWidget {
  const _WorkshopFuelReadingEditorDialog({
    required this.stationId,
    this.stationName,
    this.existingReading,
    this.suggestedPreviousReading,
  });

  final String stationId;
  final String? stationName;
  final Map<String, dynamic>? existingReading;
  final double? suggestedPreviousReading;

  @override
  State<_WorkshopFuelReadingEditorDialog> createState() =>
      _WorkshopFuelReadingEditorDialogState();
}

class _WorkshopFuelReadingEditorDialogState
    extends State<_WorkshopFuelReadingEditorDialog> {
  late final TextEditingController _previousController;
  late final TextEditingController _currentController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  bool _isSaving = false;

  bool get _isEditing => widget.existingReading != null;

  double _readNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    final reading = widget.existingReading;
    final previous = reading != null
        ? _readNum(reading['previousReading'])
        : (widget.suggestedPreviousReading ?? 0);
    final current = reading != null ? _readNum(reading['currentReading']) : 0.0;
    final notes = reading?['notes']?.toString() ?? '';
    final readingDate =
        DateTime.tryParse(reading?['readingDate']?.toString() ?? '') ??
        DateTime.now();

    _previousController = TextEditingController(
      text: previous > 0 ? previous.toString() : '',
    );
    _currentController = TextEditingController(
      text: current > 0 ? current.toString() : '',
    );
    _notesController = TextEditingController(text: notes);
    _selectedDate = readingDate;
  }

  @override
  void dispose() {
    _previousController.dispose();
    _currentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    final current = double.tryParse(_currentController.text.trim());
    final previousText = _previousController.text.trim();
    final previous = previousText.isEmpty ? 0.0 : double.tryParse(previousText);

    if (current == null) {
      _showError('أدخل القراءة الحالية بشكل صحيح');
      return;
    }

    if (previousText.isNotEmpty && previous == null) {
      _showError('أدخل القراءة السابقة بشكل صحيح');
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<WorkshopFuelProvider>();
    final payload = {
      'stationId': widget.stationId,
      'stationName': widget.stationName,
      'previousReading': previous ?? 0,
      'currentReading': current,
      'readingDate': _selectedDate.toIso8601String(),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    final success = _isEditing
        ? await provider.updateReading(
            (widget.existingReading?['_id'] ?? widget.existingReading?['id'])
                .toString(),
            payload,
          )
        : await provider.createReading(payload);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    setState(() => _isSaving = false);
    _showError(provider.error ?? 'فشل حفظ قراءة العداد');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل قراءة العداد' : 'إدخال قراءة العداد'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('التاريخ: '),
                  TextButton.icon(
                    onPressed: _isSaving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(DateFormat('yyyy/MM/dd').format(_selectedDate)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _previousController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'القراءة السابقة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _currentController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'القراءة الحالية'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ'),
        ),
      ],
    );
  }
}
