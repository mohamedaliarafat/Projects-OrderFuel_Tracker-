import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:order_tracker/models/mo_assistant_message.dart';
import 'package:order_tracker/utils/api_service.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/utils/mo_assistant_route_guide.dart';

class MoAssistantRequestCancelled implements Exception {
  const MoAssistantRequestCancelled();

  @override
  String toString() => 'Mo request cancelled';
}

class MoAssistantService {
  http.Client? _activeClient;
  int _activeRequestId = 0;

  void cancelActiveRequest() {
    _activeRequestId++;
    _activeClient?.close();
    _activeClient = null;
  }

  Future<String> sendMessage({
    required String message,
    required List<MoAssistantMessage> history,
    String? currentRoute,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw Exception('اكتب سؤالك أولًا.');
    }

    final normalizedHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;
    final routeContext = describeMoAssistantRoute(currentRoute);
    final requestId = ++_activeRequestId;
    final client = http.Client();
    _activeClient = client;

    try {
      final response = await client.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.aiAssistantChat}'),
        headers: ApiService.headers,
        body: json.encode(<String, dynamic>{
          'message': trimmedMessage,
          'currentRoute': currentRoute,
          'screenContext': routeContext?.toJson(),
          'history': normalizedHistory
              .map((item) => item.toApiJson())
              .toList(growable: false),
        }),
      );

      if (_activeRequestId != requestId) {
        throw const MoAssistantRequestCancelled();
      }

      final dynamic decoded = response.bodyBytes.isEmpty
          ? <String, dynamic>{}
          : json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (decoded is Map<String, dynamic>) {
          final message = (decoded['error'] ?? decoded['message'] ?? '')
              .toString()
              .trim();
          if (message.isNotEmpty) {
            throw Exception(message);
          }
        }
        throw Exception('تعذر الوصول إلى Mo حاليًا.');
      }

      dynamic root = decoded;
      if (root is Map<String, dynamic> && root['data'] != null) {
        root = root['data'];
      }

      if (root is Map<String, dynamic>) {
        final reply = (root['reply'] ?? '').toString().trim();
        if (reply.isNotEmpty) {
          return reply;
        }
      }

      throw Exception('لم يصل رد صالح من Mo.');
    } catch (error) {
      if (_activeRequestId != requestId) {
        throw const MoAssistantRequestCancelled();
      }
      rethrow;
    } finally {
      if (identical(_activeClient, client)) {
        _activeClient = null;
      }
      client.close();
    }
  }
}
