import 'dart:async';
import 'package:flutter/material.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/order_model.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class OrderDataSource extends DataGridSource {
  OrderDataSource(List<Order> orders) {
    _orders = orders;
    _startTimer();
    _buildDataGridRows();
  }

  List<DataGridRow> dataGridRows = [];
  List<Order> _orders = [];
  late Timer _timer;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _buildDataGridRows();
      notifyListeners();
    });
  }

  void dispose() {
    _timer.cancel();
  }

  void _buildDataGridRows() {
    dataGridRows = _orders.map<DataGridRow>((order) {
      return DataGridRow(
        cells: [
          DataGridCell<String>(
            columnName: 'orderDate',
            value: _formatDate(order.orderDate),
          ),
          DataGridCell<String>(
            columnName: 'supplierName',
            value: order.supplierName,
          ),
          DataGridCell<String>(
            columnName: 'requestType',
            value: order.requestType,
          ),
          DataGridCell<String>(
            columnName: 'orderNumber',
            value: order.orderNumber,
          ),
          DataGridCell<String>(
            columnName: 'supplierOrderNumber',
            value: order.supplierOrderNumber ?? '-',
          ),
          DataGridCell<String>(
            columnName: 'loadingDate',
            value: _formatDate(order.loadingDate),
          ),
          DataGridCell<Widget>(
            columnName: 'timer',
            value: _buildTimerCell(order),
          ),
          DataGridCell<Widget>(
            columnName: 'statusDriver',
            value: _buildStatusCell(order),
          ),
        ],
      );
    }).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildTimerCell(Order order) {
    if (order.status == 'تم التحميل' || order.status == 'ملغى') {
      return const Text('—', style: TextStyle(color: Colors.grey));
    }

    final loadingDateTime = DateTime(
      order.loadingDate.year,
      order.loadingDate.month,
      order.loadingDate.day,
      int.parse(order.loadingTime.split(':')[0]),
      int.parse(order.loadingTime.split(':')[1]),
    );

    final diff = loadingDateTime.difference(DateTime.now());
    final isLate = diff.inSeconds < 0;

    return Row(
      children: [
        Icon(
          Icons.timer,
          size: 16,
          color: isLate ? AppColors.errorRed : AppColors.successGreen,
        ),
        const SizedBox(width: 6),
        Text(
          _formatDuration(diff),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isLate ? AppColors.errorRed : AppColors.successGreen,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return 'انتهى';

    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}ي');
    if (hours > 0 || days > 0) parts.add('${hours}س');
    if (minutes > 0 || hours > 0 || days > 0) parts.add('${minutes}د');
    parts.add('${seconds}ث');

    return parts.join(' ');
  }

  Widget _buildStatusCell(Order order) {
    Color statusColor;
    switch (order.status) {
      case 'قيد الانتظار':
        statusColor = AppColors.pendingYellow;
        break;
      case 'قيد التجهيز':
        statusColor = AppColors.warningOrange;
        break;
      case 'جاهز للتحميل':
        statusColor = AppColors.infoBlue;
        break;
      case 'تم التحميل':
        statusColor = AppColors.successGreen;
        break;
      case 'ملغى':
        statusColor = AppColors.errorRed;
        break;
      default:
        statusColor = AppColors.lightGray;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor, width: 0.8),
          ),
          child: Text(
            order.status,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (order.driverName != null && order.driverName!.isNotEmpty)
          Text(
            order.driverName!,
            style: const TextStyle(fontSize: 10, color: AppColors.mediumGray),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          alignment: Alignment.centerRight,
          child: cell.value is Widget
              ? cell.value
              : Text(
                  cell.value.toString(),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
        );
      }).toList(),
    );
  }
}

class OrderDataGrid extends StatelessWidget {
  final OrderDataSource dataSource;
  final void Function(Order)? onRowTap;

