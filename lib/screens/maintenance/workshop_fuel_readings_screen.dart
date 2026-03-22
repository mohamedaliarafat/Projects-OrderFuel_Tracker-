import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/providers/workshop_fuel_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/maintenance/workshop_fuel_reading_editor_dialog.dart';
import 'package:provider/provider.dart';

class WorkshopFuelReadingsScreen extends StatefulWidget {
  const WorkshopFuelReadingsScreen({super.key});

  @override
  State<WorkshopFuelReadingsScreen> createState() =>
      _WorkshopFuelReadingsScreenState();
}

class _WorkshopFuelReadingsScreenState
    extends State<WorkshopFuelReadingsScreen> {
  String? _stationId;
  String? _stationName;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _stationId = args?['stationId']?.toString();
      _stationName = args?['stationName']?.toString();
      _loadReadings();
    });
  }

  Future<void> _loadReadings() async {
    if (_stationId == null || _stationId!.isEmpty) return;
    await context.read<WorkshopFuelProvider>().fetchReadings(
      stationId: _stationId!,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  double _readNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
    });
    await _loadReadings();
  }

  Future<void> _addReading(List<Map<String, dynamic>> readings) async {
    if (_stationId == null) return;
    final latest = readings.isNotEmpty ? readings.first : null;
    final success = await showWorkshopFuelReadingEditorDialog(
      context,
      stationId: _stationId!,
      stationName: _stationName,
      suggestedPreviousReading: _readNum(latest?['currentReading']),
    );
    if (success == true && mounted) {
      await _loadReadings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ قراءة العداد بنجاح'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _editReading(Map<String, dynamic> reading) async {
    if (_stationId == null) return;
    final success = await showWorkshopFuelReadingEditorDialog(
      context,
      stationId: _stationId!,
      stationName: _stationName,
      existingReading: reading,
    );
    if (success == true && mounted) {
      await _loadReadings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تعديل قراءة العداد بنجاح'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopFuelProvider>();
    final readings = List<Map<String, dynamic>>.from(provider.readings)
      ..sort((a, b) {
        final ad =
            DateTime.tryParse(a['readingDate']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd =
            DateTime.tryParse(b['readingDate']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

    final totalLiters = readings.fold<double>(
      0,
      (sum, reading) => sum + _readNum(reading['totalLiters']),
    );
    final latestReading = readings.isNotEmpty
        ? _readNum(readings.first['currentReading'])
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'قراءات العداد اليومية${_stationName != null ? ' - $_stationName' : ''}',
        ),
        actions: [
          IconButton(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
            tooltip: 'تحديد الفترة',
          ),
          IconButton(
            onPressed: provider.isLoading ? null : _loadReadings,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isLoading ? null : () => _addReading(readings),
        icon: const Icon(Icons.add),
        label: const Text('إضافة قراءة'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReadings,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryCard(
                  title: 'عدد اليوميات',
                  value: readings.length.toString(),
                  icon: Icons.calendar_month,
                  color: AppColors.primaryBlue,
                ),
                _SummaryCard(
                  title: 'إجمالي اللترات',
                  value: totalLiters.toStringAsFixed(2),
                  icon: Icons.opacity,
                  color: AppColors.infoBlue,
                ),
                _SummaryCard(
                  title: 'آخر قراءة حالية',
                  value: latestReading.toStringAsFixed(2),
                  icon: Icons.speed,
                  color: AppColors.successGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'الفترة: ${DateFormat('yyyy/MM/dd').format(_startDate)} - ${DateFormat('yyyy/MM/dd').format(_endDate)}',
              style: const TextStyle(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 16),
            if (provider.isLoading && readings.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.error != null && readings.isEmpty)
              Center(child: Text(provider.error!))
            else if (readings.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Text('لا توجد قراءات مسجلة في هذه الفترة'),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('التاريخ')),
                    DataColumn(label: Text('القراءة السابقة')),
                    DataColumn(label: Text('القراءة الحالية')),
                    DataColumn(label: Text('اللترات')),
                    DataColumn(label: Text('الملاحظات')),
                    DataColumn(label: Text('أُدخلت بواسطة')),
                    DataColumn(label: Text('إجراء')),
                  ],
                  rows: readings.map((reading) {
                    final date =
                        DateTime.tryParse(
                          reading['readingDate']?.toString() ?? '',
                        ) ??
                        DateTime.now();
                    return DataRow(
                      cells: [
                        DataCell(Text(DateFormat('yyyy/MM/dd').format(date))),
                        DataCell(
                          Text(
                            _readNum(
                              reading['previousReading'],
                            ).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _readNum(
                              reading['currentReading'],
                            ).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _readNum(reading['totalLiters']).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(Text(reading['notes']?.toString() ?? '-')),
                        DataCell(
                          Text(reading['createdByName']?.toString() ?? '-'),
                        ),
                        DataCell(
                          IconButton(
                            tooltip: 'تعديل',
                            onPressed: () => _editReading(reading),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}
