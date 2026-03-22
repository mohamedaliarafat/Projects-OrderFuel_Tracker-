import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:order_tracker/utils/constants.dart';

class SupplierRatingChart extends StatelessWidget {
  final List<dynamic> suppliers;

  const SupplierRatingChart({
    super.key,
    required this.suppliers,
    required bool isLargeScreen,
  });

  @override
  Widget build(BuildContext context) {
    final topRatedSuppliers = suppliers
        .where((s) => (s['rating'] ?? 0) > 0)
        .take(5)
        .toList();

    final topOrderSuppliers = suppliers
        .where((s) => (s['totalOrders'] ?? 0) > 0)
        .take(5)
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBarChart(
              title: 'تقييم الموردين',
              data: topRatedSuppliers,
              valueKey: 'rating',
              color: AppColors.warningOrange,
              suffix: '',
            ),
            const SizedBox(height: 16),
            _buildBarChart(
              title: 'عدد الطلبات',
              data: topOrderSuppliers,
              valueKey: 'totalOrders',
              color: AppColors.primaryBlue,
              suffix: '',
            ),
            const SizedBox(height: 16),
            _buildSupplierSummary(),
          ],
        ),
      ),
    );
  }

  /// ================= Bar Chart =================
  Widget _buildBarChart({
    required String title,
    required List data,
    required String valueKey,
    required Color color,
    required String suffix,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelRotation: 45,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(width: 0.5),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  BarSeries<dynamic, String>(
                    dataSource: data,
                    xValueMapper: (item, _) =>
                        item['supplierName'] ?? 'غير معروف',
                    yValueMapper: (item, _) => (item[valueKey] ?? 0).toDouble(),
                    color: color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.middle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= Summary =================
  Widget _buildSupplierSummary() {
    final avgRating = suppliers.isEmpty
        ? 0
        : suppliers
                  .map((s) => (s['rating'] ?? 0).toDouble())
                  .reduce((a, b) => a + b) /
              suppliers.length;

    final avgSuccessRate = suppliers.isEmpty
        ? 0
        : suppliers
                  .map((s) => (s['successRate'] ?? 0).toDouble())
                  .reduce((a, b) => a + b) /
              suppliers.length;

    final totalAmount = suppliers
        .map((s) => (s['totalAmount'] ?? 0).toDouble())
        .fold(0.0, (a, b) => a + b);

    final activeSuppliers = suppliers
        .where((s) => s['isActive'] == true)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص الموردين',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildSummaryItem(
                  'متوسط التقييم',
                  avgRating.toStringAsFixed(1),
                  AppColors.warningOrange,
                ),
                _buildSummaryItem(
                  'متوسط النجاح',
                  '${avgSuccessRate.toStringAsFixed(1)}%',
                  AppColors.successGreen,
                ),
                _buildSummaryItem(
                  'إجمالي المبلغ',
                  '${totalAmount.toInt()} ريال',
                  AppColors.primaryBlue,
                ),
                _buildSummaryItem(
                  'الموردين النشطين',
                  '$activeSuppliers',
                  AppColors.secondaryTeal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.mediumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
