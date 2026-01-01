import 'package:flutter/material.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/order_model.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:intl/intl.dart';

class OverdueOrdersWidget extends StatelessWidget {
  final List<Order> orders;
  final VoidCallback? onViewAll;

  const OverdueOrdersWidget({super.key, required this.orders, this.onViewAll});

  List<Order> _getOverdueOrders() {
    final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
    return orders.where((order) {
      return order.status == 'قيد الانتظار' &&
          order.createdAt.isBefore(twoHoursAgo) &&
          order.notificationSentAt == null;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final overdueOrders = _getOverdueOrders();

    if (overdueOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_outlined,
                        color: AppColors.errorRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلبات متأخرة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.errorRed,
                          ),
                        ),
                        Text(
                          '${overdueOrders.length} طلب يحتاج للتعيين',
                          style: TextStyle(
                            color: AppColors.errorRed.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('عرض الكل'),
                  ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: AppColors.errorRed.withOpacity(0.2)),

          // Orders list
          ...overdueOrders.take(3).map((order) {
            return _buildOverdueOrderItem(context, order);
          }).toList(),

          // Show more indicator
          if (overdueOrders.length > 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'و ${overdueOrders.length - 3} طلب إضافي',
                  style: TextStyle(color: AppColors.errorRed.withOpacity(0.8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverdueOrderItem(BuildContext context, Order order) {
    final hoursSinceCreation = DateTime.now()
        .difference(order.createdAt)
        .inHours;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.orderDetails,
            arguments: order.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Order icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    order.orderNumber.substring(order.orderNumber.length - 3),
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.supplierName,
                      style: TextStyle(color: AppColors.mediumGray),
                    ),
                  ],
                ),
              ),

              // Time info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'منذ $hoursSinceCreation ساعة',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(order.createdAt),
                    style: TextStyle(color: AppColors.lightGray, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