  const OrderDataGrid({super.key, required this.dataSource, this.onRowTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final isDesktop = width >= 1024;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SfDataGrid(
          source: dataSource,
          columns: _buildResponsiveColumns(
            width,
            isMobile,
            isTablet,
            isDesktop,
          ),
          gridLinesVisibility: GridLinesVisibility.both,
          headerGridLinesVisibility: GridLinesVisibility.both,
          allowSorting: true,
          allowFiltering: true,
          selectionMode: SelectionMode.single,

          // ⭐ التعديل المهم
          columnWidthMode: ColumnWidthMode.fill,
          rowHeight: 56, // ارتفاع ثابت مريح
          headerRowHeight: 48,

          onCellTap: (details) {
            if (details.rowColumnIndex.rowIndex > 0 && onRowTap != null) {
              final index = details.rowColumnIndex.rowIndex - 1;
              if (index < dataSource._orders.length) {
                onRowTap!(dataSource._orders[index]);
              }
            }
          },
        );
      },
    );
  }

  List<GridColumn> _buildResponsiveColumns(
    double width,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    // تعريف العناوين
    final columnTitles = {
      'orderDate': 'تاريخ الطلب',
      'supplierName': 'اسم المورد',
      'requestType': 'نوع الطلب',
      'orderNumber': 'رقم الطلب',
      'supplierOrderNumber': 'رقم طلب المورد',
      'loadingDate': 'تاريخ التحميل',
      'timer': 'الوقت المتبقي',
      'statusDriver': 'الحالة / السائق',
    };

    if (isMobile) {
      // للموبايل: عرض الأعمدة الأساسية فقط
      return [
        _createColumn('orderDate', columnTitles['orderDate']!, 85),
        _createColumn('supplierName', columnTitles['supplierName']!, 115),
        _createColumn('orderNumber', columnTitles['orderNumber']!, 65),
        _createColumn('timer', columnTitles['timer']!, 95),
        _createColumn(
          'statusDriver',
          columnTitles['statusDriver']!,
          100,
        ), // أقل عرضاً
      ];
    } else if (isTablet) {
      // للتابلت: عرض معظم الأعمدة
      return [
        _createColumn('orderDate', columnTitles['orderDate']!, 95),
        _createColumn('supplierName', columnTitles['supplierName']!, 135),
        _createColumn('orderNumber', columnTitles['orderNumber']!, 85),
        _createColumn('requestType', columnTitles['requestType']!, 95),
        _createColumn('timer', columnTitles['timer']!, 115),
        _createColumn(
          'statusDriver',
          columnTitles['statusDriver']!,
          120,
        ), // أقل عرضاً
      ];
    } else {
      // للكمبيوتر/الويب: عرض جميع الأعمدة
      return [
        _createColumn('orderDate', columnTitles['orderDate']!, width * 0.08),
        _createColumn(
          'supplierName',
          columnTitles['supplierName']!,
          width * 0.14,
        ),
        _createColumn('requestType', columnTitles['requestType']!, width * 0.1),
        _createColumn(
          'orderNumber',
          columnTitles['orderNumber']!,
          width * 0.08,
        ),
        _createColumn(
          'supplierOrderNumber',
          columnTitles['supplierOrderNumber']!,
          width * 0.1,
        ),
        _createColumn(
          'loadingDate',
          columnTitles['loadingDate']!,
          width * 0.09,
        ),
        _createColumn('timer', columnTitles['timer']!, width * 0.12),
        _createColumn(
          'statusDriver',
          columnTitles['statusDriver']!,
          width * 0.12, // أقل عرضاً للكمبيوتر أيضاً
        ),
      ];
    }
  }

  GridColumn _createColumn(String name, String title, double width) {
    final fontSize = width < 600
        ? 11.0
        : width < 1024
        ? 12.0
        : 14.0;
    final padding = width < 600
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 10)
        : width < 1024
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 10)
        : const EdgeInsets.all(12);

    return GridColumn(
      columnName: name,
      width: width,
      label: Container(
        padding: padding,
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            fontSize: fontSize,
          ),
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
