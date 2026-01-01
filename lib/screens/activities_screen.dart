import 'package:flutter/material.dart';
import 'package:order_tracker/providers/order_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/activity_item.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 1;
  String? _filterType;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  final List<String> _activityTypes = [
    'الكل',
    'إنشاء',
    'تعديل',
    'حذف',
    'تغيير حالة',
    'إضافة ملاحظة',
    'رفع ملف',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivities();
    });

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities({bool loadMore = false}) async {
    if (loadMore) {
      setState(() {
        _isLoadingMore = true;
      });
      _currentPage++;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final filters = <String, dynamic>{};
    if (_filterType != null && _filterType != 'الكل') {
      filters['activityType'] = _filterType;
    }
    if (_filterStartDate != null) {
      filters['startDate'] = _filterStartDate!.toIso8601String();
    }
    if (_filterEndDate != null) {
      filters['endDate'] = _filterEndDate!.toIso8601String();
    }

    await orderProvider.fetchActivities();

    if (loadMore) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadActivities(loadMore: true);
    }
  }

  Future<void> _showFilterDialog() async {
    String? selectedType = _filterType;
    DateTime? startDate = _filterStartDate;
    DateTime? endDate = _filterEndDate;

    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('تصفية الحركات'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: isDesktop ? 500 : double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        labelText: 'نوع الحركة',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _activityTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value == 'الكل' ? null : value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildDatePicker(
                                  context: context,
                                  date: startDate,
                                  label: 'من تاريخ',
                                  onDatePicked: (picked) {
                                    setState(() {
                                      startDate = picked;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDatePicker(
                                  context: context,
                                  date: endDate,
                                  label: 'إلى تاريخ',
                                  onDatePicked: (picked) {
                                    setState(() {
                                      endDate = picked;
                                    });
                                  },
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildDatePicker(
                                context: context,
                                date: startDate,
                                label: 'من تاريخ',
                                onDatePicked: (picked) {
                                  setState(() {
                                    startDate = picked;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildDatePicker(
                                context: context,
                                date: endDate,
                                label: 'إلى تاريخ',
                                onDatePicked: (picked) {
                                  setState(() {
                                    endDate = picked;
                                  });
                                },
                              ),
                            ],
                          ),
                  ],
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
                  setState(() {
                    _filterType = selectedType;
                    _filterStartDate = startDate;
                    _filterEndDate = endDate;
                  });
                  Navigator.pop(context);
                  _loadActivities();
                },
                child: const Text('تطبيق'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required DateTime? date,
    required String label,
    required Function(DateTime) onDatePicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryBlue,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDatePicked(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? DateFormat('yyyy/MM/dd').format(date!) : label,
              style: TextStyle(
                color: date != null ? Colors.black : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: date != null
                  ? AppColors.primaryBlue
                  : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _filterStartDate = null;
      _filterEndDate = null;
      _currentPage = 1;
    });
    _loadActivities();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final activities = orderProvider.activities;
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('سجل الحركات'),
              actions: [
                if (_filterType != null ||
                    _filterStartDate != null ||
                    _filterEndDate != null)
                  IconButton(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off),
                    tooltip: 'مسح الفلاتر',
                  ),
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_alt),
                  tooltip: 'تصفية',
                ),
              ],
            ),
      body: isDesktop
          ? _buildDesktopLayout(context, orderProvider, activities)
          : _buildMobileLayout(context, orderProvider, activities),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    OrderProvider orderProvider,
    List activities,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        _currentPage = 1;
        await _loadActivities();
      },
      child: Column(
        children: [
          // Active filters chips
          if (_filterType != null ||
              _filterStartDate != null ||
              _filterEndDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.backgroundGray,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_filterType != null)
                    Chip(
                      label: Text('النوع: $_filterType'),
                      onDeleted: () {
                        setState(() {
                          _filterType = null;
                        });
                        _loadActivities();
                      },
                    ),
                  if (_filterStartDate != null)
                    Chip(
                      label: Text(
                        'من: ${DateFormat('yyyy/MM/dd').format(_filterStartDate!)}',
                      ),
                      onDeleted: () {
                        setState(() {
                          _filterStartDate = null;
                        });
                        _loadActivities();
                      },
                    ),
                  if (_filterEndDate != null)
                    Chip(
                      label: Text(
                        'إلى: ${DateFormat('yyyy/MM/dd').format(_filterEndDate!)}',
                      ),
                      onDeleted: () {
                        setState(() {
                          _filterEndDate = null;
                        });
                        _loadActivities();
                      },
                    ),
                ],
              ),
            ),
          // Activities list
          Expanded(
            child: orderProvider.isLoading && _currentPage == 1
                ? const Center(child: CircularProgressIndicator())
                : activities.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد حركات مسجلة',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: activities.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == activities.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ActivityItem(activity: activities[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    OrderProvider orderProvider,
    List activities,
  ) {
    return Container(
      color: AppColors.backgroundGray,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar for filters
          Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سجل الحركات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    IconButton(
                      onPressed: _clearFilters,
                      icon: Icon(Icons.refresh, color: AppColors.primaryBlue),
                      tooltip: 'تحديث',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'التصفية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 16),

                // Filter by type
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نوع الحركة',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mediumGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activityTypes.map((type) {
                          final bool isSelected =
                              _filterType == type ||
                              (_filterType == null && type == 'الكل');
                          return FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _filterType = selected
                                    ? (type == 'الكل' ? null : type)
                                    : null;
                              });
                              _loadActivities();
                            },
                            selectedColor: AppColors.primaryBlue.withOpacity(
                              0.2,
                            ),
                            checkmarkColor: AppColors.primaryBlue,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.darkGray,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Date filters
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التاريخ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mediumGray,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDatePicker(
                        context: context,
                        date: _filterStartDate,
                        label: 'من تاريخ',
                        onDatePicked: (picked) {
                          setState(() {
                            _filterStartDate = picked;
                          });
                          _loadActivities();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDatePicker(
                        context: context,
                        date: _filterEndDate,
                        label: 'إلى تاريخ',
                        onDatePicked: (picked) {
                          setState(() {
                            _filterEndDate = picked;
                          });
                          _loadActivities();
                        },
                      ),
                      if (_filterStartDate != null || _filterEndDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ElevatedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('مسح التاريخ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.errorRed,
                              side: BorderSide(color: AppColors.errorRed),
                              minimumSize: const Size.fromHeight(40),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإحصائيات',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: AppColors.primaryBlue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'إجمالي الحركات:',
                              style: TextStyle(
                                color: AppColors.mediumGray,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            activities.length.toString(),
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: AppColors.primaryBlue,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'مستخدمة التصفية:',
                              style: TextStyle(
                                color: AppColors.mediumGray,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            (_filterType != null ||
                                    _filterStartDate != null ||
                                    _filterEndDate != null)
                                ? 'نعم'
                                : 'لا',
                            style: TextStyle(
                              color:
                                  (_filterType != null ||
                                      _filterStartDate != null ||
                                      _filterEndDate != null)
                                  ? AppColors.successGreen
                                  : AppColors.mediumGray,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _currentPage = 1;
                await _loadActivities();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'جميع الحركات (${activities.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        if (_filterType != null ||
                            _filterStartDate != null ||
                            _filterEndDate != null)
                          Wrap(
                            spacing: 8,
                            children: [
                              if (_filterType != null)
                                Chip(
                                  label: Text('النوع: $_filterType'),
                                  onDeleted: () {
                                    setState(() {
                                      _filterType = null;
                                    });
                                    _loadActivities();
                                  },
                                ),
                              if (_filterStartDate != null)
                                Chip(
                                  label: Text(
                                    'من: ${DateFormat('yyyy/MM/dd').format(_filterStartDate!)}',
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _filterStartDate = null;
                                    });
                                    _loadActivities();
                                  },
                                ),
                              if (_filterEndDate != null)
                                Chip(
                                  label: Text(
                                    'إلى: ${DateFormat('yyyy/MM/dd').format(_filterEndDate!)}',
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _filterEndDate = null;
                                    });
                                    _loadActivities();
                                  },
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Activities list
                  Expanded(
                    child: orderProvider.isLoading && _currentPage == 1
                        ? const Center(child: CircularProgressIndicator())
                        : activities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_toggle_off,
                                  size: 100,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'لا توجد حركات مسجلة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'جرب تغيير معايير التصفية',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(24),
                            itemCount:
                                activities.length + (_isLoadingMore ? 1 : 0),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              if (index == activities.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: ActivityItem(
                                  activity: activities[index],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
