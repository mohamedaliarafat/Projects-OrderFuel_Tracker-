import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:order_tracker/utils/constants.dart';

class DriverStatsChart extends StatelessWidget {
  final List<dynamic> drivers;

  const DriverStatsChart({super.key, required this.drivers, required bool isLargeScreen});

  @override
  Widget build(BuildContext context) {
    final topEarningDrivers = drivers
        .where((d) => (d['totalEarnings'] ?? 0) > 0)
        .take(5)
        .toList();

    final topOrderDrivers = drivers
        .where((d) => (d['totalOrders'] ?? 0) > 0)
        .take(5)
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBarChart(
              title: 'أعلى الأرباح',
              data: topEarningDrivers,
              valueKey: 'totalEarnings',
              color: AppColors.secondaryTeal,
              suffix: ' ريال',
            ),
            const SizedBox(height: 16),
            _buildBarChart(
              title: 'أعلى عدد الطلبات',
              data: topOrderDrivers,
              valueKey: 'totalOrders',
              color: AppColors.primaryBlue,
              suffix: '',
            ),
            const SizedBox(height: 16),
            _buildPerformanceSummary(),
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
                        item['driverName'] ?? 'غير معروف',
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
  Widget _buildPerformanceSummary() {
    final avgSuccessRate = drivers.isEmpty
        ? 0
        : drivers
                  .map((d) => (d['successRate'] ?? 0).toDouble())
                  .reduce((a, b) => a + b) /
              drivers.length;

    final avgOnTimeRate = drivers.isEmpty
        ? 0
        : drivers
                  .map((d) => (d['onTimeRate'] ?? 0).toDouble())
                  .reduce((a, b) => a + b) /
              drivers.length;

    final totalEarnings = drivers
        .map((d) => (d['totalEarnings'] ?? 0).toDouble())
        .fold(0.0, (a, b) => a + b);

    final totalOrders = drivers
        .map((d) => (d['totalOrders'] ?? 0).toDouble())
        .fold(0.0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص الأداء',
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
                  'متوسط النجاح',
                  '${avgSuccessRate.toStringAsFixed(1)}%',
                  AppColors.successGreen,
                ),
                _buildSummaryItem(
                  'متوسط التوقيت',
                  '${avgOnTimeRate.toStringAsFixed(1)}%',
                  AppColors.infoBlue,
                ),
                _buildSummaryItem(
                  'إجمالي الأرباح',
                  '${totalEarnings.toInt()} ريال',
                  AppColors.secondaryTeal,
                ),
                _buildSummaryItem(
                  'إجمالي الطلبات',
                  totalOrders.toInt().toString(),
                  AppColors.primaryBlue,
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
