import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';

class TrackingRouteOption {
  final String summary;
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final String startAddress;
  final String endAddress;
  final LatLng? startLocation;
  final LatLng? endLocation;

  const TrackingRouteOption({
    required this.summary,
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.startAddress,
    required this.endAddress,
    this.startLocation,
    this.endLocation,
  });
}

Future<List<TrackingRouteOption>> fetchTrackingRoutes({
  required String origin,
  required String destination,
  String mode = 'driving',
  String language = 'ar',
  bool alternatives = true,
}) async {
  final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.mapsDirections}')
      .replace(
        queryParameters: {
          'origin': origin,
          'destination': destination,
          'mode': mode,
          'language': language,
          'alternatives': alternatives.toString(),
        },
      );

  final response = await http.get(uri, headers: ApiService.headers);
  if (response.statusCode != 200) {
    throw Exception('تعذر جلب المسار');
  }

  final body = json.decode(utf8.decode(response.bodyBytes));
  final rawRoutes = body is Map<String, dynamic> ? body['routes'] : null;
  if (rawRoutes is! Iterable) {
    return const <TrackingRouteOption>[];
  }

  final routes = <TrackingRouteOption>[];
  for (final item in rawRoutes) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final encodedPolyline = map['polyline']?.toString() ?? '';
    if (encodedPolyline.isEmpty) continue;

    routes.add(
      TrackingRouteOption(
        summary: map['summary']?.toString() ?? 'مسار',
        points: decodeTrackingPolyline(encodedPolyline),
        distanceKm: ((map['distance'] as num?)?.toDouble() ?? 0) / 1000,
        durationMinutes: (((map['duration'] as num?)?.toDouble() ?? 0) / 60)
            .round(),
        startAddress: map['startAddress']?.toString() ?? '',
        endAddress: map['endAddress']?.toString() ?? '',
        startLocation: _parseLatLng(map['startLocation']),
        endLocation: _parseLatLng(map['endLocation']),
      ),
    );
  }

  return routes;
}

LatLng? _parseLatLng(dynamic value) {
  if (value is! Map) return null;
  final map = Map<String, dynamic>.from(value);
  final latitude = (map['latitude'] as num?)?.toDouble();
  final longitude = (map['longitude'] as num?)?.toDouble();
  if (latitude == null || longitude == null) return null;
  return LatLng(latitude, longitude);
}

List<LatLng> decodeTrackingPolyline(String encoded) {
  final points = <LatLng>[];
  int index = 0;
  int latitude = 0;
  int longitude = 0;

  while (index < encoded.length) {
    int shift = 0;
    int result = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    final latitudeDelta = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    latitude += latitudeDelta;

    shift = 0;
    result = 0;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    final longitudeDelta = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    longitude += longitudeDelta;

    points.add(LatLng(latitude / 1e5, longitude / 1e5));
  }

  return points;
}

String formatTrackingDuration(int? durationMinutes) {
  if (durationMinutes == null || durationMinutes <= 0) {
    return 'غير متاح';
  }

  if (durationMinutes < 60) {
    return '$durationMinutes دقيقة';
  }

  final hours = durationMinutes ~/ 60;
  final minutes = durationMinutes % 60;
  if (minutes == 0) {
    return '$hours ساعة';
  }

  return '$hours ساعة و $minutes دقيقة';
}
