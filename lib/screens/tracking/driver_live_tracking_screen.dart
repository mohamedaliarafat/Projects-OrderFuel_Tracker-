import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:order_tracker/models/driver_tracking_models.dart';
import 'package:order_tracker/providers/driver_tracking_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/utils/tracking_directions_service.dart';
import 'package:order_tracker/widgets/maps/advanced_web_map.dart';
import 'package:provider/provider.dart';

class DriverLiveTrackingScreen extends StatefulWidget {
  final String driverId;

  const DriverLiveTrackingScreen({super.key, required this.driverId});

  @override
  State<DriverLiveTrackingScreen> createState() =>
      _DriverLiveTrackingScreenState();
}

class _DriverLiveTrackingScreenState extends State<DriverLiveTrackingScreen> {
  Timer? _refreshTimer;
  List<LatLng> _routePoints = const <LatLng>[];
  double? _distanceKm;
  int? _durationMinutes;
  String? _routeError;
  bool _isRouteLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshTracking();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 12),
        (_) => _refreshTracking(silent: true),
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    context.read<DriverTrackingProvider>().clearDetail();
    super.dispose();
  }

  Future<void> _refreshTracking({bool silent = false}) async {
    final provider = context.read<DriverTrackingProvider>();
    final detail = await provider.fetchDriverDetail(
      widget.driverId,
      silent: silent,
    );
    if (detail == null) return;
    await _refreshRoute(detail);
  }

  Future<void> _refreshRoute(DriverTrackingDetail detail) async {
    final lastLocation = detail.summary.lastLocation;
    final activeOrder = detail.summary.activeOrder;
    final destinationText = activeOrder?.destinationText.trim() ?? '';

    if (lastLocation == null || destinationText.isEmpty) {
      if (!mounted) return;
      setState(() {
        _routePoints = const <LatLng>[];
        _distanceKm = null;
        _durationMinutes = null;
        _routeError = null;
        _isRouteLoading = false;
      });
      return;
    }

    setState(() {
      _isRouteLoading = true;
      _routeError = null;
    });

    try {
      final routes = await fetchTrackingRoutes(
        origin: '${lastLocation.latitude},${lastLocation.longitude}',
        destination: destinationText,
      );

      if (!mounted) return;
      if (routes.isEmpty) {
        setState(() {
          _routePoints = const <LatLng>[];
          _distanceKm = null;
          _durationMinutes = null;
          _routeError = 'لم يتم العثور على مسار حالي';
          _isRouteLoading = false;
        });
        return;
      }

      final route = routes.first;
      setState(() {
        _routePoints = route.points;
        _distanceKm = route.distanceKm;
        _durationMinutes = route.durationMinutes;
        _routeError = null;
        _isRouteLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _routeError = error.toString();
        _isRouteLoading = false;
      });
    }
  }

  Color _statusColor(DriverTrackingSummary summary) {
    if (summary.hasActiveOrder) return AppColors.statusGold;
    final status = summary.driver.status.trim();
    if (status == 'في إجازة') return AppColors.pendingYellow;
    if (status == 'مرفود' || status == 'غير نشط') return AppColors.errorRed;
    return AppColors.successGreen;
  }

  String _statusLabel(DriverTrackingSummary summary) {
    if (summary.hasActiveOrder) return 'معه طلب';
    final status = summary.driver.status.trim();
    if (status == 'في إجازة') return 'إجازة';
    if (status == 'مرفود') return 'مرفود';
    if (status == 'غير نشط') return 'غير نشط';
    return status.isEmpty ? 'فاضي' : status;
  }

  String _vehicleTrackingLabel(DriverTrackingSummary summary) {
    if (summary.hasActiveOrder) return 'في طلب';

    final vehicleStatus = summary.driver.vehicleStatus.trim();
    if (vehicleStatus == 'تحت الصيانة') {
      return 'تحت الصيانة';
    }

    return 'فاضي';
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) return 'غير متاح';
    final local = value.toLocal();
    final twoDigits = (int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  String _formatCoordinates(DriverLocationSnapshot? snapshot) {
    if (snapshot == null) return 'غير متاح';
    return '${snapshot.latitude.toStringAsFixed(5)}, ${snapshot.longitude.toStringAsFixed(5)}';
  }

  LatLng _resolveCenter(DriverTrackingDetail detail) {
    final lastLocation = detail.summary.lastLocation;
    if (lastLocation != null) {
      return LatLng(lastLocation.latitude, lastLocation.longitude);
    }
    if (_routePoints.isNotEmpty) {
      return _routePoints.first;
    }
    final history = detail.history;
    if (history.isNotEmpty) {
      final point = history.last;
      return LatLng(point.latitude, point.longitude);
    }
    return const LatLng(24.7136, 46.6753);
  }

  Widget _buildMap(DriverTrackingDetail detail) {
    final summary = detail.summary;
    final currentLocation = summary.lastLocation == null
        ? null
        : LatLng(
            summary.lastLocation!.latitude,
            summary.lastLocation!.longitude,
          );
    final destinationLocation = _routePoints.isEmpty ? null : _routePoints.last;
    final polylinePoints = _routePoints.isNotEmpty
        ? _routePoints
        : detail.history
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
    final center = _resolveCenter(detail);

    final markers = <Marker>{
      if (currentLocation != null)
        Marker(
          markerId: const MarkerId('driver-current'),
          position: currentLocation,
          infoWindow: InfoWindow(title: summary.driver.name),
        ),
      if (destinationLocation != null)
        Marker(
          markerId: const MarkerId('driver-destination'),
          position: destinationLocation,
          infoWindow: const InfoWindow(title: 'وجهة الطلب'),
        ),
    };

    final polylines = <Polyline>{
      if (polylinePoints.length >= 2)
        Polyline(
          polylineId: const PolylineId('driver-route'),
          points: polylinePoints,
          width: 5,
          color: AppColors.primaryBlue,
        ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            Positioned.fill(
              child: kIsWeb
                  ? AdvancedWebMap(
                      center: center,
                      zoom: 13,
                      primaryMarker: destinationLocation ?? currentLocation,
                      secondaryMarker: destinationLocation != null
                          ? currentLocation
                          : null,
                      polyline: polylinePoints.length >= 2
                          ? polylinePoints
                          : null,
                    )
                  : GoogleMap(
                      key: ValueKey(
                        '${center.latitude}-${center.longitude}-${polylinePoints.length}',
                      ),
                      initialCameraPosition: CameraPosition(
                        target: center,
                        zoom: 13,
                      ),
                      markers: markers,
                      polylines: polylines,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
            ),
            if (_isRouteLoading)
              const Positioned(
                top: 12,
                right: 12,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverTrackingProvider>(
      builder: (context, provider, _) {
        final detail = provider.selectedDetail;

        return Scaffold(
          appBar: AppBar(
            title: const Text('التتبع الحي للسائق'),
            actions: [
              IconButton(
                tooltip: 'تحديث',
                onPressed: provider.isLoading ? null : _refreshTracking,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: provider.isLoading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      provider.error ?? 'لا توجد بيانات تتبع لهذا السائق',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshTracking,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildMap(detail),
                      const SizedBox(height: 16),
                      _DriverTrackingInfoCard(
                        title: detail.summary.driver.name,
                        color: _statusColor(detail.summary),
                        statusLabel: _statusLabel(detail.summary),
                        rows: [
                          _TrackingInfoRow(
                            label: 'الجوال',
                            value: detail.summary.driver.phone,
                          ),
                          _TrackingInfoRow(
                            label: 'المركبة',
                            value:
                                detail.summary.driver.vehicleNumber ??
                                'غير محدد',
                          ),
                          _TrackingInfoRow(
                            label: 'نوع المركبة',
                            value: detail.summary.driver.vehicleType,
                          ),
                          _TrackingInfoRow(
                            label: 'حالة السيارة',
                            value: _vehicleTrackingLabel(detail.summary),
                          ),
                          _TrackingInfoRow(
                            label: 'آخر تحديث',
                            value: _formatTimestamp(
                              detail.summary.lastLocation?.timestamp,
                            ),
                          ),
                          _TrackingInfoRow(
                            label: 'الإحداثيات',
                            value: _formatCoordinates(
                              detail.summary.lastLocation,
                            ),
                          ),
                        ],
                      ),
                      if (detail.summary.activeOrder != null) ...[
                        const SizedBox(height: 12),
                        _DriverTrackingInfoCard(
                          title: 'الطلب الحالي',
                          color: AppColors.statusGold,
                          statusLabel: detail.summary.activeOrder!.status,
                          rows: [
                            _TrackingInfoRow(
                              label: 'رقم الطلب',
                              value: detail.summary.activeOrder!.orderNumber,
                            ),
                            _TrackingInfoRow(
                              label: 'الوجهة',
                              value:
                                  detail
                                      .summary
                                      .activeOrder!
                                      .destinationText
                                      .isEmpty
                                  ? 'غير محددة'
                                  : detail.summary.activeOrder!.destinationText,
                            ),
                            _TrackingInfoRow(
                              label: 'المسافة المتبقية',
                              value: _distanceKm == null
                                  ? 'غير متاحة'
                                  : '${_distanceKm!.toStringAsFixed(1)} كم',
                            ),
                            _TrackingInfoRow(
                              label: 'الوقت المتوقع',
                              value: formatTrackingDuration(_durationMinutes),
                            ),
                          ],
                        ),
                      ],
                      if (_routeError != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          color: AppColors.errorRed.withValues(alpha: 0.08),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              _routeError!,
                              style: const TextStyle(color: AppColors.errorRed),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'آخر نقاط الحركة',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 12),
                              if (detail.history.isEmpty)
                                const Text('لا يوجد مسار محفوظ حتى الآن')
                              else
                                ...detail.history.reversed
                                    .take(6)
                                    .map(
                                      (point) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.place_outlined,
                                              color: AppColors.primaryBlue,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                '${point.latitude.toStringAsFixed(5)}, '
                                                '${point.longitude.toStringAsFixed(5)}',
                                              ),
                                            ),
                                            Text(
                                              _formatTimestamp(point.timestamp),
                                              style: const TextStyle(
                                                color: AppColors.mediumGray,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _DriverTrackingInfoCard extends StatelessWidget {
  final String title;
  final String statusLabel;
  final Color color;
  final List<_TrackingInfoRow> rows;

  const _DriverTrackingInfoCard({
    required this.title,
    required this.statusLabel,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          color: AppColors.mediumGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Text(row.value)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingInfoRow {
  final String label;
  final String value;

  const _TrackingInfoRow({required this.label, required this.value});
}
