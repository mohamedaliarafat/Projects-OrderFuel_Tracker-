import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/providers/workshop_fuel_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class WorkshopFuelDriverReportScreen extends StatefulWidget {
  const WorkshopFuelDriverReportScreen({super.key});

  @override
  State<WorkshopFuelDriverReportScreen> createState() =>
      _WorkshopFuelDriverReportScreenState();
}

class _WorkshopFuelDriverReportScreenState
    extends State<WorkshopFuelDriverReportScreen> {
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
      _loadRefuels();
    });
  }

  Future<void> _loadRefuels() async {
    if (_stationId == null || _stationId!.isEmpty) return;
    await context.read<WorkshopFuelProvider>().fetchRefuels(
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
    await _loadRefuels();
  }

  List<_DriverReportRow> _buildDriverRows(List<Map<String, dynamic>> refuels) {
    final grouped = <String, _DriverReportRow>{};

    for (final refuel in refuels) {
      final driverName =
          refuel['driverName']?.toString().trim().isNotEmpty == true
          ? refuel['driverName'].toString().trim()
          : 'سائق غير معروف';
      final key = refuel['driverId']?.toString().trim().isNotEmpty == true
          ? refuel['driverId'].toString()
          : driverName;

      final row = grouped.putIfAbsent(
        key,
        () => _DriverReportRow(
          driverKey: key,
          driverName: driverName,
          vehicleNumbers: <String>{},
          details: <Map<String, dynamic>>[],
        ),
      );

      row.count += 1;
      row.totalLiters += _readNum(refuel['liters']);
      row.totalAmount += _readNum(refuel['totalAmount']);

      final vehicleNumber = refuel['vehicleNumber']?.toString().trim() ?? '';
      if (vehicleNumber.isNotEmpty) {
        row.vehicleNumbers.add(vehicleNumber);
      }
      row.details.add(refuel);
    }

    final rows = grouped.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    for (final row in rows) {
      row.details.sort((a, b) {
        final ad =
            DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd =
            DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    }

    return rows;
  }

  Future<List<_DriverReportRow>?> _pickDriversForPrint(
    List<_DriverReportRow> driverRows,
  ) async {
    if (driverRows.isEmpty) return const <_DriverReportRow>[];

    final selectedKeys = driverRows.map((row) => row.driverKey).toSet();

    final pickedKeys = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('اختيار السائقين للطباعة'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              selectedKeys
                                ..clear()
                                ..addAll(
                                  driverRows.map((row) => row.driverKey),
                                );
                            });
                          },
                          icon: const Icon(Icons.done_all),
                          label: const Text('تحديد الكل'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(selectedKeys.clear);
                          },
                          icon: const Icon(Icons.remove_done_outlined),
                          label: const Text('إلغاء التحديد'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تم تحديد ${selectedKeys.length} من ${driverRows.length} سائق',
                      style: const TextStyle(
                        color: AppColors.mediumGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 360,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: driverRows.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final row = driverRows[index];
                          final isSelected = selectedKeys.contains(
                            row.driverKey,
                          );
                          return CheckboxListTile(
                            value: isSelected,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              row.driverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'عدد التعبئات: ${row.count} • اللترات: ${row.totalLiters.toStringAsFixed(2)} • المبلغ: ${row.totalAmount.toStringAsFixed(2)}',
                            ),
                            onChanged: (_) {
                              setDialogState(() {
                                if (isSelected) {
                                  selectedKeys.remove(row.driverKey);
                                } else {
                                  selectedKeys.add(row.driverKey);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(
                    dialogContext,
                  ).pop(Set<String>.from(selectedKeys)),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('طباعة المحدد'),
                ),
              ],
            );
          },
        );
      },
    );

    if (pickedKeys == null) return null;

    return driverRows
        .where((row) => pickedKeys.contains(row.driverKey))
        .toList(growable: false);
  }

  Future<void> _handlePrint(List<_DriverReportRow> driverRows) async {
    final selectedRows = await _pickDriversForPrint(driverRows);
    if (!mounted || selectedRows == null) return;
    if (selectedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر سائقًا واحدًا على الأقل للطباعة')),
      );
      return;
    }

    final refuelCount = selectedRows.fold<int>(
      0,
      (sum, row) => sum + row.count,
    );
    final totalLiters = selectedRows.fold<double>(
      0,
      (sum, row) => sum + row.totalLiters,
    );
    final totalAmount = selectedRows.fold<double>(
      0,
      (sum, row) => sum + row.totalAmount,
    );

    await _printReport(
      driverRows: selectedRows,
      refuelCount: refuelCount,
      totalLiters: totalLiters,
      totalAmount: totalAmount,
    );
  }

  Future<void> _printReport({
    required List<_DriverReportRow> driverRows,
    required int refuelCount,
    required double totalLiters,
    required double totalAmount,
  }) async {
    if (driverRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات لطباعة التقرير')),
      );
      return;
    }

    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await rootBundle.load(AppImages.logo)).buffer.asUint8List(),
    );
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(12),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (_) => [
          _buildPdfHeader(logo),
          pw.SizedBox(height: 8),
          _buildPdfSummary(
            driverCount: driverRows.length,
            refuelCount: refuelCount,
            totalLiters: totalLiters,
            totalAmount: totalAmount,
          ),
          pw.SizedBox(height: 10),
          ...driverRows.expand(
            (row) => [_buildDriverPdfSection(row), pw.SizedBox(height: 10)],
          ),
          _buildPdfGrandTotals(
            totalLiters: totalLiters,
            totalAmount: totalAmount,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  pw.Widget _buildPdfHeader(pw.MemoryImage logo) {
    final rangeText =
        '${DateFormat('yyyy/MM/dd').format(_startDate)} - ${DateFormat('yyyy/MM/dd').format(_endDate)}';

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey, width: 0.6),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'شركة البحيرة العربية للنقليات',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'تقرير تعبئات السائقين - الورشة${_stationName != null ? ' - $_stationName' : ''}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text('الفترة: $rangeText'),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.SizedBox(
            width: 72,
            height: 72,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummary({
    required int driverCount,
    required int refuelCount,
    required double totalLiters,
    required double totalAmount,
  }) {
    return pw.Table.fromTextArray(
      headers: const [
        'عدد التعبئات',
        'عدد السائقين',
        'إجمالي اللترات',
        'إجمالي السعر',
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.center,
      data: [
        [
          refuelCount.toString(),
          driverCount.toString(),
          totalLiters.toStringAsFixed(2),
          totalAmount.toStringAsFixed(2),
        ],
      ],
    );
  }

  pw.Widget _buildDriverPdfSection(_DriverReportRow row) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  row.driverName,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                'عدد التعبئات: ${row.count}  |  اللترات: ${row.totalLiters.toStringAsFixed(2)}  |  المبلغ: ${row.totalAmount.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
          if (row.vehicleNumbers.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'المركبات: ${row.vehicleNumbers.join(' - ')}',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ],
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: const [
              'التاريخ',
              'رقم السيارة',
              'اللترات',
              'سعر اللتر',
              'المبلغ',
              'ملاحظات',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
            data: row.details
                .map((detail) {
                  final date =
                      DateTime.tryParse(
                        detail['createdAt']?.toString() ?? '',
                      ) ??
                      DateTime.now();
                  return [
                    DateFormat('yyyy/MM/dd').format(date),
                    detail['vehicleNumber']?.toString() ?? '--',
                    _readNum(detail['liters']).toStringAsFixed(2),
                    _readNum(detail['unitPrice']).toStringAsFixed(2),
                    _readNum(detail['totalAmount']).toStringAsFixed(2),
                    detail['notes']?.toString().trim().isNotEmpty == true
                        ? detail['notes'].toString()
                        : '-',
                  ];
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfGrandTotals({
    required double totalLiters,
    required double totalAmount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.blue200, width: 0.7),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'إجمالي اللترات المعبأة: ${totalLiters.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'إجمالي السعر: ${totalAmount.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkshopFuelProvider>();
    final refuels = List<Map<String, dynamic>>.from(provider.refuels);
    final driverRows = _buildDriverRows(refuels);
    final totalLiters = refuels.fold<double>(
      0,
      (sum, item) => sum + _readNum(item['liters']),
    );
    final totalAmount = refuels.fold<double>(
      0,
      (sum, item) => sum + _readNum(item['totalAmount']),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تقرير تعبئات السائقين${_stationName != null ? ' - $_stationName' : ''}',
        ),
        actions: [
          IconButton(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
            tooltip: 'تحديد الفترة',
          ),
          IconButton(
            onPressed: provider.isLoading
                ? null
                : () => _handlePrint(driverRows),
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة التقرير',
          ),
          IconButton(
            onPressed: provider.isLoading ? null : _loadRefuels,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRefuels,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DriverSummaryCard(
                  title: 'عدد التعبئات',
                  value: refuels.length.toString(),
                  icon: Icons.local_gas_station,
                  color: AppColors.primaryBlue,
                ),
                _DriverSummaryCard(
                  title: 'عدد السائقين',
                  value: driverRows.length.toString(),
                  icon: Icons.person_outline,
                  color: AppColors.successGreen,
                ),
                _DriverSummaryCard(
                  title: 'إجمالي اللترات',
                  value: totalLiters.toStringAsFixed(2),
                  icon: Icons.opacity,
                  color: AppColors.infoBlue,
                ),
                _DriverSummaryCard(
                  title: 'إجمالي المبلغ',
                  value: totalAmount.toStringAsFixed(2),
                  icon: Icons.payments_outlined,
                  color: AppColors.warningOrange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'الفترة: ${DateFormat('yyyy/MM/dd').format(_startDate)} - ${DateFormat('yyyy/MM/dd').format(_endDate)}',
              style: const TextStyle(color: AppColors.mediumGray),
            ),
            const SizedBox(height: 16),
            if (provider.isLoading && refuels.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (provider.error != null && refuels.isEmpty)
              Center(child: Text(provider.error!))
            else if (driverRows.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Text('لا توجد تعبئات للسائقين في هذه الفترة'),
                ),
              )
            else
              ...driverRows.map((row) => _DriverReportCard(row: row)),
            const SizedBox(height: 16),
            _DriverTotalsFooter(
              totalLiters: totalLiters,
              totalAmount: totalAmount,
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverSummaryCard extends StatelessWidget {
  const _DriverSummaryCard({
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

class _DriverReportCard extends StatelessWidget {
  const _DriverReportCard({required this.row});

  final _DriverReportRow row;

  double _readNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryBlue,
          child: Text(
            row.driverName.isNotEmpty ? row.driverName[0] : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          row.driverName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'عدد التعبئات: ${row.count} • اللترات: ${row.totalLiters.toStringAsFixed(2)} • المبلغ: ${row.totalAmount.toStringAsFixed(2)}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (row.vehicleNumbers.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: row.vehicleNumbers
                    .map(
                      (vehicle) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGray,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(vehicle),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('التاريخ')),
                DataColumn(label: Text('رقم السيارة')),
                DataColumn(label: Text('اللترات')),
                DataColumn(label: Text('سعر اللتر')),
                DataColumn(label: Text('المبلغ')),
                DataColumn(label: Text('ملاحظات')),
              ],
              rows: row.details
                  .map((detail) {
                    final date =
                        DateTime.tryParse(
                          detail['createdAt']?.toString() ?? '',
                        ) ??
                        DateTime.now();
                    return DataRow(
                      cells: [
                        DataCell(Text(DateFormat('yyyy/MM/dd').format(date))),
                        DataCell(
                          Text(detail['vehicleNumber']?.toString() ?? '--'),
                        ),
                        DataCell(
                          Text(_readNum(detail['liters']).toStringAsFixed(2)),
                        ),
                        DataCell(
                          Text(
                            _readNum(detail['unitPrice']).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(
                          Text(
                            _readNum(detail['totalAmount']).toStringAsFixed(2),
                          ),
                        ),
                        DataCell(Text(detail['notes']?.toString() ?? '-')),
                      ],
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverTotalsFooter extends StatelessWidget {
  const _DriverTotalsFooter({
    required this.totalLiters,
    required this.totalAmount,
  });

  final double totalLiters;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.14)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(
            'إجمالي اللترات المعبأة: ${totalLiters.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'إجمالي السعر: ${totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DriverReportRow {
  _DriverReportRow({
    required this.driverKey,
    required this.driverName,
    required this.vehicleNumbers,
    required this.details,
  });

  final String driverKey;
  final String driverName;
  final Set<String> vehicleNumbers;
  final List<Map<String, dynamic>> details;
  int count = 0;
  double totalLiters = 0;
  double totalAmount = 0;
}
