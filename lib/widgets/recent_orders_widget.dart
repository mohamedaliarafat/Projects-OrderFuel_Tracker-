import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/order_model.dart';
import 'package:order_tracker/utils/constants.dart';

class RecentOrdersWidget extends StatelessWidget {
  final List<Order> orders;
  final bool isDesktop;

  const RecentOrdersWidget({
    super.key,
    required this.orders,
    this.isDesktop = false,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'في انتظار عمل طلب جديد':
        return AppColors.pendingYellow;
      case 'تم دمجه':
        return AppColors.warningOrange;
      case 'مدمج وجاهز للتنفيذ':
        return AppColors.infoBlue;
      case 'تم التنفيذ':
        return AppColors.successGreen;
      case 'ملغى':
        return AppColors.errorRed;
      default:
        return AppColors.lightGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'لا توجد طلبات حديثة',
            style: TextStyle(color: AppColors.mediumGray),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ...orders.asMap().entries.map((entry) {
            final order = entry.value;
            final isLast = entry.key == orders.length - 1;

            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: AppColors.lightGray.withOpacity(0.5),
                        ),
                      ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      order.orderNumber.substring(order.orderNumber.length - 3),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  order.supplierName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  DateFormat('yyyy/MM/dd').format(order.orderDate),
                  style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(order.status)),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/order/details',
                    arguments: order.id,
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
