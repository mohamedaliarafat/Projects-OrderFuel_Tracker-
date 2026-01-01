import 'package:flutter/material.dart';
import 'package:order_tracker/models/supplier_model.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class SupplierDataSource extends DataGridSource {
  SupplierDataSource(List<Supplier> suppliers) {
    _suppliers = suppliers;
    _buildDataGridRows();
  }

  List<DataGridRow> dataGridRows = [];
  List<Supplier> _suppliers = [];

  void _buildDataGridRows() {
    dataGridRows = _suppliers.map<DataGridRow>((supplier) {
      return DataGridRow(
        cells: [
          DataGridCell<String>(columnName: 'name', value: supplier.name),
          DataGridCell<String>(columnName: 'company', value: supplier.company),
          DataGridCell<String>(
            columnName: 'contactPerson',
            value: supplier.contactPerson,
          ),
          DataGridCell<String>(columnName: 'phone', value: supplier.phone),
          DataGridCell<String>(
            columnName: 'supplierType',
            value: supplier.supplierType,
          ),
          DataGridCell<Widget>(
            columnName: 'statusRating',
            value: _buildStatusRatingCell(supplier),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildStatusRatingCell(Supplier supplier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: supplier.isActive
                    ? AppColors.successGreen
                    : AppColors.errorRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              supplier.isActive ? 'نشط' : 'غير نشط',
              style: TextStyle(
                color: supplier.isActive
                    ? AppColors.successGreen
                    : AppColors.errorRed,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < supplier.rating.round() ? Icons.star : Icons.star_border,
              size: 14,
              color: AppColors.warningOrange,
            );
          }),
        ),
      ],
    );
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        return Container(
          padding: const EdgeInsets.all(12),
          alignment: Alignment.centerRight,
          child: dataGridCell.columnName == 'statusRating'
              ? dataGridCell.value
              : Text(
                  dataGridCell.value.toString(),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  textAlign: TextAlign.right,
                ),
        );
      }).toList(),
    );
  }
}

class SupplierDataGrid extends StatelessWidget {
  final SupplierDataSource dataSource;
  final void Function(Supplier)? onRowTap;

  const SupplierDataGrid({super.key, required this.dataSource, this.onRowTap});

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      source: dataSource,
      columns: [
        GridColumn(
          columnName: 'name',
          width: MediaQuery.of(context).size.width * 0.18,
          label: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerRight,
            child: const Text(
              'اسم المورد',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
        GridColumn(
          columnName: 'company',
          width: MediaQuery.of(context).size.width * 0.18,
          label: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerRight,
            child: const Text(
              'الشركة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
        GridColumn(
          columnName: 'contactPerson',
          width: MediaQuery.of(context).size.width * 0.15,
          label: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerRight,
            child: const Text(
              'جهة الاتصال',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
        GridColumn(
          columnName: 'phone',
          width: MediaQuery.of(context).size.width * 0.12,
          label: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerRight,
            child: const Text(
              'الهاتف',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
        GridColumn(
          columnName: 'supplierType',
          width: MediaQuery.of(context).size.width * 0.12,
          label: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerRight,
            child: const Text(
              'نوع المورد',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
        GridColumn(
          columnName: 'statusRating',
          width: MediaQuery.of(context).size.width * 0.15,
          label: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.centerRight,
            child: const Text(
              'الحالة / التقييم',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
      ],
      gridLinesVisibility: GridLinesVisibility.both,
      headerGridLinesVisibility: GridLinesVisibility.both,
      allowSorting: true,
      allowFiltering: true,
      selectionMode: SelectionMode.single,
      onCellTap: (details) {
        if (details.rowColumnIndex.rowIndex > 0 && onRowTap != null) {
          final supplierIndex = details.rowColumnIndex.rowIndex - 1;
          if (supplierIndex < dataSource._suppliers.length) {
            onRowTap!(dataSource._suppliers[supplierIndex]);
          }
        }
      },
    );
  }
}
