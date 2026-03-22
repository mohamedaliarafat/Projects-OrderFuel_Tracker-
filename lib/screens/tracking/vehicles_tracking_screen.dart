import 'dart:async';

import 'package:flutter/material.dart';
import 'package:order_tracker/models/driver_tracking_models.dart';
import 'package:order_tracker/providers/driver_tracking_provider.dart';
import 'package:order_tracker/screens/tracking/driver_live_tracking_screen.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/app_surface_card.dart';
import 'package:order_tracker/widgets/tracking/tracking_page_shell.dart';
import 'package:provider/provider.dart';

class VehiclesTrackingScreen extends StatefulWidget {
  const VehiclesTrackingScreen({super.key});

  @override
  State<VehiclesTrackingScreen> createState() => _VehiclesTrackingScreenState();
}

class _VehiclesTrackingScreenState extends State<VehiclesTrackingScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverTrackingProvider>().fetchTrackingDrivers();
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => context.read<DriverTrackingProvider>().fetchTrackingDrivers(
        silent: true,
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _vehicleUnderMaintenance(DriverTrackingSummary summary) {
    return summary.driver.vehicleStatus.trim() == 'تحت الصيانة';
  }

  Color _vehicleColor(DriverTrackingSummary summary) {
    if (summary.hasActiveOrder) return AppColors.statusGold;
    if (_vehicleUnderMaintenance(summary)) return AppColors.pendingYellow;
    return AppColors.successGreen;
  }

  String _vehicleLabel(DriverTrackingSummary summary) {
    if (summary.hasActiveOrder) return 'في طلب';
    if (_vehicleUnderMaintenance(summary)) return 'تحت الصيانة';
    return 'فاضي';
  }

  List<DriverTrackingSummary> _applySearch(List<DriverTrackingSummary> items) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((summary) {
      final driver = summary.driver;
      return driver.name.toLowerCase().contains(query) ||
          driver.licenseNumber.toLowerCase().contains(query) ||
          driver.phone.toLowerCase().contains(query) ||
          (driver.vehicleNumber ?? '').toLowerCase().contains(query) ||
          driver.vehicleType.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openVehicleForm([Object? arguments]) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.driverForm,
      arguments: arguments,
    );
    if (!mounted) return;
    await context.read<DriverTrackingProvider>().fetchTrackingDrivers();
  }

  Future<void> _openLiveTracking(DriverTrackingSummary summary) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DriverLiveTrackingScreen(driverId: summary.driver.id),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.year}/${_twoDigits(local.month)}/${_twoDigits(local.day)} ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverTrackingProvider>(
      builder: (context, provider, _) {
        final allItems = provider.drivers;
        final items = _applySearch(allItems);
        final activeOrders = allItems
            .where((item) => item.hasActiveOrder)
            .length;
        final availableVehicles = allItems
            .where(
              (item) => !item.hasActiveOrder && !_vehicleUnderMaintenance(item),
            )
            .length;
        final trackedItems = allItems
            .where((item) => item.lastLocation != null)
            .length;

        return RefreshIndicator(
          onRefresh: () => provider.fetchTrackingDrivers(silent: true),
          child: TrackingPageShell(
            icon: Icons.directions_car_filled_rounded,
            title: 'متابعة السيارات',
            subtitle:
                'مراجعة سيارات السائقين، الحالات التشغيلية، وآخر مواقع التتبع من واجهة واحدة.',
            metrics: [
              TrackingMetric(
                label: 'إجمالي السيارات',
                value: '${allItems.length}',
                icon: Icons.directions_car_rounded,
                color: AppColors.infoBlue,
                helper: 'كل المركبات المرتبطة بالسائقين',
              ),
              TrackingMetric(
                label: 'السيارات المتاحة',
                value: '$availableVehicles',
                icon: Icons.check_circle_rounded,
                color: AppColors.successGreen,
                helper: 'سيارات فارغة وجاهزة للتكليف',
              ),
              TrackingMetric(
                label: 'طلبات بالمستودع',
                value: '$activeOrders',
                icon: Icons.local_shipping_rounded,
                color: AppColors.statusGold,
                helper: 'سيارات مرتبطة بطلبات حالتها في المستودع فقط',
              ),
              TrackingMetric(
                label: 'تتبع مباشر',
                value: '$trackedItems',
                icon: Icons.gps_fixed_rounded,
                color: AppColors.secondaryTeal,
                helper: 'وصلت لها إحداثيات حديثة',
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

  Widget _buildHeaderActions(DriverTrackingProvider provider) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: provider.isLoading
              ? null
              : () => provider.fetchTrackingDrivers(silent: true),
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
          onPressed: () => _openVehicleForm(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة سيارة'),
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
        final infoChips = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            TrackingStatusBadge(
              label: '$resultCount نتيجة',
              color: AppColors.infoBlue,
              icon: Icons.filter_alt_rounded,
            ),
            const TrackingStatusBadge(
              label: 'تحديث تلقائي كل 12 ثانية',
              color: AppColors.secondaryTeal,
              icon: Icons.schedule_rounded,
            ),
          ],
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: TrackingSearchField(
                  controller: _searchController,
                  hintText: 'ابحث برقم السيارة أو اسم السائق أو نوع المركبة...',
                  onChanged: (_) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              infoChips,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrackingSearchField(
              controller: _searchController,
              hintText: 'ابحث برقم السيارة أو اسم السائق أو نوع المركبة...',
              onChanged: (_) => setState(() {}),
              onClear: () {
                _searchController.clear();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            infoChips,
          ],
        );
      },
    );
  }

  Widget _buildContent(
    DriverTrackingProvider provider,
    List<DriverTrackingSummary> items,
  ) {
    if (provider.isLoading && provider.drivers.isEmpty) {
      return const TrackingStateCard(
        icon: Icons.sync_rounded,
        title: 'جاري تحميل السيارات',
        message: 'يتم الآن جلب بيانات التتبع والحالات الحالية للمركبات.',
        color: AppColors.infoBlue,
        action: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      );
    }

    if (provider.error != null && provider.drivers.isEmpty) {
      return TrackingStateCard(
        icon: Icons.error_outline_rounded,
        title: 'تعذر تحميل السيارات',
        message: provider.error ?? 'حدث خطأ غير متوقع أثناء جلب البيانات.',
        color: AppColors.errorRed,
        action: FilledButton.icon(
          onPressed: () => provider.fetchTrackingDrivers(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      );
    }

    if (items.isEmpty) {
      return TrackingStateCard(
        icon: Icons.directions_car_outlined,
        title: 'لا توجد سيارات مطابقة',
        message: _searchController.text.trim().isEmpty
            ? 'لا توجد سيارات مضافة للمتابعة حالياً.'
            : 'جرّب تغيير كلمات البحث أو امسح الفلتر الحالي.',
        color: AppColors.primaryBlue,
        action: _searchController.text.trim().isEmpty
            ? FilledButton.icon(
                onPressed: () => _openVehicleForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة سيارة'),
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
                (summary) => SizedBox(
                  width: cardWidth,
                  child: _buildVehicleCard(summary),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildVehicleCard(DriverTrackingSummary summary) {
    final color = _vehicleColor(summary);
    final label = _vehicleLabel(summary);
    final driver = summary.driver;
    final orderColor = summary.hasActiveOrder
        ? AppColors.statusGold
        : AppColors.infoBlue;
    final vehicleTitle = driver.vehicleNumber?.trim().isNotEmpty == true
        ? driver.vehicleNumber!.trim()
        : 'سيارة ${driver.name}';
    final lastLocation = summary.lastLocation;
    final lastUpdate = lastLocation == null
        ? 'لا يوجد تتبع مباشر بعد'
        : 'آخر تحديث ${_formatTimestamp(lastLocation.timestamp)}';

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
                  Icons.directions_car_filled_rounded,
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
                      vehicleTitle,
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
                      '${driver.name} • ${driver.vehicleType}',
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
                label: label,
                color: color,
                icon: summary.hasActiveOrder
                    ? Icons.local_shipping_rounded
                    : Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.phone_rounded, driver.phone),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.badge_outlined,
            driver.licenseNumber.trim().isEmpty
                ? 'لا يوجد رقم رخصة'
                : 'الرخصة ${driver.licenseNumber}',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.access_time_rounded, lastUpdate),
          if (summary.activeOrder != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: orderColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: orderColor.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${summary.hasActiveOrder ? 'طلب بالمستودع' : 'الطلب الحالي'} ${summary.activeOrder!.orderNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: summary.hasActiveOrder
                          ? const Color(0xFF7C5A03)
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.activeOrder!.status,
                    style: TextStyle(
                      color: summary.hasActiveOrder
                          ? const Color(0xFF92400E)
                          : const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (summary.activeOrder!.destinationText
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      summary.activeOrder!.destinationText,
                      style: TextStyle(
                        color: summary.hasActiveOrder
                            ? const Color(0xFF92400E)
                            : const Color(0xFF1E40AF),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _openLiveTracking(summary),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('فتح التتبع'),
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
                tooltip: 'تعديل السيارة',
                onPressed: () => _openVehicleForm(driver),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue.withValues(
                    alpha: 0.10,
                  ),
                  foregroundColor: AppColors.primaryBlue,
                ),
                icon: const Icon(Icons.edit_outlined),
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
