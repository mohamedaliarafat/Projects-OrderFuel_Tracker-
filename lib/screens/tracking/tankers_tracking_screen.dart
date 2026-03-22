import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:order_tracker/models/driver_model.dart';
import 'package:order_tracker/models/tanker_model.dart';
import 'package:order_tracker/providers/driver_provider.dart';
import 'package:order_tracker/providers/tanker_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/app_surface_card.dart';
import 'package:order_tracker/widgets/tracking/tracking_page_shell.dart';
import 'package:provider/provider.dart';

class TankersTrackingScreen extends StatefulWidget {
  const TankersTrackingScreen({super.key});

  @override
  State<TankersTrackingScreen> createState() => _TankersTrackingScreenState();
}

class _TankersTrackingScreenState extends State<TankersTrackingScreen> {
  static const List<String> _statuses = ['تحت الصيانة', 'في طلب', 'فاضي'];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TankerProvider>().fetchTankers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status.trim()) {
      case 'تحت الصيانة':
        return AppColors.pendingYellow;
      case 'في طلب':
        return AppColors.statusGold;
      case 'فاضي':
        return AppColors.successGreen;
      default:
        return Colors.grey;
    }
  }

  String _vehicleLabel(Tanker tanker) {
    final vehicleNumber = tanker.linkedVehicleNumber?.trim() ?? '';
    final driverName = tanker.linkedDriverName?.trim() ?? '';

    if (vehicleNumber.isNotEmpty && driverName.isNotEmpty) {
      return '$vehicleNumber • $driverName';
    }
    if (vehicleNumber.isNotEmpty) {
      return vehicleNumber;
    }
    if (driverName.isNotEmpty) {
      return driverName;
    }
    return 'غير مرتبط بسيارة';
  }

  String _capacityLabel(Tanker tanker) {
    final capacity = tanker.capacityLiters;
    if (capacity == null || capacity <= 0) {
      return 'غير محدد';
    }

    return '$capacity لتر';
  }

  List<Driver> _vehicleOptions(List<Driver> drivers, {Tanker? tanker}) {
    final items = drivers
        .where((driver) => (driver.vehicleNumber?.trim().isNotEmpty ?? false))
        .toList()
      ..sort((a, b) {
        final left = a.vehicleNumber?.trim().isNotEmpty == true
            ? a.vehicleNumber!.trim()
            : a.name.trim();
        final right = b.vehicleNumber?.trim().isNotEmpty == true
            ? b.vehicleNumber!.trim()
            : b.name.trim();
        return left.compareTo(right);
      });

    final linkedDriverId = tanker?.linkedDriverId?.trim() ?? '';
    if (linkedDriverId.isEmpty || items.any((driver) => driver.id == linkedDriverId)) {
      return items;
    }

    items.insert(
      0,
      Driver(
        id: linkedDriverId,
        name: tanker?.linkedDriverName?.trim().isNotEmpty == true
            ? tanker!.linkedDriverName!.trim()
            : 'المركبة الحالية',
        licenseNumber: '',
        phone: '',
        vehicleType: tanker?.linkedVehicleType?.trim().isNotEmpty == true
            ? tanker!.linkedVehicleType!.trim()
            : 'غير محدد',
        vehicleNumber: tanker?.linkedVehicleNumber,
        vehicleStatus: 'فاضي',
        status: 'نشط',
        isActive: true,
        createdById: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return items;
  }

  String _vehicleOptionLabel(Driver driver) {
    final vehicleNumber = driver.vehicleNumber?.trim() ?? '';
    if (vehicleNumber.isEmpty) {
      return driver.name;
    }

    return '$vehicleNumber • ${driver.name}';
  }

  Driver? _findDriverById(List<Driver> drivers, String? driverId) {
    if (driverId == null || driverId.trim().isEmpty) {
      return null;
    }

    for (final driver in drivers) {
      if (driver.id == driverId) {
        return driver;
      }
    }

    return null;
  }

  List<Tanker> _applySearch(List<Tanker> tankers) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return tankers;

    return tankers.where((tanker) {
      return tanker.number.toLowerCase().contains(query) ||
          tanker.status.toLowerCase().contains(query) ||
          (tanker.notes ?? '').toLowerCase().contains(query) ||
          (tanker.linkedVehicleNumber ?? '').toLowerCase().contains(query) ||
          (tanker.linkedDriverName ?? '').toLowerCase().contains(query) ||
          (tanker.linkedVehicleType ?? '').toLowerCase().contains(query) ||
          (tanker.capacityLiters?.toString() ?? '').contains(query);
    }).toList();
  }

  Future<void> _showTankerForm({Tanker? tanker}) async {
    final numberController = TextEditingController(text: tanker?.number ?? '');
    final capacityController = TextEditingController(
      text: tanker?.capacityLiters?.toString() ?? '',
    );
    final notesController = TextEditingController(text: tanker?.notes ?? '');
    final driverProvider = context.read<DriverProvider>();
    final provider = context.read<TankerProvider>();
    final vehicleDrivers = _vehicleOptions(
      await driverProvider.fetchActiveDrivers(),
      tanker: tanker,
    );

    if (!mounted) return;

    String status = _statuses.contains(tanker?.status) ? tanker!.status : 'فاضي';
    String? linkedDriverId = tanker?.linkedDriverId?.trim().isNotEmpty == true
        ? tanker!.linkedDriverId!.trim()
        : null;

    if (linkedDriverId != null &&
        vehicleDrivers.every((driver) => driver.id != linkedDriverId)) {
      linkedDriverId = null;
    }

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(tanker == null ? 'إضافة صهريج' : 'تعديل الصهريج'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'رقم الصهريج / اللوحة',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرقم مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: linkedDriverId,
                      decoration: InputDecoration(
                        labelText: 'السيارة المرتبطة',
                        prefixIcon: const Icon(Icons.directions_car_filled_outlined),
                        helperText: vehicleDrivers.isEmpty
                            ? 'لا توجد سيارات مسجلة للسائقين حالياً'
                            : 'اختر السيارة التي يعمل معها هذا الصهريج',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('بدون ربط حالياً'),
                        ),
                        ...vehicleDrivers.map(
                          (driver) => DropdownMenuItem<String?>(
                            value: driver.id,
                            child: Text(
                              _vehicleOptionLabel(driver),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        linkedDriverId = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: capacityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'سعة الصهريج باللتر',
                        prefixIcon: Icon(Icons.local_gas_station_outlined),
                      ),
                      validator: (value) {
                        final capacity = int.tryParse(value?.trim() ?? '');
                        if (capacity == null || capacity <= 0) {
                          return 'أدخل سعة صحيحة باللتر';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _statuses.contains(status) ? status : 'فاضي',
                      decoration: const InputDecoration(
                        labelText: 'الحالة',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: _statuses
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        status = value ?? 'فاضي';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      final capacityLiters = int.parse(
                        capacityController.text.trim(),
                      );
                      final linkedDriver = _findDriverById(
                        vehicleDrivers,
                        linkedDriverId,
                      );

                      final payload = Tanker(
                        id: tanker?.id ?? '',
                        number: numberController.text.trim(),
                        status: status,
                        capacityLiters: capacityLiters,
                        linkedDriverId: linkedDriverId,
                        linkedDriverName: linkedDriver?.name,
                        linkedVehicleNumber: linkedDriver?.vehicleNumber,
                        linkedVehicleType: linkedDriver?.vehicleType,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        createdAt: tanker?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      final ok = tanker == null
                          ? await provider.createTanker(payload)
                          : await provider.updateTanker(tanker.id, payload);

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext, ok);
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tanker == null ? 'تمت الإضافة' : 'تم التحديث'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else if (result == false && mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'حدث خطأ'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Tanker tanker) async {
    final provider = context.read<TankerProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('حذف الصهريج'),
          content: Text('هل أنت متأكد من حذف الصهريج ${tanker.number}؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    final success = await provider.deleteTanker(tanker.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'تم الحذف' : (provider.error ?? 'فشل الحذف')),
        backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TankerProvider>(
      builder: (context, provider, _) {
        final allTankers = provider.tankers;
        final items = _applySearch(allTankers);
        final availableCount = allTankers.where((t) => t.status == 'فاضي').length;
        final busyCount = allTankers.where((t) => t.status == 'في طلب').length;
        final maintenanceCount = allTankers
            .where((t) => t.status == 'تحت الصيانة')
            .length;

        return RefreshIndicator(
          onRefresh: provider.fetchTankers,
          child: TrackingPageShell(
            icon: Icons.local_shipping_rounded,
            title: 'متابعة الصهاريج',
            subtitle:
                'مراجعة الصهاريج، حالتها التشغيلية، ربطها بالسيارات، وإدارة السعات والملاحظات من شاشة واحدة.',
            metrics: [
              TrackingMetric(
                label: 'إجمالي الصهاريج',
                value: '${allTankers.length}',
                icon: Icons.local_shipping_outlined,
                color: AppColors.primaryBlue,
                helper: 'كل الصهاريج المسجلة في النظام',
              ),
              TrackingMetric(
                label: 'متاحة حالياً',
                value: '$availableCount',
                icon: Icons.check_circle_rounded,
                color: AppColors.successGreen,
                helper: 'جاهزة للاستلام أو الإسناد',
              ),
              TrackingMetric(
                label: 'في طلب',
                value: '$busyCount',
                icon: Icons.assignment_rounded,
                color: AppColors.statusGold,
                helper: 'مرتبطة بطلبات نشطة',
              ),
              TrackingMetric(
                label: 'تحت الصيانة',
                value: '$maintenanceCount',
                icon: Icons.build_circle_outlined,
                color: AppColors.pendingYellow,
                helper: 'بحاجة متابعة أو إصلاح',
              ),
            ],
            headerActions: _buildHeaderActions(provider),
            toolbar: _buildToolbar(items.length),
            child: _buildContent(provider, items),
          ),
        );
      },
    );
  }

  Widget _buildHeaderActions(TankerProvider provider) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: provider.isLoading ? null : provider.fetchTankers,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تحديث'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: provider.isLoading ? null : () => _showTankerForm(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة صهريج'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: BorderSide(
              color: AppColors.primaryBlue.withValues(alpha: 0.18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(int resultCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 860;
        final chips = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            TrackingStatusBadge(
              label: '$resultCount نتيجة',
              color: AppColors.infoBlue,
              icon: Icons.filter_alt_rounded,
            ),
            const TrackingStatusBadge(
              label: 'فلترة حسب الرقم أو السيارة',
              color: AppColors.secondaryTeal,
              icon: Icons.tune_rounded,
            ),
          ],
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: TrackingSearchField(
                  controller: _searchController,
                  hintText: 'ابحث برقم الصهريج أو السيارة أو السعة أو الملاحظات...',
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              chips,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrackingSearchField(
              controller: _searchController,
              hintText: 'ابحث برقم الصهريج أو السيارة أو السعة أو الملاحظات...',
              onChanged: (_) => setState(() {}),
              onClear: () {
                _searchController.clear();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            chips,
          ],
        );
      },
    );
  }

  Widget _buildContent(TankerProvider provider, List<Tanker> items) {
    if (provider.isLoading && provider.tankers.isEmpty) {
      return const TrackingStateCard(
        icon: Icons.local_shipping_outlined,
        title: 'جاري تحميل الصهاريج',
        message: 'يتم الآن جلب الصهاريج والحالات التشغيلية الحالية.',
        color: AppColors.infoBlue,
        action: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      );
    }

    if (provider.error != null && provider.tankers.isEmpty) {
      return TrackingStateCard(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل الصهاريج',
        message: provider.error ?? 'حدث خطأ أثناء جلب الصهاريج.',
        color: AppColors.errorRed,
        action: FilledButton.icon(
          onPressed: provider.fetchTankers,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      );
    }

    if (items.isEmpty) {
      return TrackingStateCard(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج حالياً',
        message: _searchController.text.trim().isEmpty
            ? 'لا توجد صهاريج مسجلة في النظام حالياً.'
            : 'لا توجد صهاريج مطابقة لنص البحث الحالي.',
        color: AppColors.primaryBlue,
        action: _searchController.text.trim().isEmpty
            ? FilledButton.icon(
                onPressed: () => _showTankerForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة صهريج'),
              )
            : OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text('مسح البحث'),
              ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1320 ? 3 : (width >= 860 ? 2 : 1);
        final cardWidth = columns == 1
            ? width
            : (width - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: items
              .map(
                (tanker) => SizedBox(
                  width: cardWidth,
                  child: _buildTankerCard(provider, tanker),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildTankerCard(TankerProvider provider, Tanker tanker) {
    final color = _statusColor(tanker.status);
    final vehicleText = _vehicleLabel(tanker);
    final notesText = tanker.notes?.trim().isNotEmpty == true
        ? tanker.notes!.trim()
        : 'بدون ملاحظات';

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      color: Colors.white.withValues(alpha: 0.82),
      border: Border.all(color: color.withValues(alpha: 0.18)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tanker.number,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicleText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TrackingStatusBadge(
                label: tanker.status,
                color: color,
                icon: Icons.flag_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.confirmation_number_outlined, tanker.number),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.local_gas_station_outlined,
            _capacityLabel(tanker),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.directions_car_filled_outlined,
            vehicleText,
          ),
          if (tanker.linkedVehicleType?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.category_outlined,
              tanker.linkedVehicleType!.trim(),
            ),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(Icons.notes_outlined, notesText),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _showTankerForm(tanker: tanker),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.infoBlue.withValues(alpha: 0.12),
                    foregroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'حذف',
                onPressed: provider.isLoading
                    ? null
                    : () => _confirmDelete(tanker),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.errorRed.withValues(alpha: 0.10),
                  foregroundColor: AppColors.errorRed,
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
