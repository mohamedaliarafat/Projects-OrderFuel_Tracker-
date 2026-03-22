import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/models/station_models.dart';
import 'package:order_tracker/providers/station_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class MonthlyStationReportScreen extends StatefulWidget {
  const MonthlyStationReportScreen({super.key});

  @override
  State<MonthlyStationReportScreen> createState() =>
      _MonthlyStationReportScreenState();
}

class _MonthlyStationReportScreenState
    extends State<MonthlyStationReportScreen> {
  static const List<String> _arabicMonths = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  final Set<String> _selectedStationIds = <String>{};
  final NumberFormat _fmt = NumberFormat('#,##0.##');

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool _isLoading = false;
  bool _isExporting = false;

  List<_StationMonthlyRow> _rows = const <_StationMonthlyRow>[];
  Map<DateTime, Map<String, _FuelMetric>>? _dailyFuelByDay;
  List<String> _fuelColumns = const <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final provider = context.read<StationProvider>();
    setState(() => _isLoading = true);
    await provider.fetchStations();
    if (!mounted) return;

    _selectedStationIds
      ..clear()
      ..addAll(provider.stations.map((s) => s.id));

    await _loadData();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'اختيار شهر التقرير',
    );

    if (picked == null) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month, 1);
    });
    await _loadData();
  }

  Future<void> _pickStations() async {
    final provider = context.read<StationProvider>();
    final stations = provider.stations;
    final temp = Set<String>.from(_selectedStationIds);

    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final allSelected =
                stations.isNotEmpty && temp.length == stations.length;
            return AlertDialog(
              title: const Text('اختيار المحطات'),
              content: SizedBox(
                width: 500,
                height: 460,
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: allSelected,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('كل المحطات'),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            temp
                              ..clear()
                              ..addAll(stations.map((e) => e.id));
                          } else {
                            temp.clear();
                          }
                        });
                      },
                    ),
                    const Divider(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: stations.length,
                        itemBuilder: (context, index) {
                          final s = stations[index];
                          return CheckboxListTile(
                            value: temp.contains(s.id),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(s.stationName),
                            subtitle: Text(s.stationCode),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  temp.add(s.id);
                                } else {
                                  temp.remove(s.id);
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: temp.isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, temp),
                  child: const Text('تطبيق'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _selectedStationIds
        ..clear()
        ..addAll(selected);
    });

    await _loadData();
  }

  Future<void> _loadData() async {
    if (_selectedStationIds.isEmpty) {
      setState(() {
        _isLoading = false;
        _rows = const <_StationMonthlyRow>[];
        _dailyFuelByDay = <DateTime, Map<String, _FuelMetric>>{};
        _fuelColumns = const <String>[];
      });
      return;
    }

    final provider = context.read<StationProvider>();
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startApi = DateFormat('yyyy-MM-dd').format(start);
    final endApi = DateFormat('yyyy-MM-dd').format(end);

    setState(() => _isLoading = true);

    final stations = provider.stations
        .where((s) => _selectedStationIds.contains(s.id))
        .toList();

    final rows = <_StationMonthlyRow>[];
    final dailyFuel = <DateTime, Map<String, _FuelMetric>>{};
    final allFuels = <String>{};

    for (final station in stations) {
      await provider.fetchSessions(
        filters: {
          'stationId': station.id,
          'startDate': startApi,
          'endDate': endApi,
          'limit': 5000,
        },
      );

      final sessionError = provider.error;
      final sessions = sessionError == null
          ? provider.sessions
                .where(
                  (s) =>
                      s.stationId == station.id &&
                      _isInsideMonth(s.sessionDate),
                )
                .toList()
          : <PumpSession>[];
      if (sessionError != null) {
        provider.clearError();
      }

      await provider.fetchInventories(
        filters: {
          'stationId': station.id,
          'startDate': startApi,
          'endDate': endApi,
          'limit': 5000,
        },
      );

      final inventoryError = provider.error;
      final inventories = inventoryError == null
          ? provider.inventories
                .where(
                  (i) =>
                      i.stationId == station.id &&
                      _isInsideMonth(i.inventoryDate),
                )
                .toList()
          : <DailyInventory>[];
      if (inventoryError != null) {
        provider.clearError();
      }

      final sessionAgg = _aggregateSessions(sessions);
      final inventoryAgg = _aggregateInventories(inventories);
      final stationDailyFuel = _aggregateDailyFuelMetrics(
        sessions: sessions,
        inventories: inventories,
      );

      final fuelMap = <String, _FuelMetric>{}..addAll(sessionAgg.fuels);
      for (final entry in inventoryAgg.fuelFallback.entries) {
        final target = fuelMap.putIfAbsent(entry.key, () => _FuelMetric());
        if (target.liters <= 0 && entry.value.liters > 0) {
          target.liters = entry.value.liters;
        }
        if (target.sales <= 0 && entry.value.sales > 0) {
          target.sales = entry.value.sales;
        }
      }

      final notes = LinkedHashSet<String>.from(<String>{})
        ..addAll(sessionAgg.notes)
        ..addAll(inventoryAgg.notes);

      final totalLiters = sessionAgg.totalLiters > 0
          ? sessionAgg.totalLiters
          : inventoryAgg.totalLiters;
      final totalSales = sessionAgg.totalSales > 0
          ? sessionAgg.totalSales
          : inventoryAgg.totalRevenue;
      final totalExpenses = inventoryAgg.totalExpenses > 0
          ? inventoryAgg.totalExpenses
          : sessionAgg.totalExpenses;

      rows.add(
        _StationMonthlyRow(
          stationName: station.stationName,
          sessionsCount: sessions.length,
          totalLiters: totalLiters,
          totalSales: totalSales,
          totalExpenses: totalExpenses,
          shortage: sessionAgg.shortage,
          netSales: totalSales - totalExpenses,
          notes: notes.toList(),
          fuelMap: fuelMap,
        ),
      );

      for (final entry in stationDailyFuel.entries) {
        final targetDay = dailyFuel.putIfAbsent(
          entry.key,
          () => <String, _FuelMetric>{},
        );
        for (final fuelEntry in entry.value.entries) {
          final targetMetric = targetDay.putIfAbsent(
            fuelEntry.key,
            () => _FuelMetric(),
          );
          targetMetric.liters += fuelEntry.value.liters;
          targetMetric.sales += fuelEntry.value.sales;
        }
      }

      allFuels.addAll(fuelMap.keys);
    }

    rows.sort((a, b) => a.stationName.compareTo(b.stationName));
    final fuels = <String>{}..addAll(allFuels);
    for (final day in dailyFuel.values) {
      fuels.addAll(day.keys);
    }
    final fuelColumns = fuels.toList()..sort();

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _dailyFuelByDay = dailyFuel;
      _fuelColumns = fuelColumns;
      _isLoading = false;
    });
  }

  _SessionAgg _aggregateSessions(List<PumpSession> sessions) {
    final notes = <String>[];
    final fuelMap = <String, _FuelMetric>{};

    double totalLiters = 0;
    double totalSales = 0;
    double totalExpenses = 0;
    double shortage = 0;

    for (final session in sessions) {
      final sessionNote = (session.notes ?? '').trim();
      if (sessionNote.isNotEmpty) {
        notes.add(sessionNote);
      }

      final diff =
          session.actualDifference ?? session.calculatedDifference ?? 0;
      if (diff < 0) {
        shortage += diff.abs();
      }

      final itemsExpenses = (session.expenses ?? <Expense>[]).fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );
      totalExpenses += session.expensesTotal ?? itemsExpenses;

      final metrics = _resolveSessionMetrics(session);
      _mergeFuelMetrics(fuelMap, metrics.fuelMap);

      totalLiters += metrics.totalLiters;
      totalSales += metrics.totalAmount;
    }

    return _SessionAgg(
      totalLiters: totalLiters,
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      shortage: shortage,
      notes: notes,
      fuels: fuelMap,
    );
  }

  Map<DateTime, Map<String, _FuelMetric>> _aggregateDailyFuelMetrics({
    required List<PumpSession> sessions,
    required List<DailyInventory> inventories,
  }) {
    final sessionFuelByDay = <DateTime, Map<String, _FuelMetric>>{};
    final sessionTotalByDay = <DateTime, double>{};

    for (final session in sessions) {
      final date = _normalizeDate(session.sessionDate);
      final metrics = _resolveSessionMetrics(session);

      sessionTotalByDay.update(
        date,
        (current) => current + metrics.totalAmount,
        ifAbsent: () => metrics.totalAmount,
      );

      final dayFuel = sessionFuelByDay.putIfAbsent(
        date,
        () => <String, _FuelMetric>{},
      );

      if (metrics.fuelMap.isNotEmpty) {
        _mergeFuelMetrics(dayFuel, metrics.fuelMap);
      } else if (metrics.totalAmount > 0 || metrics.totalLiters > 0) {
        final metric = dayFuel.putIfAbsent('غير محدد', () => _FuelMetric());
        metric.liters += metrics.totalLiters;
        metric.sales += metrics.totalAmount;
      }
    }

    final inventoryFuelByDay = <DateTime, Map<String, _FuelMetric>>{};
    final inventoryTotalByDay = <DateTime, double>{};

    for (final inventory in inventories) {
      final date = _normalizeDate(inventory.inventoryDate);
      inventoryTotalByDay.update(
        date,
        (current) => current + inventory.totalRevenue,
        ifAbsent: () => inventory.totalRevenue,
      );

      final fuelType = inventory.fuelType.trim().isNotEmpty
          ? inventory.fuelType.trim()
          : 'غير محدد';
      final dayFuel = inventoryFuelByDay.putIfAbsent(
        date,
        () => <String, _FuelMetric>{},
      );
      final metric = dayFuel.putIfAbsent(fuelType, () => _FuelMetric());
      metric.liters += inventory.totalSales;
      metric.sales += inventory.totalRevenue;
    }

    final merged = <DateTime, Map<String, _FuelMetric>>{};
    final allDates = <DateTime>{
      ...sessionTotalByDay.keys,
      ...inventoryTotalByDay.keys,
    };

    for (final date in allDates) {
      final sessionTotal = sessionTotalByDay[date] ?? 0;
      merged[date] = sessionTotal > 0
          ? (sessionFuelByDay[date] ?? <String, _FuelMetric>{})
          : (inventoryFuelByDay[date] ?? <String, _FuelMetric>{});
    }

    return merged;
  }

  _InventoryAgg _aggregateInventories(List<DailyInventory> inventories) {
    final notes = <String>[];
    final fuelFallback = <String, _FuelMetric>{};

    double totalRevenue = 0;
    double totalExpenses = 0;
    double totalLiters = 0;

    for (final inventory in inventories) {
      final inventoryNote = (inventory.notes ?? '').trim();
      if (inventoryNote.isNotEmpty) {
        notes.add(inventoryNote);
      }

      totalRevenue += inventory.totalRevenue;
      totalExpenses += inventory.totalExpenses;
      totalLiters += inventory.totalSales;

      if (inventory.fuelType.trim().isNotEmpty) {
        final metric = fuelFallback.putIfAbsent(
          inventory.fuelType.trim(),
          () => _FuelMetric(),
        );
        metric.liters += inventory.totalSales;
        metric.sales += inventory.totalRevenue;
      }
    }

    return _InventoryAgg(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      totalLiters: totalLiters,
      notes: notes,
      fuelFallback: fuelFallback,
    );
  }

  double _readLiters(NozzleReading reading) {
    if ((reading.totalLiters ?? 0) > 0) return reading.totalLiters!;
    if (reading.closingReading == null) return 0;
    final diff = reading.closingReading! - reading.openingReading;
    return diff > 0 ? diff : 0;
  }

  double _readAmount(
    NozzleReading reading,
    PumpSession session,
    double liters,
  ) {
    if ((reading.totalAmount ?? 0) > 0) return reading.totalAmount!;
    final unitPrice = (reading.unitPrice ?? 0) > 0
        ? reading.unitPrice!
        : (session.unitPrice ?? 0);
    return unitPrice > 0 ? unitPrice * liters : 0;
  }

  double _resolveSessionAmount(PumpSession session) {
    if ((session.totalSales ?? 0) > 0) return session.totalSales!;
    if ((session.totalAmount ?? 0) > 0) return session.totalAmount!;
    if (session.paymentTypes.total > 0) return session.paymentTypes.total;
    return 0;
  }

  _ResolvedSessionMetric _resolveSessionMetrics(PumpSession session) {
    final fuelMap = <String, _FuelMetric>{};
    final readings = session.nozzleReadings ?? <NozzleReading>[];

    double sessionLiters = 0;
    double sessionAmount = 0;

    for (final reading in readings) {
      final fuelType =
          (reading.fuelType.trim().isNotEmpty
                  ? reading.fuelType
                  : session.fuelType)
              .trim();
      if (fuelType.isEmpty) continue;

      final liters = _readLiters(reading);
      final amount = _readAmount(reading, session, liters);

      if (liters <= 0 && amount <= 0) continue;

      final metric = fuelMap.putIfAbsent(fuelType, () => _FuelMetric());
      metric.liters += liters;
      metric.sales += amount;

      sessionLiters += liters;
      sessionAmount += amount;
    }

    if (sessionLiters <= 0) {
      sessionLiters = session.totalLiters ?? 0;
    }
    if (sessionAmount <= 0) {
      sessionAmount = _resolveSessionAmount(session);
    }

    if (readings.isEmpty && session.fuelType.trim().isNotEmpty) {
      final metric = fuelMap.putIfAbsent(
        session.fuelType.trim(),
        () => _FuelMetric(),
      );
      metric.liters += sessionLiters;
      metric.sales += sessionAmount;
    }

    return _ResolvedSessionMetric(
      totalLiters: sessionLiters,
      totalAmount: sessionAmount,
      fuelMap: fuelMap,
    );
  }

  void _mergeFuelMetrics(
    Map<String, _FuelMetric> target,
    Map<String, _FuelMetric> source,
  ) {
    for (final entry in source.entries) {
      final metric = target.putIfAbsent(entry.key, () => _FuelMetric());
      metric.liters += entry.value.liters;
      metric.sales += entry.value.sales;
    }
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isInsideMonth(DateTime date) {
    return date.year == _selectedMonth.year &&
        date.month == _selectedMonth.month;
  }

  String _monthLabel(DateTime month) =>
      '${_arabicMonths[month.month - 1]} ${month.year}';

  String _formatNum(double value) => _fmt.format(value);

  String _formatDate(DateTime date) => DateFormat('yyyy/MM/dd').format(date);

  String _formatMoney(double value) => '${_fmt.format(value)} ريال';

  String _stationsLabel(List<Station> stations) {
    if (_selectedStationIds.isEmpty) return 'لا يوجد اختيار';
    if (_selectedStationIds.length == stations.length && stations.isNotEmpty) {
      return 'كل المحطات (${stations.length})';
    }
    if (_selectedStationIds.length == 1) {
      final station = stations.firstWhere(
        (s) => s.id == _selectedStationIds.first,
        orElse: () => Station(
          id: '',
          stationCode: '',
          stationName: '',
          location: '',
          city: '',
          managerName: '',
          managerPhone: '',
          fuelTypes: const [],
          pumps: const [],
          createdById: '',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fuelPrices: const [],
        ),
      );
      if (station.stationName.isNotEmpty) return station.stationName;
    }
    return '${_selectedStationIds.length} محطات';
  }

  Future<void> _exportPdf() async {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
      return;
    }

    // Hot-reload safety: older state may have monthly rows but no daily rows yet.
    if (_dailyFuelByDay == null) {
      await _loadData();
      if (!mounted) return;
    }

    setState(() => _isExporting = true);
    try {
      final bytes = await _buildPdfBytes();
      final fileName =
          'monthly-stations-${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تصدير التقرير: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<Uint8List> _buildPdfBytes() async {
    final regularFont = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final boldFont = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final logoBytes = (await rootBundle.load(
      'assets/images/logo.png',
    )).buffer.asUint8List();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(regularFont),
        bold: pw.Font.ttf(boldFont),
      ),
    );

    final logo = pw.MemoryImage(logoBytes);
    final generatedAt = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final dailyFuelByDay =
        _dailyFuelByDay ?? <DateTime, Map<String, _FuelMetric>>{};
    final fuelTotals = <String, _FuelMetric>{};
    double totalDailySales = 0;

    for (final dayMap in dailyFuelByDay.values) {
      for (final entry in dayMap.entries) {
        final metric = fuelTotals.putIfAbsent(entry.key, () => _FuelMetric());
        metric.liters += entry.value.liters;
        metric.sales += entry.value.sales;
        totalDailySales += entry.value.sales;
      }
    }

    final headers = <String>[
      '#',
      'المحطة',
      'الجلسات',
      'إجمالي اللترات',
      'إجمالي المبيعات',
      'المصروفات',
      'صافي المبيعات',
      'العجز',
    ];

    for (final fuel in _fuelColumns) {
      headers.add('$fuel (لتر)');
      headers.add('$fuel (مبيعات)');
    }
    headers.add('الملاحظات');

    final dailyHeaders = <String>[
      '#',
      ..._fuelColumns,
      'إجمالي اليوم',
      'التاريخ',
    ];

    final data = <List<String>>[];
    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final cells = <String>[
        '${i + 1}',
        row.stationName,
        '${row.sessionsCount}',
        _formatNum(row.totalLiters),
        _formatMoney(row.totalSales),
        _formatMoney(row.totalExpenses),
        _formatMoney(row.netSales),
        _formatMoney(row.shortage),
      ];
      for (final fuel in _fuelColumns) {
        final metric = row.fuelMap[fuel];
        cells.add(_formatNum(metric?.liters ?? 0));
        cells.add(_formatMoney(metric?.sales ?? 0));
      }
      cells.add(row.notesSummary);
      data.add(cells);
    }

    final dailyData = <List<String>>[];
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final dayMetrics =
          dailyFuelByDay[_normalizeDate(date)] ?? <String, _FuelMetric>{};

      double daySales = 0;
      final row = <String>['$day'];

      for (final fuel in _fuelColumns) {
        final metric = dayMetrics[fuel];
        final liters = metric?.liters ?? 0;
        final sales = metric?.sales ?? 0;

        if (liters <= 0 && sales <= 0) {
          row.add('-');
          continue;
        }

        daySales += sales;
        row.add('${_formatNum(liters)} لتر\n${_formatNum(sales)} ريال');
      }

      row.add(_formatMoney(daySales));
      row.add(_formatDate(date));
      dailyData.add(row);
    }

    final totalRow = <String>[''];
    for (final fuel in _fuelColumns) {
      final metric = fuelTotals[fuel];
      final liters = metric?.liters ?? 0;
      final sales = metric?.sales ?? 0;
      if (liters <= 0 && sales <= 0) {
        totalRow.add('-');
      } else {
        totalRow.add('${_formatNum(liters)} لتر\n${_formatNum(sales)} ريال');
      }
    }
    totalRow.add(_formatMoney(totalDailySales));
    totalRow.add('إجمالي المبيعات الكاملة');
    dailyData.add(totalRow);

    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(14),
      1: const pw.FlexColumnWidth(2.1),
      2: const pw.FlexColumnWidth(0.8),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1.05),
      5: const pw.FlexColumnWidth(1.05),
      6: const pw.FlexColumnWidth(1.05),
      7: const pw.FlexColumnWidth(1),
    };

    int dynamicIndex = 8;
    for (int i = 0; i < _fuelColumns.length; i++) {
      widths[dynamicIndex++] = const pw.FlexColumnWidth(1.15);
      widths[dynamicIndex++] = const pw.FlexColumnWidth(1.25);
    }
    widths[dynamicIndex] = const pw.FlexColumnWidth(1.3);

    final dailyWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(14),
    };

    int dailyIndex = 1;
    for (int i = 0; i < _fuelColumns.length; i++) {
      dailyWidths[dailyIndex++] = const pw.FlexColumnWidth(1.15);
    }
    dailyWidths[dailyIndex++] = const pw.FlexColumnWidth(1.1); // daily total
    dailyWidths[dailyIndex] = const pw.FlexColumnWidth(1.05); // date

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18), // 0.25 inch
        textDirection: pw.TextDirection.rtl,
        header: (context) {
          if (context.pageNumber != 1) return pw.SizedBox();
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
                        pw.Text(
                          'تقرير شهري شامل لمحطات الوقود - ${_monthLabel(_selectedMonth)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'عدد المحطات: ${_rows.length}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(
                    width: 56,
                    height: 56,
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.grey500),
            ],
          );
        },
        footer: (context) {
          if (context.pageNumber != context.pagesCount) return pw.SizedBox();
          return pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey500),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'عنوان الشركة: حائل, المملكة العربية السعودية',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'تم الإنشاء: $generatedAt',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          );
        },
        build: (context) {
          return [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              cellAlignment: pw.Alignment.centerRight,
              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 6.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE3ECF9),
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFD),
              ),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 2.2,
                vertical: 3,
              ),
              columnWidths: widths,
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFEAF2FF),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'المبيعات اليومية خلال شهر ${_monthLabel(_selectedMonth)}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'الأيام: $daysInMonth | أنواع الوقود: ${_fuelColumns.length}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: dailyHeaders,
              data: dailyData,
              cellAlignment: pw.Alignment.centerRight,
              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 6.2),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFDDEAFB),
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFD),
              ),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.45),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 2.6,
              ),
              columnWidths: dailyWidths,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();
    final stations = provider.stations;

    final totalSales = _rows.fold<double>(
      0,
      (sum, row) => sum + row.totalSales,
    );
    final totalLiters = _rows.fold<double>(
      0,
      (sum, row) => sum + row.totalLiters,
    );
    final totalExpenses = _rows.fold<double>(
      0,
      (sum, row) => sum + row.totalExpenses,
    );
    final totalShortage = _rows.fold<double>(
      0,
      (sum, row) => sum + row.shortage,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('التقرير الشهري للمحطات')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip('الشهر: ${_monthLabel(_selectedMonth)}'),
                    _chip('المحطات: ${_stationsLabel(stations)}'),
                    OutlinedButton.icon(
                      onPressed: _pickMonth,
                      icon: const Icon(Icons.date_range),
                      label: const Text('تغيير الشهر'),
                    ),
                    OutlinedButton.icon(
                      onPressed: stations.isEmpty ? null : _pickStations,
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text('اختيار المحطات'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('تحديث'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading || _isExporting || _rows.isEmpty
                          ? null
                          : _exportPdf,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf),
                      label: const Text('تصدير PDF'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    Text('إجمالي اللترات: ${_formatNum(totalLiters)}'),
                    Text('إجمالي المبيعات: ${_formatMoney(totalSales)}'),
                    Text('إجمالي المصروفات: ${_formatMoney(totalExpenses)}'),
                    Text('إجمالي العجز: ${_formatMoney(totalShortage)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _buildPreviewTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    if (_rows.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 220,
          child: Center(
            child: Text('لا توجد بيانات لهذا الشهر أو للمحطات المحددة'),
          ),
        ),
      );
    }

    final columns = <DataColumn>[
      const DataColumn(label: Text('#')),
      const DataColumn(label: Text('المحطة')),
      const DataColumn(label: Text('الجلسات')),
      const DataColumn(label: Text('إجمالي اللترات')),
      const DataColumn(label: Text('إجمالي المبيعات')),
      const DataColumn(label: Text('المصروفات')),
      const DataColumn(label: Text('صافي المبيعات')),
      const DataColumn(label: Text('العجز')),
      ..._fuelColumns.expand(
        (fuel) => [
          DataColumn(label: Text('$fuel (لتر)')),
          DataColumn(label: Text('$fuel (مبيعات)')),
        ],
      ),
      const DataColumn(label: Text('الملاحظات')),
    ];

    final rows = _rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;

      final cells = <DataCell>[
        DataCell(Text('${index + 1}')),
        DataCell(Text(row.stationName)),
        DataCell(Text('${row.sessionsCount}')),
        DataCell(Text(_formatNum(row.totalLiters))),
        DataCell(Text(_formatMoney(row.totalSales))),
        DataCell(Text(_formatMoney(row.totalExpenses))),
        DataCell(Text(_formatMoney(row.netSales))),
        DataCell(Text(_formatMoney(row.shortage))),
      ];

      for (final fuel in _fuelColumns) {
        final metric = row.fuelMap[fuel];
        cells.add(
          DataCell(
            SizedBox(width: 104, child: Text(_formatNum(metric?.liters ?? 0))),
          ),
        );
        cells.add(
          DataCell(
            SizedBox(width: 118, child: Text(_formatMoney(metric?.sales ?? 0))),
          ),
        );
      }

      cells.add(
        DataCell(
          SizedBox(
            width: 160,
            child: Text(
              row.notesSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      return DataRow(cells: cells);
    }).toList();

    final minTableWidth = 1300 + (_fuelColumns.length * 180);

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minTableWidth.toDouble()),
          child: DataTable(
            columns: columns,
            rows: rows,
            headingRowHeight: 44,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 58,
            horizontalMargin: 10,
            columnSpacing: 22,
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StationMonthlyRow {
  final String stationName;
  final int sessionsCount;
  final double totalLiters;
  final double totalSales;
  final double totalExpenses;
  final double shortage;
  final double netSales;
  final List<String> notes;
  final Map<String, _FuelMetric> fuelMap;

  const _StationMonthlyRow({
    required this.stationName,
    required this.sessionsCount,
    required this.totalLiters,
    required this.totalSales,
    required this.totalExpenses,
    required this.shortage,
    required this.netSales,
    required this.notes,
    required this.fuelMap,
  });

  String get notesSummary {
    if (notes.isEmpty) return '-';
    if (notes.length == 1) return notes.first;
    return '${notes.first} (+${notes.length - 1})';
  }
}

class _FuelMetric {
  double liters;
  double sales;

  _FuelMetric() : liters = 0, sales = 0;
}

class _SessionAgg {
  final double totalLiters;
  final double totalSales;
  final double totalExpenses;
  final double shortage;
  final List<String> notes;
  final Map<String, _FuelMetric> fuels;

  const _SessionAgg({
    required this.totalLiters,
    required this.totalSales,
    required this.totalExpenses,
    required this.shortage,
    required this.notes,
    required this.fuels,
  });
}

class _ResolvedSessionMetric {
  final double totalLiters;
  final double totalAmount;
  final Map<String, _FuelMetric> fuelMap;

  const _ResolvedSessionMetric({
    required this.totalLiters,
    required this.totalAmount,
    required this.fuelMap,
  });
}

class _InventoryAgg {
  final double totalRevenue;
  final double totalExpenses;
  final double totalLiters;
  final List<String> notes;
  final Map<String, _FuelMetric> fuelFallback;

  const _InventoryAgg({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalLiters,
    required this.notes,
    required this.fuelFallback,
  });
}
