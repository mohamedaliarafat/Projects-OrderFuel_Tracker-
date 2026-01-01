import 'package:flutter/material.dart';
import 'package:order_tracker/utils/constants.dart';

class AdvancedFilterSheet extends StatefulWidget {
  const AdvancedFilterSheet({super.key});

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  final Map<String, dynamic> _filters = {};
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;
  String? _selectedCity;
  String? _selectedType;

  final List<String> _statusOptions = [
    'في انتظار التحميل',
    'جاهز للتحميل',
    'مخصص للعميل',
    'في الطريق',
    'تم التحميل',
    'تم التسليم',
    'ملغى',
    'مكتمل',
  ];

  final List<String> _cityOptions = [
    'الرياض',
    'جدة',
    'مكة',
    'المدينة',
    'الدمام',
    'الخبر',
    'الطائف',
    'أبها',
  ];

  final List<String> _typeOptions = ['عميل', 'مورد', 'مدمج', 'جميع الأنواع'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'فلاتر متقدمة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو الرقم...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _filters['search'] = value.isNotEmpty ? value : null;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Date Range
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفترة الزمنية',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'من تاريخ',
                                  style: TextStyle(
                                    color: AppColors.mediumGray,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectDate(true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.lightGray,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _startDate != null
                                              ? _formatDate(_startDate!)
                                              : 'اختر التاريخ',
                                          style: TextStyle(
                                            color: _startDate != null
                                                ? AppColors.darkGray
                                                : AppColors.mediumGray,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إلى تاريخ',
                                  style: TextStyle(
                                    color: AppColors.mediumGray,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectDate(false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.lightGray,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _endDate != null
                                              ? _formatDate(_endDate!)
                                              : 'اختر التاريخ',
                                          style: TextStyle(
                                            color: _endDate != null
                                                ? AppColors.darkGray
                                                : AppColors.mediumGray,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Filter
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'حالة الطلب',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _statusOptions.map((status) {
                          return ChoiceChip(
                            label: Text(status),
                            selected: _selectedStatus == status,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected ? status : null;
                                _filters['status'] = _selectedStatus;
                              });
                            },
                            selectedColor: AppColors.primaryBlue,
                            labelStyle: TextStyle(
                              color: _selectedStatus == status
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // City Filter
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المدينة',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _cityOptions.map((city) {
                          return ChoiceChip(
                            label: Text(city),
                            selected: _selectedCity == city,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCity = selected ? city : null;
                                _filters['city'] = _selectedCity;
                              });
                            },
                            selectedColor: AppColors.secondaryTeal,
                            labelStyle: TextStyle(
                              color: _selectedCity == city
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Type Filter
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع الطلب',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _typeOptions.map((type) {
                          return ChoiceChip(
                            label: Text(type),
                            selected: _selectedType == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = selected ? type : null;
                                _filters['type'] = _selectedType;
                              });
                            },
                            selectedColor: AppColors.successGreen,
                            labelStyle: TextStyle(
                              color: _selectedType == type
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.errorRed),
                      ),
                      child: const Text(
                        'مسح الكل',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('تطبيق الفلاتر'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
          _filters['startDate'] = _formatDate(selectedDate);
        } else {
          _endDate = selectedDate;
          _filters['endDate'] = _formatDate(selectedDate);
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
      _selectedStatus = null;
      _selectedCity = null;
      _selectedType = null;
      _filters.clear();
    });
  }

  void _applyFilters() {
    // تنظيف الفلاتر الفارغة
    final cleanFilters = Map<String, dynamic>.from(_filters)
      ..removeWhere((key, value) => value == null || value.toString().isEmpty);

    // يمكنك إرجاع الفلاتر للشاشة الرئيسية
    Navigator.pop(context, cleanFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
