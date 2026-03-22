import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:order_tracker/models/station_models.dart';
import 'package:order_tracker/models/station_treasury_models.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';
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
    ).replace(queryParameters: {'stationId': stationId});

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
    final uri = Uri.parse(
      '${ApiEndpoints.baseUrl}/stations/treasury/vouchers',
    ).replace(queryParameters: {
      'stationId': stationId,
      'page': '1',
      'limit': '100',
    });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('خزنة المحطات'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTreasuryData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilterCard(),
            if (_isBusy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 3),
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
              _buildNetworkBreakdown(summary),
            ],
            if (_canCreateVoucher && _selectedStationId != null) ...[
              const SizedBox(height: 16),
              _buildVoucherForm(summary),
            ],
            const SizedBox(height: 16),
            _buildVouchersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedStationId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'المحطة',
                      border: OutlineInputBorder(),
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
                ],
              ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.errorRed.withValues(alpha: 0.20),
        ),
      ),
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

  Widget _buildInfoCard(StationTreasurySummary summary) {
    final stationName = _overview?.station.stationName ?? '';
    final stationCode = _overview?.station.stationCode ?? '';
    final infoText = summary.computedAt != null
        ? 'آخر تحديث: ${_dateFormat.format(summary.computedAt!)}'
        : 'البيانات محسوبة من الجلسات المغلقة والمعتمدة';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stationName.isEmpty ? 'خزنة المحطة' : stationName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (stationCode.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              stationCode,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            infoText,
            style: const TextStyle(color: Colors.white),
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

    return LayoutBuilder(
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
    );
  }

  Widget _buildMetricCard(_TreasuryMetric metric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفصيل مبيعات الشبكة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            const Text(
              'ملاحظة: أي مصروف أو سند صرف يتم خصمه من الرصيد النقدي فقط، بينما رصيد الشبكة يبقى مبنيًا على عمليات الدفع غير النقدي.',
              style: TextStyle(
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
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
      ),
      child: Text(
        '$label: ${_moneyFormat.format(value)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildVoucherForm(StationTreasurySummary? summary) {
    final availableCash = summary?.cashBalance ?? 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إصدار سند صرف',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'المتاح حاليًا في الخزنة النقدية: ${_moneyFormat.format(availableCash)}',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستلم',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: _isSubmittingVoucher ? null : _submitVoucher,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: Text(
                    _isSubmittingVoucher ? 'جارٍ الحفظ...' : 'حفظ سند الصرف',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVouchersSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'سجلات سندات الصرف',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${_vouchers.length} سجل',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_vouchers.isEmpty)
              const Text(
                'لا توجد سندات صرف مسجلة لهذه المحطة حتى الآن.',
                style: TextStyle(color: Color(0xFF64748B)),
              )
            else
              ..._vouchers.map(_buildVoucherCard),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(StationTreasuryVoucherRecord voucher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
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
              style: const TextStyle(
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoucherMeta(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
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
