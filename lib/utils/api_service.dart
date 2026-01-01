import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _token;
  // static const String _baseUrl = 'http://192.168.8.126:6030/api';
  static const String _baseUrl = 'https://backend-ordertrack.onrender.com/api';

  static Map<String, String> get headers {
    final headers = {'Content-Type': 'application/json'};

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  static void setToken(String? token) {
    _token = token;
  }

  static Future<http.Response> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static Future<http.Response> download(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return response;
    } else if (response.statusCode == 401) {
      throw Exception('الرجاء تسجيل الدخول');
    } else {
      throw Exception(
        'Download failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  static Future<http.Response> post(String endpoint, dynamic data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<http.Response> put(String endpoint, dynamic data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  static Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  static http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}
