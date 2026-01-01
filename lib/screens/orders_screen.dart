import 'package:flutter/material.dart';
import 'package:order_tracker/models/order_model.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_data_grid.dart';
import '../widgets/filter_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
    });
  }

  List<Order> _applySearch(List<Order> orders) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return orders;

    return orders.where((order) {
      return order.orderNumber.contains(query) ||
          order.supplierName.contains(query) ||
          order.driverName?.contains(query) == true;
    }).toList();
  }

  Future<void> _showFilters() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const FilterDialog(),
    );

    if (result != null && mounted) {
      await Provider.of<OrderProvider>(
        context,
        listen: false,
      ).fetchOrders(filters: result);
    }
  }

  Widget _buildOrdersTab(List<Order> orders) {
    final filtered = _applySearch(orders);

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد طلبات',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return OrderDataGrid(
      dataSource: OrderDataSource(filtered),
      onRowTap: (order) {
        Navigator.pushNamed(
          context,
          AppRoutes.orderDetails,
          arguments: order.id,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor, // أو أي لون
          iconTheme: const IconThemeData(color: Colors.white), // أيقونات أبيض
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          title: const Text(AppStrings.orders),
          bottom: const TabBar(
            labelColor: Colors.white, // النص المحدد
            unselectedLabelColor: Colors.white70, // النص غير المحدد
            tabs: [
              Tab(text: 'الكل'),
              Tab(text: 'طلبات العملاء'),
              Tab(text: 'طلبات الموردين'),
              Tab(text: 'المدمجة'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _showFilters,
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.orderForm);
          },
          child: const Icon(Icons.add),
        ),

        body: Column(
          children: [
            // 🔍 البحث
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: AppStrings.search,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 📋 المحتوى
            Expanded(
              child: orderProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        // الكل
                        _buildOrdersTab(orderProvider.orders),

                        // ✅ طلبات العملاء
                        _buildOrdersTab(
                          orderProvider.orders
                              .where((o) => o.orderNumber.startsWith('CUS-'))
                              .toList(),
                        ),

                        // ✅ طلبات الموردين
                        _buildOrdersTab(
                          orderProvider.orders
                              .where((o) => o.orderNumber.startsWith('SUP-'))
                              .toList(),
                        ),

                        // ✅ الطلبات المدمجة فقط
                        _buildOrdersTab(
                          orderProvider.orders
                              .where((o) => o.orderNumber.startsWith('MIX-'))
                              .toList(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
