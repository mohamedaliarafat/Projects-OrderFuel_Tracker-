import 'package:flutter/material.dart';
import 'package:order_tracker/utils/constants.dart';

class SupplierFilterDialog extends StatefulWidget {
  const SupplierFilterDialog({super.key});

  @override
  State<SupplierFilterDialog> createState() => _SupplierFilterDialogState();
}

class _SupplierFilterDialogState extends State<SupplierFilterDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _supplierType;
  String? _status;
  String? _name;
  String? _company;

  final List<String> _supplierTypes = [
    'الكل',
    'وقود',
    'صيانة',
    'خدمات لوجستية',
    'أخرى',
  ];

  final List<String> _statuses = ['الكل', 'نشط', 'غير نشط'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تصفية الموردين'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _supplierType,
                  decoration: InputDecoration(
                    labelText: 'نوع المورد',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.glassBlue.withOpacity(0.1),
                  ),
                  items: _supplierTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'الكل' ? null : value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _supplierType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.glassBlue.withOpacity(0.1),
                  ),
                  items: _statuses.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'الكل'
                          ? null
                          : (value == 'نشط' ? 'true' : 'false'),
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _status = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'اسم المورد',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.glassBlue.withOpacity(0.1),
                  ),
                  onChanged: (value) {
                    _name = value;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'الشركة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.glassBlue.withOpacity(0.1),
                  ),
                  onChanged: (value) {
                    _company = value;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final filters = {
              if (_supplierType != null && _supplierType!.isNotEmpty)
                'supplierType': _supplierType!,
              if (_status != null) 'isActive': _status!,
              if (_name != null && _name!.isNotEmpty) 'name': _name!,
              if (_company != null && _company!.isNotEmpty)
                'company': _company!,
            };
            Navigator.pop(context, filters);
          },
          child: const Text('تطبيق'),
        ),
      ],
    );
  }
}
