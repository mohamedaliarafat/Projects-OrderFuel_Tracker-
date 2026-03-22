import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/utils/constants.dart';

class MaintenanceCard extends StatelessWidget {
  final dynamic record;
  final VoidCallback onTap;
  final bool isLargeScreen;

  const MaintenanceCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.isLargeScreen,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مكتمل':
        return Colors.green;
      case 'غير مكتمل':
      case 'غير_مكتمل':
        return Colors.red;
      case 'تحت المراجعة':
      case 'تحت_المراجعة':
        return Colors.orange;
      case 'مرفوض':
        return Colors.grey;
      default:
        return AppColors.appBarWaterMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(20);

    final status = (record['monthlyStatus'] ?? record['status'] ?? 'غير مكتمل')
        .toString()
        .replaceAll('_', ' ')
        .trim();
    final statusColor = _getStatusColor(status);

    final plateNumber =
        (record['plateNumber'] ?? record['vehicleNumber'] ?? 'غير محدد')
            .toString()
            .trim();
    final driverName = (record['driverName'] ?? record['driver'] ?? 'غير محدد')
        .toString()
        .trim();

    final completedDays =
        int.tryParse((record['completedDays'] ?? '0').toString()) ?? 0;
    final totalDays =
        int.tryParse((record['totalDays'] ?? '30').toString()) ?? 30;
    final ratio = totalDays > 0
        ? (completedDays / totalDays).clamp(0.0, 1.0)
        : 0.0;
    final completionRate = (ratio * 100).toStringAsFixed(1);

    final tankNumber = (record['tankNumber'] ?? 'غير محدد').toString().trim();
    final inspectionMonth = record['inspectionMonth']?.toString().trim();
    final inspectionLabel = (inspectionMonth ?? '').isNotEmpty
        ? DateFormat('MMM yyyy').format(DateTime.parse('$inspectionMonth-01'))
        : '';

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 18 : 16),
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
                            plateNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.appBarWaterDeep,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            driverName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.mediumGray.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        status,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      'الإنجاز',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGray,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$completionRate%',
                      textDirection: ui.TextDirection.ltr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: AppColors.silverLight.withValues(
                      alpha: 0.75,
                    ),
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.local_gas_station_outlined,
                      size: 16,
                      color: AppColors.mediumGray.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tankNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGray.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    if (inspectionLabel.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: AppColors.mediumGray.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        inspectionLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGray.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      '$completedDays/$totalDays يوم',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mediumGray.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
