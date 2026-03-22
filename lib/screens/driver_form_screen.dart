import 'dart:async';

import 'package:flutter/material.dart';
import 'package:order_tracker/models/driver_model.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/utils/driver_user_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/driver_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';

class DriverFormScreen extends StatefulWidget {
  final Driver? driverToEdit;

  const DriverFormScreen({super.key, this.driverToEdit});

  @override
  State<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _driverUsernameController =
      TextEditingController();
  final TextEditingController _driverPasswordController =
      TextEditingController();

  Driver? _driverToEdit;
  User? _linkedDriverUser;
  bool _didLoadArgs = false;
  bool _isLoadingLinkedUser = false;

  String _vehicleType = 'شاحنة كبيرة';
  String _vehicleStatus = 'فاضي';
  String _status = 'نشط';
  DateTime? _licenseExpiryDate;

  final List<String> _vehicleTypes = [
    'سيارة صغيرة',
    'شاحنة صغيرة',
    'شاحنة كبيرة',
    'تانكر',
    'أخرى',
  ];

  final List<String> _statuses = [
    'نشط',
    'غير نشط',
    'في إجازة',
    'مرفود',
    'معلق',
  ];

  final List<String> _vehicleStatuses = [
    'فاضي',
    'في طلب',
    'تحت الصيانة',
  ];

  @override
  void initState() {
    super.initState();
    _driverToEdit = widget.driverToEdit;
    if (_driverToEdit != null) {
      _initializeFormWithDriver(_driverToEdit!);
    }
    _setSuggestedDriverUsername(force: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadLinkedDriverUser());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArgs) return;
    _didLoadArgs = true;

