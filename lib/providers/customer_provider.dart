import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/customer_model.dart';
import '../utils/constants.dart';
import '../utils/api_service.dart';

class CustomerProvider with ChangeNotifier {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  List<Customer> get customers =>
      _filteredCustomers.isNotEmpty ? _filteredCustomers : _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCustomers({int page = 1, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '${ApiEndpoints.baseUrl}/customers?page=$page';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _customers = (data['customers'] as List)
            .map((e) => Customer.fromJson(e))
            .toList();
        _currentPage = data['pagination']['page'];
        _totalPages = data['pagination']['pages'];
        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('فشل في جلب العملاء');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchCustomers(String query) {
    if (query.isEmpty) {
      _filteredCustomers = _customers;
    } else {
      _filteredCustomers = _customers.where((customer) {
        return customer.name.toLowerCase().contains(query.toLowerCase()) ||
            customer.code.toLowerCase().contains(query.toLowerCase()) ||
            (customer.phone?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();
    }
    notifyListeners();
  }

  Future<bool> createCustomer(Map<String, dynamic> customerData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/customers'),
        headers: ApiService.headers,
        body: json.encode(customerData),
      );

      print(response.body);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final newCustomer = Customer.fromJson(data['customer']);
        _customers.insert(0, newCustomer);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['error'] ?? 'فشل إنشاء العميل';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالسيرفر';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(
    String id,
    Map<String, dynamic> customerData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.baseUrl}/customers/$id'),
        headers: ApiService.headers,
        body: json.encode(customerData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedCustomer = Customer.fromJson(data['customer']);

        final index = _customers.indexWhere((c) => c.id == id);
        if (index != -1) {
          _customers[index] = updatedCustomer;
        }

        if (_selectedCustomer?.id == id) {
          _selectedCustomer = updatedCustomer;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['error'] ?? 'فشل تحديث العميل';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'حدث خطأ في الاتصال بالسيرفر';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchCustomerById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/customers/$id'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _selectedCustomer = Customer.fromJson(data['customer']);
        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('فشل في جلب بيانات العميل');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Customer>> searchCustomersAutoComplete(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/customers/search?q=$query'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((e) => Customer.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelectedCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }
}
