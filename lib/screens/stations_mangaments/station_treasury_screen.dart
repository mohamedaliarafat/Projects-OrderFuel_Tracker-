import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:order_tracker/models/station_models.dart';
import 'package:order_tracker/models/station_treasury_models.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/app_soft_background.dart';
import 'package:order_tracker/widgets/app_surface_card.dart';
import 'package:provider/provider.dart';

class StationTreasuryScreen extends StatefulWidget {
  const StationTreasuryScreen({super.key});

  @override
  State<StationTreasuryScreen> createState() => _StationTreasuryScreenState();
}

class _StationTreasuryScreenState extends State<StationTreasuryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final NumberFormat _moneyFormat = NumberFormat.currency(
    locale: 'ar',
    symbol: 'ر.س',
    decimalDigits: 2,
  );
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd - hh:mm a', 'ar');

  List<Station> _stations = const [];
  List<StationTreasuryVoucherRecord> _vouchers = const [];
  StationTreasuryOverview? _overview;
  String? _selectedStationId;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoadingStations = false;
  bool _isLoadingOverview = false;
  bool _isLoadingVouchers = false;
  bool _isSubmittingVoucher = false;

  bool get _canCreateVoucher {
    final role = context.read<AuthProvider>().role;
    return role == 'admin' ||
        role == 'owner' ||
        role == 'finance_manager' ||
        role == 'sales_manager_statiun';
  }

  bool get _isBusy =>
      _isLoadingStations ||
      _isLoadingOverview ||
      _isLoadingVouchers ||
      _isSubmittingVoucher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _formatApiDate(DateTime? value) {
    if (value == null) return null;
    return value.toIso8601String().split('T').first;
  }

  String _formatFilterDate(DateTime? value, {required String fallback}) {
    if (value == null) return fallback;
    return DateFormat('yyyy/MM/dd', 'ar').format(value);
  }

  String _currentPeriodLabel() {
    if (_startDate == null && _endDate == null) {
      return 'كل الفترات';
    }

    return '${_formatFilterDate(_startDate, fallback: 'البداية')} - ${_formatFilterDate(_endDate, fallback: 'الآن')}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate =
        (isStart ? _startDate : _endDate) ??
        (isStart ? (_endDate ?? DateTime.now()) : (_startDate ?? DateTime.now()));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
        if (_startDate != null && _startDate!.isAfter(picked)) {
          _startDate = picked;
        }
      }
    });

    await _loadTreasuryData();
  }

  Future<void> _clearDateRange() async {
    setState(() {
      _startDate = null;
      _endDate = null;
    });

    await _loadTreasuryData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingStations = true;
      _errorMessage = null;
    });

    try {
      await ApiService.loadToken();
      final stations = await _fetchStations();
      if (!mounted) return;

      setState(() {
        _stations = stations;
        _selectedStationId ??= stations.isNotEmpty ? stations.first.id : null;
      });

      await _loadTreasuryData();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingStations = false;
      });
    }
  }

  Future<void> _loadTreasuryData() async {
    final stationId = _selectedStationId;
    if (stationId == null || stationId.isEmpty) return;

    setState(() {
      _isLoadingOverview = true;
      _isLoadingVouchers = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _fetchOverview(stationId),
        _fetchVouchers(stationId),
      ]);

      if (!mounted) return;
      setState(() {
        _overview = results[0] as StationTreasuryOverview;
        _vouchers = results[1] as List<StationTreasuryVoucherRecord>;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingOverview = false;
        _isLoadingVouchers = false;
      });
    }
  }

  Future<List<Station>> _fetchStations() async {
    final uri = Uri.parse(
      '${ApiEndpoints.baseUrl}/stations/stations',
    ).replace(queryParameters: const {'page': '1', 'limit': '0'});

    final response = await http.get(uri, headers: ApiService.headers);
    if (response.statusCode != 200) {
      throw Exception('فشل جلب قائمة المحطات');
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final stations =
        (decoded is Map ? decoded['stations'] : null) as List<dynamic>? ?? [];

    return stations
        .whereType<Map>()
        .map((item) => Station.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<StationTreasuryOverview> _fetchOverview(String stationId) async {
    final uri = Uri.parse(
      '${ApiEndpoints.baseUrl}/stations/treasury/summary',
    ).replace(
      queryParameters: {
        'stationId': stationId,
        if (_formatApiDate(_startDate) != null)
          'startDate': _formatApiDate(_startDate)!,
        if (_formatApiDate(_endDate) != null)
          'endDate': _formatApiDate(_endDate)!,
      },
    );

    final response = await http.get(uri, headers: ApiService.headers);
    if (response.statusCode != 200) {
      throw Exception('فشل تحميل ملخص الخزنة');
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('بيانات الخزنة غير صالحة');
    }

    return StationTreasuryOverview.fromJson(decoded);
  }

  Future<List<StationTreasuryVoucherRecord>> _fetchVouchers(
    String stationId,
  ) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/stations/treasury/vouchers')
        .replace(
          queryParameters: {
            'stationId': stationId,
            'page': '1',
            'limit': '100',
            if (_formatApiDate(_startDate) != null)
              'startDate': _formatApiDate(_startDate)!,
            if (_formatApiDate(_endDate) != null)
              'endDate': _formatApiDate(_endDate)!,
          },
        );

    final response = await http.get(uri, headers: ApiService.headers);
    if (response.statusCode != 200) {
      throw Exception('فشل تحميل سجلات سندات الصرف');
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final vouchers =
        (decoded is Map ? decoded['vouchers'] : null) as List<dynamic>? ?? [];

    return vouchers
        .whereType<Map>()
        .map(
          (item) => StationTreasuryVoucherRecord.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> _submitVoucher() async {
    final stationId = _selectedStationId;
    if (stationId == null || stationId.isEmpty) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmittingVoucher = true;
    });

    try {
      final response = await ApiService.post('/stations/treasury/vouchers', {
        'stationId': stationId,
        'recipientName': _recipientController.text.trim(),
        'amount': double.tryParse(_amountController.text.trim()) ?? 0,
        'notes': _notesController.text.trim(),
      });

      final body = json.decode(utf8.decode(response.bodyBytes));
      if (!mounted) return;

      _recipientController.clear();
      _amountController.clear();
      _notesController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            body is Map && body['message'] != null
                ? body['message'].toString()
                : 'تم إنشاء سند الصرف بنجاح',
          ),
        ),
      );

      await _loadTreasuryData();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmittingVoucher = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _overview?.summary;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 700;
    final horizontalPadding = isDesktop ? 28.0 : (isTablet ? 20.0 : 16.0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text('خزنة المحطات'),
        flexibleSpace: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const AppSoftBackground(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: RefreshIndicator(
                onRefresh: _loadTreasuryData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    20,
                    horizontalPadding,
                    120,
                  ),
                  children: [
                    _buildFilterCard(),
                    if (_isBusy) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(minHeight: 4),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _buildErrorCard(_errorMessage!),
                    ],
                    if (summary != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoCard(summary),
                      const SizedBox(height: 16),
                      _buildSummarySection(summary),
                      const SizedBox(height: 16),
                      _buildFinancePanels(summary),
                    ],
                    if (summary == null &&
                        !_isBusy &&
                        _errorMessage == null) ...[
                      const SizedBox(height: 16),
                      _buildEmptyState(),
                    ],
                    const SizedBox(height: 16),
                    _buildVouchersSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: _stations.isEmpty
          ? const Text(
              'لا توجد محطات متاحة لهذا المستخدم حاليًا.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اختيار المحطة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'اختر المحطة لعرض الرصيد النقدي، الشبكة، وسجلات سندات الصرف المرتبطة بها.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedStationId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'المحطة',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.92),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.appBarWaterBright.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.appBarWaterBright,
                        width: 1.4,
                      ),
                    ),
                  ),
                  items: _stations
                      .map(
                        (station) => DropdownMenuItem<String>(
                          value: station.id,
                          child: Text(
                            station.stationName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoadingStations
                      ? null
                      : (value) async {
                          if (value == null || value == _selectedStationId) {
                            return;
                          }
                          setState(() {
                            _selectedStationId = value;
                          });
                          await _loadTreasuryData();
                        },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isStart: true),
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: Text(
                          'من: ${_formatFilterDate(_startDate, fallback: 'البداية')}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isStart: false),
                        icon: const Icon(Icons.event_available_rounded),
                        label: Text(
                          'إلى: ${_formatFilterDate(_endDate, fallback: 'الآن')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الفترة الحالية: ${_currentPeriodLabel()}',
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_startDate != null || _endDate != null)
                      TextButton(
                        onPressed: _clearDateRange,
                        child: const Text('مسح الفترة'),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildErrorCard(String message) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.errorRed.withValues(alpha: 0.08),
      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.20)),
      boxShadow: const [],
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.errorRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AppSurfaceCard(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 60,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 14),
          Text(
            'اختر محطة لعرض تفاصيل الخزنة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'عند اختيار المحطة ستظهر الأرصدة، تفصيل المبيعات، وسجلات سندات الصرف هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(StationTreasurySummary summary) {
    final stationName = _overview?.station.stationName ?? '';
    final stationCode = _overview?.station.stationCode ?? '';
    final infoText = summary.computedAt != null
        ? 'آخر تحديث: ${_dateFormat.format(summary.computedAt!)}'
        : 'البيانات محسوبة من الجلسات المغلقة والمعتمدة';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF0F4C5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationName.isEmpty ? 'خزنة المحطة' : stationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (stationCode.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        stationCode,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'الفترة: ${_currentPeriodLabel()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      infoText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(StationTreasurySummary summary) {
    final items = <_TreasuryMetric>[
      _TreasuryMetric(
        label: 'الرصيد النقدي الحالي',
        value: summary.cashBalance,
        icon: Icons.payments_rounded,
        color: AppColors.successGreen,
      ),
      _TreasuryMetric(
        label: 'رصيد الشبكة',
        value: summary.networkBalance,
        icon: Icons.credit_card_rounded,
        color: AppColors.infoBlue,
      ),
      _TreasuryMetric(
        label: 'إجمالي الرصيد',
        value: summary.totalBalance,
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.primaryBlue,
      ),
      _TreasuryMetric(
        label: 'مبيعات النقدي',
        value: summary.cashSales,
        icon: Icons.attach_money_rounded,
        color: AppColors.warningOrange,
      ),
      _TreasuryMetric(
        label: 'مبيعات الشبكة',
        value: summary.networkSales,
        icon: Icons.point_of_sale_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _TreasuryMetric(
        label: 'مصروفات من المبيعات',
        value: summary.salesExpenses,
        icon: Icons.money_off_csred_rounded,
        color: AppColors.errorRed,
      ),
      _TreasuryMetric(
        label: 'سندات الصرف',
        value: summary.disbursedCash,
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF0F766E),
      ),
      _TreasuryMetric(
        label: 'الجلسات المحتسبة',
        value: summary.closedSessionsCount.toDouble(),
        icon: Icons.analytics_rounded,
        color: const Color(0xFF334155),
        isCurrency: false,
      ),
    ];

    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الملخص المالي',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'ملخص فوري لحركة النقدي، الشبكة، والمبالغ المحتسبة من الجلسات المعتمدة.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final double tileWidth;
              if (width >= 1100) {
                tileWidth = (width - 24) / 4;
              } else if (width >= 720) {
                tileWidth = (width - 12) / 2;
              } else {
                tileWidth = width;
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: tileWidth,
                        child: _buildMetricCard(item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(_TreasuryMetric metric) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      color: Colors.white.withValues(alpha: 0.78),
      border: Border.all(color: metric.color.withValues(alpha: 0.12)),
      boxShadow: [
        BoxShadow(
          color: metric.color.withValues(alpha: 0.08),
          blurRadius: 22,
          offset: const Offset(0, 14),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(metric.icon, color: metric.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  metric.isCurrency
                      ? _moneyFormat.format(metric.value)
                      : NumberFormat.decimalPattern('ar').format(metric.value),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkBreakdown(StationTreasurySummary summary) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تفصيل مبيعات الشبكة',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'توزيع مبيعات الدفع غير النقدي حسب القنوات المختلفة.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildBreakdownChip(
                label: 'بطاقات',
                value: summary.cardSales,
                color: AppColors.infoBlue,
              ),
              _buildBreakdownChip(
                label: 'مدى',
                value: summary.madaSales,
                color: const Color(0xFF2563EB),
              ),
              _buildBreakdownChip(
                label: 'أخرى',
                value: summary.otherSales,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: const Text(
              'ملاحظة: أي مصروف أو سند صرف يتم خصمه من الرصيد النقدي فقط، بينما رصيد الشبكة يبقى مبنيًا على عمليات الدفع غير النقدي.',
              style: TextStyle(
                color: Color(0xFF475569),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancePanels(StationTreasurySummary summary) {
    final showVoucher = _canCreateVoucher && _selectedStationId != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!showVoucher || constraints.maxWidth < 980) {
          return Column(
            children: [
              _buildNetworkBreakdown(summary),
              if (showVoucher) ...[
                const SizedBox(height: 16),
                _buildVoucherForm(summary),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildNetworkBreakdown(summary)),
            const SizedBox(width: 16),
            Expanded(child: _buildVoucherForm(summary)),
          ],
        );
      },
    );
  }

  Widget _buildBreakdownChip({
    required String label,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        '$label: ${_moneyFormat.format(value)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildVoucherForm(StationTreasurySummary? summary) {
    final availableCash = summary?.cashBalance ?? 0;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إصدار سند صرف',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'المتاح حاليًا في الخزنة النقدية: ${_moneyFormat.format(availableCash)}',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recipientController,
              decoration: _inputDecoration(
                'اسم المستلم',
                Icons.person_outline_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اسم المستلم مطلوب';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration('المبلغ', Icons.payments_outlined),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'أدخل مبلغًا صحيحًا';
                }
                if (summary != null && amount > summary.cashBalance) {
                  return 'المبلغ أكبر من الرصيد النقدي الحالي';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: _inputDecoration('ملاحظات', Icons.notes_rounded),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _isSubmittingVoucher ? null : _submitVoucher,
                icon: const Icon(Icons.receipt_long_rounded),
                label: Text(
                  _isSubmittingVoucher ? 'جارٍ الحفظ...' : 'حفظ سند الصرف',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersSection() {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'سجلات سندات الصرف',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Text(
                '${_vouchers.length} سجل',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'جميع سندات الصرف المسجلة للمحطة المختارة مع الرصيد قبل وبعد الصرف.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          if (_vouchers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Text(
                  'لا توجد سندات صرف مسجلة لهذه المحطة حتى الآن.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ..._vouchers.map(_buildVoucherCard),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(StationTreasuryVoucherRecord voucher) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: const [],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    voucher.recipientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  _moneyFormat.format(voucher.amount),
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildVoucherMeta('رقم السند', voucher.voucherNumber),
                _buildVoucherMeta(
                  'الرصيد قبل',
                  _moneyFormat.format(voucher.cashBalanceBefore),
                ),
                _buildVoucherMeta(
                  'الرصيد بعد',
                  _moneyFormat.format(voucher.cashBalanceAfter),
                ),
                if (voucher.createdByName.trim().isNotEmpty)
                  _buildVoucherMeta('أُنشئ بواسطة', voucher.createdByName),
                if (voucher.createdAt != null)
                  _buildVoucherMeta(
                    'التاريخ',
                    _dateFormat.format(voucher.createdAt!),
                  ),
              ],
            ),
            if (voucher.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                voucher.notes,
                style: const TextStyle(color: Color(0xFF475569), height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherMeta(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.appBarWaterBright.withValues(alpha: 0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.appBarWaterBright,
          width: 1.4,
        ),
      ),
    );
  }
}

class _TreasuryMetric {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isCurrency;

  const _TreasuryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isCurrency = true,
  });
}
