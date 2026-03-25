import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:order_tracker/providers/qualification_provider.dart';
import 'package:order_tracker/models/qualification_models.dart';
import 'package:order_tracker/screens/tasks/task_location_picker_screen.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/widgets/app_soft_background.dart';
import 'package:order_tracker/widgets/app_surface_card.dart';

class QualificationStationFormScreen extends StatefulWidget {
  final QualificationStation? inspectionToEdit;

  const QualificationStationFormScreen({super.key, this.inspectionToEdit});

  @override
  State<QualificationStationFormScreen> createState() =>
      _QualificationStationFormScreenState();
}

class _QualificationStationFormScreenState
    extends State<QualificationStationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  QualificationStatus _status = QualificationStatus.underReview;
  LatLng? _selectedLatLng;
  final List<PlatformFile> _newAttachments = [];
  final List<QualificationAttachment> _existingAttachments = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final inspection = widget.inspectionToEdit;
    if (inspection != null) {
      _nameController.text = inspection.name;
      _ownerNameController.text = inspection.ownerName ?? '';
      _ownerPhoneController.text = inspection.ownerPhone ?? '';
      _cityController.text = inspection.city;
      _regionController.text = inspection.region;
      _addressController.text = inspection.address;
      _notesController.text = inspection.notes ?? '';
      _status = inspection.status;
      _existingAttachments
        ..clear()
        ..addAll(inspection.attachments);
      if (inspection.location != null) {
        _selectedLatLng = LatLng(
          inspection.location.lat,
          inspection.location.lng,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _statusLabel(QualificationStatus status) {
    switch (status) {
      case QualificationStatus.underReview:
        return 'تحت الدراسة';
      case QualificationStatus.negotiating:
        return 'جاري التفاوض';
      case QualificationStatus.agreed:
        return 'تم الاتفاق';
      case QualificationStatus.notAgreed:
        return 'لم يتم الاتفاق';
    }
  }

  Color _statusColor(QualificationStatus status) {
    switch (status) {
      case QualificationStatus.underReview:
        return Colors.amber.shade700;
      case QualificationStatus.negotiating:
        return Colors.blue.shade700;
      case QualificationStatus.agreed:
        return Colors.green;
      case QualificationStatus.notAgreed:
        return Colors.red;
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<TaskLocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskLocationPickerScreen(
          initialLat: _selectedLatLng?.latitude,
          initialLng: _selectedLatLng?.longitude,
          initialAddress: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _selectedLatLng = LatLng(result.latitude, result.longitude);
      if (_addressController.text.trim().isEmpty &&
          (result.address ?? '').trim().isNotEmpty) {
        _addressController.text = result.address!.trim();
      }
      if (_cityController.text.trim().isEmpty &&
          (result.city ?? '').trim().isNotEmpty) {
        _cityController.text = result.city!.trim();
      }
      if (_regionController.text.trim().isEmpty) {
        final region = result.district?.trim().isNotEmpty == true
            ? result.district!.trim()
            : result.city?.trim() ?? '';
        if (region.isNotEmpty) {
          _regionController.text = region;
        }
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLatLng == null) {
      _showSnackBar('يرجى تحديد موقع المحطة من الخريطة');
      return;
    }

    setState(() => _saving = true);
    try {
      final provider = context.read<QualificationProvider>();
      final uploaded = await provider.uploadAttachments(_newAttachments);
      final attachments = [..._existingAttachments, ...uploaded];
      final location = QualificationLocation(
        lat: _selectedLatLng!.latitude,
        lng: _selectedLatLng!.longitude,
      );
      final payload = QualificationStation(
        id: widget.inspectionToEdit?.id ?? '',
        name: _nameController.text.trim(),
        ownerName: _ownerNameController.text.trim().isEmpty
            ? null
            : _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim().isEmpty
            ? null
            : _ownerPhoneController.text.trim(),
        city: _cityController.text.trim(),
        region: _regionController.text.trim(),
        address: _addressController.text.trim(),
        status: _status,
        createdAt: widget.inspectionToEdit?.createdAt ?? DateTime.now(),
        createdByName: widget.inspectionToEdit?.createdByName,
        location: location,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        attachments: attachments,
      );

      if (widget.inspectionToEdit == null) {
        await provider.createStation(payload);
      } else {
        await provider.updateStation(payload);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('تعذر حفظ المحطة');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
      type: FileType.custom,
      allowedExtensions: const [
        'png',
        'jpg',
        'jpeg',
        'gif',
        'webp',
        'mp4',
        'mov',
        'avi',
        'mkv',
        'webm',
      ],
    );
    if (result == null) return;
    setState(() {
      _newAttachments.addAll(result.files);
    });
  }

  void _removeNewAttachment(PlatformFile file) {
    setState(() {
      _newAttachments.remove(file);
    });
  }

  void _removeExistingAttachment(QualificationAttachment attachment) {
    setState(() {
      _existingAttachments.remove(attachment);
    });
  }

  String _attachmentLabel(String name) {
    if (name.length <= 24) return name;
    return '${name.substring(0, 21)}...';
  }

  Widget _buildStationFieldsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 1;
        if (width >= 1200) {
          columns = 3;
        } else if (width >= 800) {
          columns = 2;
        }

        final fields = <Widget>[
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'اسم المحطة',
              prefixIcon: Icon(Icons.local_gas_station),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال اسم المحطة';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _ownerNameController,
            decoration: const InputDecoration(
              labelText: 'اسم المالك',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          TextFormField(
            controller: _ownerPhoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
            ],
            decoration: const InputDecoration(
              labelText: 'رقم الجوال',
              prefixIcon: Icon(Icons.phone_android),
            ),
          ),
          TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'المدينة',
              prefixIcon: Icon(Icons.location_city),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال المدينة';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _regionController,
            decoration: const InputDecoration(
              labelText: 'المنطقة',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال المنطقة';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'العنوان',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال العنوان';
              }
              return null;
            },
          ),
        ];

        final rows = <Widget>[];
        for (var i = 0; i < fields.length; i += columns) {
          final rowChildren = <Widget>[];
          for (var j = 0; j < columns; j++) {
            if (i + j < fields.length) {
              rowChildren.add(Expanded(child: fields[i + j]));
            } else {
              rowChildren.add(const Expanded(child: SizedBox()));
            }
            if (j < columns - 1) {
              rowChildren.add(const SizedBox(width: 12));
            }
          }
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren,
            ),
          );
          rows.add(const SizedBox(height: 12));
        }
        if (rows.isNotEmpty) {
          rows.removeLast();
        }

        return Column(children: rows);
      },
    );
  }

  Widget _surfaceSection({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _heroSection() {
    final isEditing = widget.inspectionToEdit != null;
    final statusColor = _statusColor(_status);
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      borderRadius: const BorderRadius.all(Radius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: AppColors.appBarGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing
                            ? 'تعديل محطة التأهيل'
                            : 'إضافة محطة تأهيل جديدة',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أدخل بيانات المحطة، حدّد موقعها، وأرفق الملفات اللازمة داخل نموذج واضح ومتجاوب.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.add_business_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        _statusLabel(_status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedLatLng != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      '${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (_existingAttachments.isNotEmpty || _newAttachments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.warningOrange.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      '${_existingAttachments.length + _newAttachments.length} مرفق',
                      style: const TextStyle(
                        color: AppColors.warningOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_status);
    final detailsCard = _surfaceSection(
      title: 'بيانات المحطة',
      child: Column(
        children: [
          _buildStationFieldsGrid(),
          const SizedBox(height: 14),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ملاحظات',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.sticky_note_2_outlined),
            ),
          ),
        ],
      ),
    );

    final locationCard = _surfaceSection(
      title: 'تحديد الموقع',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: statusColor.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: statusColor),
            const SizedBox(width: 8),
            Text(
              _statusLabel(_status),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _pickLocation,
            icon: const Icon(Icons.map_outlined),
            label: Text(
              _selectedLatLng == null
                  ? 'تحديد الموقع من الخريطة'
                  : 'تعديل موقع المحطة',
            ),
          ),
          if (_selectedLatLng != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'الإحداثيات الحالية',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_selectedLatLng!.latitude.toStringAsFixed(6)}, ${_selectedLatLng!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final attachmentsCard = _surfaceSection(
      title: 'المرفقات',
      trailing: Text(
        '${_existingAttachments.length + _newAttachments.length} ملف',
        style: const TextStyle(
          color: AppColors.mediumGray,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _pickAttachments,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(
              _newAttachments.isEmpty
                  ? 'إرفاق صور أو فيديو'
                  : 'تمت إضافة ${_newAttachments.length} ملف جديد',
            ),
          ),
          if (_existingAttachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'المرفقات الحالية',
              style: TextStyle(
                color: AppColors.mediumGray,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _existingAttachments.map((attachment) {
                return InputChip(
                  label: Text(_attachmentLabel(attachment.name)),
                  onDeleted: () => _removeExistingAttachment(attachment),
                );
              }).toList(),
            ),
          ],
          if (_newAttachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'المرفقات الجديدة',
              style: TextStyle(
                color: AppColors.mediumGray,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _newAttachments.map((file) {
                return InputChip(
                  label: Text(_attachmentLabel(file.name)),
                  onDeleted: () => _removeNewAttachment(file),
                );
              }).toList(),
            ),
          ],
          if (_existingAttachments.isEmpty && _newAttachments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'لا توجد مرفقات مضافة بعد',
                style: TextStyle(color: AppColors.mediumGray),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        title: Text(
          widget.inspectionToEdit == null
              ? 'إضافة محطة تأهيل'
              : 'تعديل محطة التأهيل',
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AppSoftBackground(),
          Form(
            key: _formKey,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _heroSection(),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 1100;
                        if (!isWide) {
                          return Column(
                            children: [
                              detailsCard,
                              const SizedBox(height: 16),
                              locationCard,
                              const SizedBox(height: 16),
                              attachmentsCard,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  detailsCard,
                                  const SizedBox(height: 16),
                                  attachmentsCard,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: locationCard),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(18),
                      borderRadius: const BorderRadius.all(Radius.circular(28)),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'جاري الحفظ...' : 'حفظ بيانات المحطة',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