    if (_driverToEdit != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Driver) {
      _driverToEdit = args;
      _initializeFormWithDriver(args);
      _setSuggestedDriverUsername(force: true);
      unawaited(_loadLinkedDriverUser());
    }
  }

  void _initializeFormWithDriver(Driver driver) {
    _nameController.text = driver.name;
    _licenseNumberController.text = driver.licenseNumber;
    _phoneController.text = driver.phone;
    _emailController.text = driver.email ?? '';
    _addressController.text = driver.address ?? '';
    _vehicleNumberController.text = driver.vehicleNumber ?? '';
    _notesController.text = driver.notes ?? '';

    _vehicleType = driver.vehicleType;
    _vehicleStatus = driver.vehicleStatus;
    _status = driver.status;
    _licenseExpiryDate = driver.licenseExpiryDate;
  }

  Future<void> _loadLinkedDriverUser() async {
    final driverId = _driverToEdit?.id;
    if (driverId == null || driverId.isEmpty) {
      _setSuggestedDriverUsername(force: true);
      return;
    }

    setState(() {
      _isLoadingLinkedUser = true;
    });

    try {
      final linkedUser = await findDriverUserByDriverId(driverId);
      if (!mounted) return;

      setState(() {
        _linkedDriverUser = linkedUser;
        if (linkedUser != null && linkedUser.username.trim().isNotEmpty) {
          _driverUsernameController.text = linkedUser.username.trim();
        }
        final linkedEmail = linkedUser?.email.trim() ?? '';
        if (linkedEmail.isNotEmpty &&
            (_emailController.text.trim().isEmpty ||
                _isLegacyGeneratedDriverEmail(_emailController.text))) {
          _emailController.text = linkedEmail;
        }
        if (linkedUser == null) {
          _setSuggestedDriverUsername(force: true);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setSuggestedDriverUsername(force: true);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLinkedUser = false;
        });
      }
    }
  }

  void _setSuggestedDriverUsername({bool force = false}) {
    if (!force && _driverUsernameController.text.trim().isNotEmpty) {
      return;
    }

    _driverUsernameController.text = suggestedDriverTruckUsername(
      vehicleNumber: _vehicleNumberController.text,
      licenseNumber: _licenseNumberController.text,
      phone: _phoneController.text,
    );
  }

  bool _isLegacyGeneratedDriverEmail(String value) {
    return value.trim().toLowerCase().endsWith('@driver-truck.local');
  }

  String? _validateDriverAccountEmail(String? value) {
    final rawValue = (value ?? '').trim();
    if (rawValue.isEmpty) {
      return 'بريد حساب السائق مطلوب';
    }
    if (_isLegacyGeneratedDriverEmail(rawValue)) {
      return 'أدخل بريدًا حقيقيًا ليستقبل السائق رمز التحقق';
    }
    if (!isValidDriverAccountEmail(rawValue)) {
      return 'أدخل بريدًا إلكترونيًا صالحًا';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenseNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _vehicleNumberController.dispose();
    _notesController.dispose();
    _driverUsernameController.dispose();
    _driverPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _licenseExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _licenseExpiryDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final wasEditing = _driverToEdit != null;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final normalizedUsername = normalizeDriverTruckUsername(
      _driverUsernameController.text,
    );
    final password = _driverPasswordController.text.trim();
    final accountEmail = normalizeDriverAccountEmail(_emailController.text);
    final company = authProvider.user?.company.trim() ?? '';

    if (company.isEmpty) {
      _showErrorSnack('تعذر تحديد الشركة الحالية لإنشاء حساب السائق');
      return;
    }

    if (_isLegacyGeneratedDriverEmail(accountEmail) ||
        !isValidDriverAccountEmail(accountEmail)) {
      _showErrorSnack('أدخل بريدًا إلكترونيًا صالحًا لاستقبال رمز التحقق');
      return;
    }

    if (_linkedDriverUser == null && password.isEmpty) {
      _showErrorSnack('كلمة مرور حساب السائق مطلوبة عند إنشاء الحساب لأول مرة');
      return;
    }

    final driverData = {
      'name': _nameController.text.trim(),
      'licenseNumber': _licenseNumberController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': accountEmail,
      'address': _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      'vehicleType': _vehicleType,
      'vehicleStatus': _vehicleStatus,
      'vehicleNumber': _vehicleNumberController.text.trim().isNotEmpty
          ? _vehicleNumberController.text.trim()
          : null,
      'licenseExpiryDate': _licenseExpiryDate?.toIso8601String(),
      'status': _status,
      'notes': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    };

    bool success;
    if (wasEditing) {
      success = await driverProvider.updateDriver(
        _driverToEdit!.id,
        driverData,
      );
    } else {
      success = await driverProvider.createDriver(driverData);
    }

    if (!success) {
      _showErrorSnack(driverProvider.error ?? 'حدث خطأ أثناء حفظ السائق');
      return;
    }

    final savedDriver = driverProvider.selectedDriver;
    if (savedDriver == null || savedDriver.id.isEmpty) {
      _showErrorSnack('تم حفظ السائق لكن تعذر قراءة البيانات المحدثة');
      return;
    }

    try {
      final linkedUser = await upsertDriverUser(
        driver: savedDriver,
        username: normalizedUsername,
        email: accountEmail,
        company: company,
        existingUser: _linkedDriverUser,
        password: password.isEmpty ? null : password,
      );

      if (!mounted) return;
      setState(() {
        _driverToEdit = savedDriver;
        _linkedDriverUser = linkedUser;
        _driverUsernameController.text = linkedUser.username;
        _driverPasswordController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? 'تم تحديث السائق وربط حساب ${linkedUser.username}'
                : 'تم إنشاء السائق وحساب ${linkedUser.username}',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context, savedDriver);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _driverToEdit = savedDriver;
      });
      _showErrorSnack(
        'تم حفظ السائق لكن تعذر حفظ حساب driver_truck: $error',
      );
    }
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
      ),
    );
  }

  // تحديد إذا كان العرض واسع (ويب/كمبيوتر)
  bool get _isWideScreen {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width > 768;
  }

  // تحديد إذا كان العرض كبير جداً (شاشات واسعة)
  bool get _isExtraWideScreen {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width > 1200;
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final isEditing = _driverToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل السائق' : 'سائق جديد',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: !_isWideScreen,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _isExtraWideScreen
                  ? 1000
                  : _isWideScreen
                  ? 800
                  : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: _isWideScreen ? 24 : 16,
                vertical: 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isWideScreen)
                      _buildWideLayout()
                    else
                      _buildMobileLayout(),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: _isWideScreen ? 400 : double.infinity,
                      child: GradientButton(
                        onPressed: driverProvider.isLoading
                            ? null
                            : _submitForm,
                        text: driverProvider.isLoading
                            ? 'جاري الحفظ...'
                            : (isEditing ? 'تحديث السائق' : 'إنشاء السائق'),
                        gradient: AppColors.accentGradient,
                        isLoading: driverProvider.isLoading,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Basic Information Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المعلومات الأساسية',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _nameController,
                  labelText: 'اسم السائق *',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'اسم السائق مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _licenseNumberController,
                  labelText: 'رقم الرخصة *',
                  prefixIcon: Icons.card_membership,
                  onChanged: (_) => _setSuggestedDriverUsername(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'رقم الرخصة مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'رقم الهاتف *',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _setSuggestedDriverUsername(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'رقم الهاتف مطلوب';
                    }
                    if (!RegExp(r'^[0-9]{10,}$').hasMatch(value)) {
                      return 'رقم هاتف غير صالح';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Vehicle Information Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات المركبة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDropdownField(
                  label: 'نوع المركبة',
                  value: _vehicleType,
                  items: _vehicleTypes,
                  onChanged: (value) {
                    setState(() {
                      _vehicleType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _vehicleNumberController,
                  labelText: 'رقم المركبة',
                  prefixIcon: Icons.directions_car,
                  onChanged: (_) => _setSuggestedDriverUsername(),
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  label: 'حالة السيارة',
                  value: _vehicleStatus,
                  items: _vehicleStatuses,
                  onChanged: (value) {
                    setState(() {
                      _vehicleStatus = value ?? 'فاضي';
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDateField(
                  label: 'تاريخ انتهاء الرخصة',
                  date: _licenseExpiryDate,
                  onTap: _pickLicenseExpiryDate,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Status & Contact Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الحالة ومعلومات الاتصال',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDropdownField(
                  label: 'حالة السائق',
                  value: _status,
                  items: _statuses,
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  labelText: 'العنوان',
                  prefixIcon: Icons.location_on,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        _buildDriverUserCard(),
        const SizedBox(height: 16),

        // Notes Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _notesController,
                  labelText: 'ملاحظات إضافية',
                  prefixIcon: Icons.note,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildDriverUserCard(elevation: 4, padding: 20),
            ),
            SizedBox(
              width: cardWidth,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المعلومات الأساسية',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'اسم السائق *',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'اسم السائق مطلوب';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _licenseNumberController,
                              labelText: 'رقم الرخصة *',
                              prefixIcon: Icons.card_membership,
                              onChanged: (_) => _setSuggestedDriverUsername(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'رقم الرخصة مطلوب';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _phoneController,
                              labelText: 'رقم الهاتف *',
                              prefixIcon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              onChanged: (_) => _setSuggestedDriverUsername(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'رقم الهاتف مطلوب';
                                }
                                if (!RegExp(r'^[0-9]{10,}$').hasMatch(value)) {
                                  return 'رقم هاتف غير صالح';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات المركبة',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        label: 'نوع المركبة',
                        value: _vehicleType,
                        items: _vehicleTypes,
                        onChanged: (value) {
                          setState(() {
                            _vehicleType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _vehicleNumberController,
                        labelText: 'رقم المركبة',
                        prefixIcon: Icons.directions_car,
                        onChanged: (_) => _setSuggestedDriverUsername(),
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'حالة السيارة',
                        value: _vehicleStatus,
                        items: _vehicleStatuses,
                        onChanged: (value) {
                          setState(() {
                            _vehicleStatus = value ?? 'فاضي';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        label: 'تاريخ انتهاء الرخصة',
                        date: _licenseExpiryDate,
                        onTap: _pickLicenseExpiryDate,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحالة ومعلومات الاتصال',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        label: 'حالة السائق',
                        value: _status,
                        items: _statuses,
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _addressController,
                        labelText: 'العنوان',
                        prefixIcon: Icons.location_on,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملاحظات',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _notesController,
                        labelText: 'ملاحظات إضافية',
                        prefixIcon: Icons.note,
                        maxLines: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDriverUserCard({double elevation = 2, double padding = 16}) {
    final hasLinkedUser = _linkedDriverUser != null;
    final accountStatusColor = hasLinkedUser
        ? AppColors.successGreen
        : AppColors.pendingYellow;

    return Card(
      elevation: elevation,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'حساب السائق driver_truck',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoadingLinkedUser)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accountStatusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: accountStatusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      hasLinkedUser ? 'مرتبط' : 'ينتظر الإنشاء',
                      style: TextStyle(
                        color: accountStatusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLinkedUser
                        ? 'اسم المستخدم الحالي: ${_linkedDriverUser!.username}'
                        : 'سيتم إنشاء حساب سائق مرتبط بهذا السائق',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'هذا البريد سيستقبل رمز التحقق عند دخول السائق، والحساب يشاهد فقط الطلبات المعيّنة له.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _driverUsernameController,
              labelText: 'اسم المستخدم *',
              prefixIcon: Icons.alternate_email,
              suffixIcon: IconButton(
                tooltip: 'اقتراح جديد',
                onPressed: () => setState(
                  () => _setSuggestedDriverUsername(force: true),
                ),
                icon: const Icon(Icons.auto_fix_high_outlined),
              ),
              validator: (value) {
                final rawValue = (value ?? '').trim();
                if (rawValue.isEmpty) {
                  return 'اسم المستخدم مطلوب';
                }
                final normalized = normalizeDriverTruckUsername(value ?? '');
                if (!normalized.startsWith('driver_truck')) {
                  return 'اسم المستخدم يجب أن يبدأ بـ driver_truck';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              labelText: 'بريد حساب السائق *',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateDriverAccountEmail,
            ),
            const SizedBox(height: 8),
            Text(
              'سيصل رمز التحقق لهذا البريد عند تسجيل دخول السائق.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mediumGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _driverPasswordController,
              labelText: hasLinkedUser
                  ? 'كلمة المرور الجديدة'
                  : 'كلمة مرور الحساب *',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (!hasLinkedUser && trimmed.isEmpty) {
                  return 'كلمة المرور مطلوبة';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.mediumGray,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.mediumGray,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('yyyy/MM/dd').format(date)
                      : 'اختر التاريخ',
                  style: TextStyle(
                    color: date != null
                        ? AppColors.darkGray
                        : AppColors.mediumGray,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
