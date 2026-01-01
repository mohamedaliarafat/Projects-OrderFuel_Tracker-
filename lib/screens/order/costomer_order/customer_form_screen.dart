import 'package:flutter/material.dart';
import 'package:order_tracker/models/customer_model.dart';
import 'package:order_tracker/providers/customer_provider.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/custom_text_field.dart';
import 'package:order_tracker/widgets/gradient_button.dart';
import 'package:provider/provider.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customerToEdit;

  const CustomerFormScreen({super.key, this.customerToEdit});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPersonPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customerToEdit != null) {
      _initializeFormWithCustomer();
    }
  }

  void _initializeFormWithCustomer() {
    final customer = widget.customerToEdit!;
    _nameController.text = customer.name;
    _codeController.text = customer.code;
    _phoneController.text = customer.phone ?? '';
    _emailController.text = customer.email ?? '';
    _addressController.text = customer.address ?? '';
    _contactPersonController.text = customer.contactPerson ?? '';
    _contactPersonPhoneController.text = customer.contactPersonPhone ?? '';
    _notesController.text = customer.notes ?? '';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<CustomerProvider>(context, listen: false);

    final data = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      'email': _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      'address': _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      'contactPerson': _contactPersonController.text.trim().isNotEmpty
          ? _contactPersonController.text.trim()
          : null,
      'contactPersonPhone': _contactPersonPhoneController.text.trim().isNotEmpty
          ? _contactPersonPhoneController.text.trim()
          : null,
      'notes': _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    };

    if (widget.customerToEdit != null) {
      data['code'] = _codeController.text.trim();
    }

    bool success;
    if (widget.customerToEdit != null) {
      success = await provider.updateCustomer(widget.customerToEdit!.id, data);
    } else {
      success = await provider.createCustomer(data);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.customerToEdit != null
                ? 'تم تحديث بيانات العميل بنجاح'
                : 'تم إنشاء العميل بنجاح',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'حدث خطأ'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final isEditing = widget.customerToEdit != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1024;
        final bool isDesktop = width >= 1024;

        final double maxWidth = isDesktop ? 900 : double.infinity;
        final int gridCols = isDesktop ? 2 : 1;

        return Scaffold(
          appBar: AppBar(title: Text(isEditing ? 'تعديل العميل' : 'عميل جديد')),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        /// ======================
                        /// المعلومات الأساسية
                        /// ======================
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                                  labelText: 'اسم العميل *',
                                  prefixIcon: Icons.person_outline,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'اسم العميل مطلوب'
                                      : null,
                                ),

                                const SizedBox(height: 16),

                                if (isEditing) ...[
                                  CustomTextField(
                                    controller: _codeController,
                                    labelText: 'كود العميل',
                                    prefixIcon: Icons.code,
                                    enabled: false,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: gridCols,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 3.5,
                                  children: [
                                    CustomTextField(
                                      controller: _phoneController,
                                      labelText: 'رقم الهاتف',
                                      prefixIcon: Icons.phone,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    CustomTextField(
                                      controller: _emailController,
                                      labelText: 'البريد الإلكتروني',
                                      prefixIcon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// ======================
                        /// معلومات الاتصال
                        /// ======================
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'معلومات الاتصال',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 20),

                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: gridCols,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 3.5,
                                  children: [
                                    CustomTextField(
                                      controller: _contactPersonController,
                                      labelText: 'اسم الشخص المسؤول',
                                      prefixIcon: Icons.contact_page,
                                    ),
                                    CustomTextField(
                                      controller: _contactPersonPhoneController,
                                      labelText: 'هاتف الشخص المسؤول',
                                      prefixIcon: Icons.phone_android,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// ======================
                        /// العنوان والملاحظات
                        /// ======================
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'العنوان والملاحظات',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 20),

                                CustomTextField(
                                  controller: _addressController,
                                  labelText: 'العنوان',
                                  prefixIcon: Icons.location_on,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _notesController,
                                  labelText: 'ملاحظات',
                                  prefixIcon: Icons.note,
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        /// ======================
                        /// زر الحفظ
                        /// ======================
                        GradientButton(
                          onPressed: provider.isLoading ? null : _submitForm,
                          text: provider.isLoading
                              ? 'جاري الحفظ...'
                              : (isEditing ? 'تحديث العميل' : 'إنشاء العميل'),
                          gradient: AppColors.accentGradient,
                          isLoading: provider.isLoading,
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
