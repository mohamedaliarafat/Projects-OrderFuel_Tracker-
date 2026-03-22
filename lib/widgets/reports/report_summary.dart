import 'package:flutter/material.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/app_surface_card.dart';

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
    final theme = Theme.of(context);
    final totalCustomers = statistics['totalCustomers'] ?? 0;
    final totalOrders = statistics['totalOrders'] ?? 0;
    final totalAmount = statistics['totalAmount'] ?? 0;
    final totalQuantity = statistics['totalQuantity'] ?? 0;

    final bool hasAdditional =
        statistics['avgSuccessRate'] != null ||
        statistics['avgPaymentRate'] != null ||
        statistics['avgOrderValue'] != null;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.primaryBlue.withValues(alpha: 0.78),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateRange(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final int columns;
              final double aspect;

              if (w >= 980) {
                columns = 4;
                aspect = 2.90;
              } else if (w >= 640) {
                columns = 2;
                aspect = 3.05;
              } else {
                columns = 2;
                aspect = 2.75;
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspect,
                children: [
                  _buildStatCard(
                    context,
                    'إجمالي العملاء',
                    totalCustomers.toString(),
                    Icons.people_rounded,
                    AppColors.primaryBlue,
                  ),
                  _buildStatCard(
                    context,
                    'إجمالي الطلبات',
                    totalOrders.toString(),
                    Icons.shopping_cart_rounded,
                    AppColors.secondaryTeal,
                  ),
                  _buildStatCard(
                    context,
                    'إجمالي المبلغ',
                    '${_formatNumber(totalAmount)} ريال',
                    Icons.payments_rounded,
                    AppColors.successGreen,
                  ),
                  _buildStatCard(
                    context,
                    'إجمالي الكمية',
                    _formatNumber(totalQuantity),
                    Icons.inventory_2_rounded,
                    AppColors.warningOrange,
                  ),
                ],
              );
            },
          ),
          if (hasAdditional) ...[
            const SizedBox(height: 14),
            _buildAdditionalStats(context),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalStats(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_MiniStat>[];

    if (statistics['avgSuccessRate'] != null) {
      items.add(
        _MiniStat(
          label: 'متوسط النجاح',
          value: '${_formatNumber(statistics['avgSuccessRate'])}%',
          icon: Icons.verified_rounded,
          color: AppColors.successGreen,
        ),
      );
    }
    if (statistics['avgPaymentRate'] != null) {
      items.add(
        _MiniStat(
          label: 'متوسط السداد',
          value: '${_formatNumber(statistics['avgPaymentRate'])}%',
          icon: Icons.percent_rounded,
          color: AppColors.infoBlue,
        ),
      );
    }
    if (statistics['avgOrderValue'] != null) {
      items.add(
        _MiniStat(
          label: 'متوسط الطلب',
          value: '${_formatNumber(statistics['avgOrderValue'])} ريال',
          icon: Icons.trending_up_rounded,
          color: AppColors.warningOrange,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: item.color.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 16, color: item.color),
              const SizedBox(width: 8),
              Text(
                item.value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

class _MiniStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
