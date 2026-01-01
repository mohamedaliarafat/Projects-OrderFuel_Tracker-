import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../models/driver_model.dart';

class DriverSelectionDialog extends StatefulWidget {
  final Driver? currentDriver;

  const DriverSelectionDialog({super.key, this.currentDriver});

  @override
  State<DriverSelectionDialog> createState() => _DriverSelectionDialogState();
}

class _DriverSelectionDialogState extends State<DriverSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Driver> _filteredDrivers = [];
  Driver? _selectedDriver;

  @override
  void initState() {
    super.initState();
    _selectedDriver = widget.currentDriver;
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.fetchDrivers(status: 'نشط');
    _filterDrivers('');
  }

  void _filterDrivers(String query) {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);

    if (query.isEmpty) {
      setState(() {
        _filteredDrivers = driverProvider.drivers;
      });
    } else {
      setState(() {
        _filteredDrivers = driverProvider.drivers.where((driver) {
          return driver.name.toLowerCase().contains(query.toLowerCase()) ||
              driver.licenseNumber.toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              driver.phone.toLowerCase().contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    return AlertDialog(
      title: const Text('اختر سائق'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: _filterDrivers,
              decoration: InputDecoration(
                hintText: 'ابحث عن سائق...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selected driver (if any)
            if (_selectedDriver != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDriver!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'رخصة: ${_selectedDriver!.licenseNumber}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'هاتف: ${_selectedDriver!.phone}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDriver = null;
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.red),
                    ),
                  ],
                ),
              ),

            // Drivers list
            Expanded(
              child: driverProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDrivers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد سائقين',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredDrivers.length,
                      itemBuilder: (context, index) {
                        final driver = _filteredDrivers[index];
                        final isSelected = _selectedDriver?.id == driver.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.withOpacity(0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.directions_car,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                              ),
                            ),
                            title: Text(driver.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('رخصة: ${driver.licenseNumber}'),
                                Text('هاتف: ${driver.phone}'),
                                if (driver.vehicleNumber != null)
                                  Text('مركبة: ${driver.vehicleNumber}'),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedDriver = driver;
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),

            // Add new driver button
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/driver/form').then((value) {
                    if (value != null && value is Driver) {
                      Navigator.pop(context, value);
                    }
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة سائق جديد'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
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
          onPressed: _selectedDriver != null
              ? () {
                  Navigator.pop(context, _selectedDriver);
                }
              : null,
          child: const Text('اختيار'),
        ),
      ],
    );
  }
}
