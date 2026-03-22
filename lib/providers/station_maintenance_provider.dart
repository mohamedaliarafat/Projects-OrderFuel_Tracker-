import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/station_maintenance_models.dart';
import 'package:order_tracker/services/firebase_storage_service.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';

class StationMaintenanceProvider with ChangeNotifier {
  final List<StationMaintenanceRequest> _requests = [];
  StationMaintenanceRequest? _selectedRequest;
  bool _isLoading = false;
  String? _error;

  List<StationMaintenanceRequest> get requests => List.unmodifiable(_requests);
  StationMaintenanceRequest? get selectedRequest => _selectedRequest;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool _isTechnicianRole(String role) {
    return role.trim().toLowerCase() == 'maintenance_station';
  }

  Future<List<User>> fetchTechnicians({String? search}) async {
    try {
      final query = StringBuffer('/users?limit=200&role=maintenance_station');
      if (search != null && search.trim().isNotEmpty) {
        query.write('&search=${Uri.encodeQueryComponent(search.trim())}');
      }

      final response = await ApiService.get(query.toString());
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const FormatException('Unexpected users response');
      }

      final data = Map<String, dynamic>.from(decoded);
      final rawUsers = _extractUsersList(data);
      final technicians = <User>[];

      for (final rawUser in rawUsers) {
        if (rawUser is! Map) continue;
        try {
          final user = User.fromJson(Map<String, dynamic>.from(rawUser));
          if (user.id.trim().isNotEmpty && _isTechnicianRole(user.role)) {
            technicians.add(user);
          }
        } catch (e, s) {
          debugPrint(
            'Skipping invalid technician record in station maintenance: $e',
          );
          debugPrintStack(stackTrace: s);
        }
      }

      return technicians;
    } catch (e, s) {
      debugPrint('StationMaintenanceProvider.fetchTechnicians failed: $e');
      debugPrintStack(stackTrace: s);
      throw Exception(_readableTechnicianError(e));
    }
  }

  Future<void> fetchRequests({
    String? stationId,
    String? status,
    String? type,
    String? technicianId,
    String? entryType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final params = <String, String>{};
      if (stationId != null && stationId.trim().isNotEmpty) {
        params['stationId'] = stationId.trim();
      }
      if (status != null && status.trim().isNotEmpty) {
        params['status'] = status.trim();
      }
      if (type != null && type.trim().isNotEmpty) {
        params['type'] = type.trim();
      }
      if (technicianId != null && technicianId.trim().isNotEmpty) {
        params['technicianId'] = technicianId.trim();
      }
      if (entryType != null && entryType.trim().isNotEmpty) {
        params['entryType'] = entryType.trim();
      }

      final query = params.isNotEmpty
          ? '?${Uri(queryParameters: params).query}'
          : '';

      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.stationMaintenance}$query',
        ),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        final raw = body['data'] as List<dynamic>? ?? [];
        _requests
          ..clear()
          ..addAll(
            raw.map(
              (item) => StationMaintenanceRequest.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            ),
          );
      } else {
        throw Exception('Failed to load requests');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StationMaintenanceRequest?> fetchRequestById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.stationMaintenanceById(id)}',
        ),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        final request = StationMaintenanceRequest.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
        _selectedRequest = request;
        _upsertRequest(request);
        return request;
      }
      throw Exception('Request not found');
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StationMaintenanceRequest?> fetchMyActiveRequest() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.stationMaintenanceMyActive}',
        ),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        final data = body['data'];
        if (data == null) {
          return null;
        }
        final request = StationMaintenanceRequest.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        _upsertRequest(request);
        return request;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StationMaintenanceRequest?> createRequest({
    required String type,
    required String stationName,
    required String title,
    required String description,
    required String technicianId,
    String? stationAddress,
    double? stationLat,
    double? stationLng,
    String? googleMapsUrl,
    String? technicianName,
    String? stationId,
    bool? needsMaintenance,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'type': type,
        'stationName': stationName.trim(),
        'title': title.trim(),
        'description': description.trim(),
        'technicianId': technicianId,
        'entryType': 'manager_request',
      };
      if (needsMaintenance != null) {
        payload['needsMaintenance'] = needsMaintenance;
      }
      if (stationAddress != null && stationAddress.trim().isNotEmpty) {
        payload['stationAddress'] = stationAddress.trim();
      }
      if (stationLat != null) {
        payload['stationLat'] = stationLat;
      }
      if (stationLng != null) {
        payload['stationLng'] = stationLng;
      }
      if (googleMapsUrl != null && googleMapsUrl.trim().isNotEmpty) {
        payload['googleMapsUrl'] = googleMapsUrl.trim();
      }
      if (technicianName != null && technicianName.trim().isNotEmpty) {
        payload['technicianName'] = technicianName.trim();
      }
      if (stationId != null && stationId.trim().isNotEmpty) {
        payload['stationId'] = stationId.trim();
      }

      final response = await ApiService.post(
        ApiEndpoints.stationMaintenance,
        payload,
      );
      final body = json.decode(utf8.decode(response.bodyBytes));
      final request = StationMaintenanceRequest.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
      _upsertRequest(request);
      return request;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StationMaintenanceRequest?> createTechnicianReport({
    required String stationName,
    required String title,
    required String description,
    required bool needsMaintenance,
    List<XFile> photoFiles = const [],
    List<XFile> videoFiles = const [],
    String? technicianNotes,
    String? stationAddress,
    double? stationLat,
    double? stationLng,
    String? googleMapsUrl,
    String? stationId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uploadKey =
          'technician-report-${DateTime.now().millisecondsSinceEpoch}';
      final photoAttachments = await _uploadStationMaintenanceMedia(
        requestId: uploadKey,
        section: 'report-photos',
        files: photoFiles,
      );
      final videoAttachments = await _uploadStationMaintenanceMedia(
        requestId: uploadKey,
        section: 'report-videos',
        files: videoFiles,
      );

      final payload = <String, dynamic>{
        'entryType': 'technician_report',
        'type': needsMaintenance ? 'maintenance' : 'other',
        'needsMaintenance': needsMaintenance,
        'stationName': stationName.trim(),
        'title': title.trim(),
        'description': description.trim(),
        'technicianNotes': technicianNotes?.trim() ?? '',
        'photoAttachments': photoAttachments,
        'videoAttachments': videoAttachments,
      };
      if (stationAddress != null && stationAddress.trim().isNotEmpty) {
        payload['stationAddress'] = stationAddress.trim();
      }
      if (stationLat != null) {
        payload['stationLat'] = stationLat;
      }
      if (stationLng != null) {
        payload['stationLng'] = stationLng;
      }
      if (googleMapsUrl != null && googleMapsUrl.trim().isNotEmpty) {
        payload['googleMapsUrl'] = googleMapsUrl.trim();
      }
      if (stationId != null && stationId.trim().isNotEmpty) {
        payload['stationId'] = stationId.trim();
      }

      final response = await ApiService.post(
        ApiEndpoints.stationMaintenance,
        payload,
      );
      final body = json.decode(utf8.decode(response.bodyBytes));
      final request = StationMaintenanceRequest.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
      _upsertRequest(request);
      return request;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StationMaintenanceRequest?> startRequest(String id) async {
    try {
      final response = await ApiService.patch(
        ApiEndpoints.stationMaintenanceStart(id),
        {},
      );
      final body = json.decode(utf8.decode(response.bodyBytes));
      final request = StationMaintenanceRequest.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
      _upsertRequest(request);
      return request;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<StationMaintenanceRequest?> submitRequest({
    required String id,
    required String technicianNotes,
    required List<XFile> beforeImages,
    required List<XFile> afterImages,
    required List<XFile> videos,
    required List<PlatformFile> invoiceFiles,
    required List<Map<String, dynamic>> invoices,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final beforePhotoAttachments = await _uploadStationMaintenanceMedia(
        requestId: id,
        section: 'before-photos',
        files: beforeImages,
      );
      final afterPhotoAttachments = await _uploadStationMaintenanceMedia(
        requestId: id,
        section: 'after-photos',
        files: afterImages,
      );
      final videoAttachments = await _uploadStationMaintenanceMedia(
        requestId: id,
        section: 'videos',
        files: videos,
      );

      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.stationMaintenanceSubmit(id)}',
        ),
      );

      final authHeader = ApiService.headers['Authorization'];
      if (authHeader != null && authHeader.isNotEmpty) {
        request.headers['Authorization'] = authHeader;
      }

      request.fields['technicianNotes'] = technicianNotes.trim();
      request.fields['invoices'] = json.encode(invoices);
      request.fields['beforePhotoAttachments'] = json.encode(
        beforePhotoAttachments,
      );
      request.fields['afterPhotoAttachments'] = json.encode(
        afterPhotoAttachments,
      );
      request.fields['videoAttachments'] = json.encode(videoAttachments);
      for (final file in invoiceFiles) {
        await _addPlatformFile(request, file, 'invoiceFiles');
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        final updated = StationMaintenanceRequest.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
        _upsertRequest(updated);
        return updated;
      }

      throw Exception('Failed to submit request');
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<StationMaintenanceRequest?> reviewRequest({
    required String id,
    required String decision,
    String? notes,
    double? ratingScore,
    String? ratingNote,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'decision': decision,
        'notes': notes?.trim() ?? '',
      };
      if (ratingScore != null && ratingScore > 0) {
        payload['rating'] = {
          'score': ratingScore,
          'note': ratingNote?.trim() ?? '',
        };
      }

      final response = await ApiService.patch(
        ApiEndpoints.stationMaintenanceReview(id),
        payload,
      );
      final body = json.decode(utf8.decode(response.bodyBytes));
      final updated = StationMaintenanceRequest.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
      _upsertRequest(updated);
      return updated;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _upsertRequest(StationMaintenanceRequest request) {
    final index = _requests.indexWhere((r) => r.id == request.id);
    if (index == -1) {
      _requests.insert(0, request);
    } else {
      _requests[index] = request;
    }
  }

  Future<List<Map<String, dynamic>>> _uploadStationMaintenanceMedia({
    required String requestId,
    required String section,
    required List<XFile> files,
  }) async {
    final attachments = <Map<String, dynamic>>[];
    for (final file in files) {
      attachments.add(
        await FirebaseStorageService.uploadStationMaintenanceMedia(
          requestId: requestId,
          section: section,
          file: file,
        ),
      );
    }
    return attachments;
  }

  Future<void> _addPlatformFile(
    http.MultipartRequest request,
    PlatformFile file,
    String fieldName,
  ) async {
    if (kIsWeb) {
      if (file.bytes == null) return;
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          file.bytes!,
          filename: file.name,
        ),
      );
    } else {
      final path = file.path;
      if (path == null || path.isEmpty) return;
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, path, filename: file.name),
      );
    }
  }

  List<dynamic> _extractUsersList(Map<String, dynamic> data) {
    final directUsers = data['users'];
    if (directUsers is List<dynamic>) {
      return directUsers;
    }

    final nestedData = data['data'];
    if (nestedData is List<dynamic>) {
      return nestedData;
    }

    if (nestedData is Map) {
      final nestedUsers = nestedData['users'];
      if (nestedUsers is List<dynamic>) {
        return nestedUsers;
      }
    }

    return const <dynamic>[];
  }

  String _readableTechnicianError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.contains('Auth token not initialized')) {
      return 'جلسة الدخول غير مهيأة. أعد تسجيل الدخول ثم حاول مرة أخرى.';
    }

    if (message.startsWith('API Error:')) {
      return 'فشل تحميل الفنيين من الخادم ($message).';
    }

    if (message.startsWith('FormatException')) {
      return 'استجابة الخادم غير صالحة أثناء تحميل الفنيين.';
    }

    if (message.startsWith("Instance of 'minified:")) {
      return 'حدث خطأ غير واضح أثناء قراءة بيانات الفنيين في المتصفح.';
    }

    if (message.isEmpty) {
      return 'حدث خطأ غير متوقع أثناء تحميل الفنيين.';
    }

    return message;
  }
}
