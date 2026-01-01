import 'package:flutter/material.dart';
import 'package:order_tracker/utils/constants.dart';

class ReportSummary extends StatelessWidget {
  final String title;
  final Map<String, dynamic> statistics;
  final Map<String, dynamic> period;

  const ReportSummary({
    super.key,
    required this.title,
    required this.statistics,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final totalCustomers = statistics['totalCustomers'] ?? 0;
    final totalOrders = statistics['totalOrders'] ?? 0;
    final totalAmount = statistics['totalAmount'] ?? 0;
    final totalQuantity = statistics['totalQuantity'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Chip(
                label: Text(
                  '${_formatDateRange()}',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'إجمالي العملاء',
                totalCustomers.toString(),
                Icons.people,
                AppColors.primaryBlue,
              ),
              _buildStatCard(
                'إجمالي الطلبات',
                totalOrders.toString(),
                Icons.shopping_cart,
                AppColors.secondaryTeal,
              ),
              _buildStatCard(
                'إجمالي المبلغ',
                '${_formatNumber(totalAmount)} ريال',
                Icons.monetization_on,
                AppColors.successGreen,
              ),
              _buildStatCard(
                'إجمالي الكمية',
                _formatNumber(totalQuantity),
                Icons.inventory,
                AppColors.warningOrange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Additional Stats
          if (statistics['avgSuccessRate'] != null ||
              statistics['avgPaymentRate'] != null)
            _buildAdditionalStats(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
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

  Widget _buildAdditionalStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (statistics['avgSuccessRate'] != null)
          _buildMiniStat(
            'متوسط النجاح',
            '${_formatNumber(statistics['avgSuccessRate'])}%',
            AppColors.successGreen,
          ),
        if (statistics['avgPaymentRate'] != null)
          _buildMiniStat(
            'متوسط السداد',
            '${_formatNumber(statistics['avgPaymentRate'])}%',
            AppColors.infoBlue,
          ),
        if (statistics['avgOrderValue'] != null)
          _buildMiniStat(
            'متوسط الطلب',
            '${_formatNumber(statistics['avgOrderValue'])} ريال',
            AppColors.warningOrange,
          ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.mediumGray),
        ),
      ],
    );
  }

  String _formatDateRange() {
    final start = period['startDate']?.toString() ?? '--/--/----';
    final end = period['endDate']?.toString() ?? '--/--/----';
    return '$start - $end';
  }

  String _formatNumber(dynamic number) {
    if (number is double) {
      return number.toStringAsFixed(2);
    }
    return number.toString();
  }
}
