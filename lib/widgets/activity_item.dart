import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/utils/constants.dart';

class ActivityItem extends StatelessWidget {
  final Activity activity;

  const ActivityItem({super.key, required this.activity});

  IconData _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'إنشاء':
        return Icons.add_circle_outline;
      case 'تعديل':
        return Icons.edit_outlined;
      case 'حذف':
        return Icons.delete_outline;
      case 'تغيير حالة':
        return Icons.change_circle_outlined;
      case 'إضافة ملاحظة':
        return Icons.note_add_outlined;
      case 'رفع ملف':
        return Icons.attach_file_outlined;
      default:
        return Icons.history_outlined;
    }
  }

  Color _getActivityColor(String activityType) {
    switch (activityType) {
      case 'إنشاء':
        return AppColors.successGreen;
      case 'تعديل':
        return AppColors.infoBlue;
      case 'حذف':
        return AppColors.errorRed;
      case 'تغيير حالة':
        return AppColors.warningOrange;
      case 'إضافة ملاحظة':
        return AppColors.secondaryTeal;
      case 'رفع ملف':
        return AppColors.primaryBlue;
      default:
        return AppColors.mediumGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1024;
        final bool isDesktop = width >= 1024;

        final double padding = isDesktop
            ? 20
            : isTablet
            ? 18
            : 16;
        final double iconSize = isDesktop ? 24 : 20;
        final double titleSize = isDesktop ? 16 : 14;
        final double bodySize = isDesktop ? 15 : 14;
        final double smallSize = isDesktop ? 13 : 12;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getActivityColor(
                        activity.activityType,
                      ).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getActivityIcon(activity.activityType),
                      color: _getActivityColor(activity.activityType),
                      size: iconSize,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity.activityType,
                      style: TextStyle(
                        color: _getActivityColor(activity.activityType),
                        fontWeight: FontWeight.w600,
                        fontSize: titleSize,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(activity.createdAt),
                    style: TextStyle(
                      color: AppColors.mediumGray,
                      fontSize: smallSize,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// 📝 Description
              Text(
                activity.description,
                style: TextStyle(fontSize: bodySize, height: 1.5),
              ),

              const SizedBox(height: 12),

              /// 👤 Footer
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.mediumGray,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      activity.performedByName,
                      style: TextStyle(
                        color: AppColors.mediumGray,
                        fontSize: smallSize,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd').format(activity.createdAt),
                    style: TextStyle(
                      color: AppColors.mediumGray,
                      fontSize: smallSize,
                    ),
                  ),
                ],
              ),

              /// 🔄 Changes
              if (activity.changes != null && activity.changes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(isDesktop ? 14 : 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التغييرات:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: smallSize,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...activity.changes!.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${entry.key}: ${entry.value}',
                            style: TextStyle(fontSize: smallSize),
                            maxLines: isMobile ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
