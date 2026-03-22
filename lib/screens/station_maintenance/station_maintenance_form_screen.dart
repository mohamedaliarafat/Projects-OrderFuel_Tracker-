import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/models/station_models.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/station_maintenance_provider.dart';
import 'package:order_tracker/providers/station_provider.dart';
import 'package:order_tracker/screens/tasks/task_location_picker_screen.dart';
import 'package:order_tracker/utils/constants.dart';

class StationMaintenanceFormScreen extends StatefulWidget {
  const StationMaintenanceFormScreen({super.key});

  @override
  State<StationMaintenanceFormScreen> createState() =>
      _StationMaintenanceFormScreenState();
}

class _StationMaintenanceFormScreenState
    extends State<StationMaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stationNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _mapsUrlController = TextEditingController();

  final List<XFile> _reportImages = [];
  final List<XFile> _reportVideos = [];

  List<Station> _stations = [];
  List<User> _technicians = [];

  String? _selectedStationId;
  String? _selectedTechnicianId;
  String _requestType = 'maintenance';

  bool _loadingStations = false;
  bool _loadingTechnicians = false;
  bool _saving = false;
  bool _isTechnicianMode = false;
  bool _useManualStation = false;
  bool _needsMaintenance = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final args = ModalRoute.of(context)?.settings.arguments;

      _isTechnicianMode = _isTechnicianRole(authProvider.user?.role);
      if (args is Map) {
        if (args['type'] is String) {
          _requestType = args['type'] as String;
        }
        if (args['mode'] == 'technician_report') {
          _isTechnicianMode = true;
        }
      }

      _loadStations();
      if (!_isTechnicianMode) {
        _loadTechnicians();
      }
    });
  }

  @override
  void dispose() {
    _stationNameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _mapsUrlController.dispose();
    super.dispose();
  }

  bool _isTechnicianRole(String? role) {
    return role == 'maintenance_technician' ||
        role == 'Maintenance_Technician' ||
        role == 'maintenance_station';
  }

  Future<void> _loadStations() async {
    setState(() => _loadingStations = true);
    try {
      final stationProvider = context.read<StationProvider>();
      await stationProvider.fetchStations(limit: 0);
      if (!mounted) return;
      final stations = List<Station>.from(stationProvider.stations)
        ..sort((a, b) => a.stationName.compareTo(b.stationName));
      setState(() => _stations = stations);
    } catch (e) {
      if (!mounted) return;
      _showSnack('تعذر تحميل المحطات: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _loadingStations = false);
      }
    }
  }

  Future<void> _loadTechnicians() async {
    setState(() => _loadingTechnicians = true);
    try {
      final provider = context.read<StationMaintenanceProvider>();
      final technicians = await provider.fetchTechnicians();
      if (!mounted) return;
      setState(() {
        _technicians = technicians
            .where(
              (tech) => tech.role.trim().toLowerCase() == 'maintenance_station',
            )
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('تعذر تحميل الفنيين: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _loadingTechnicians = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isTechnicianMode) {
      await _submitTechnicianReport();
      return;
    }

    await _submitManagerRequest();
  }

  Future<void> _submitManagerRequest() async {
    if (_selectedStationId == null || _selectedStationId!.trim().isEmpty) {
      _showSnack('يرجى اختيار المحطة', isError: true);
      return;
    }
    if (_selectedTechnicianId == null ||
        _selectedTechnicianId!.trim().isEmpty) {
      _showSnack('يرجى اختيار الفني المسؤول', isError: true);
      return;
    }

    setState(() => _saving = true);

    final provider = context.read<StationMaintenanceProvider>();
    final selectedStation = _stations.firstWhere(
      (station) => station.id == _selectedStationId,
      orElse: () => _fallbackStation(_selectedStationId!),
    );
    final selectedTech = _technicians.firstWhere(
      (tech) => tech.id == _selectedTechnicianId,
      orElse: () => User(
        id: _selectedTechnicianId!,
        name: '',
        email: '',
        role: '',
        company: '',
      ),
    );

    final created = await provider.createRequest(
      type: _requestType,
      stationName: selectedStation.stationName.trim(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      technicianId: _selectedTechnicianId!,
      technicianName: selectedTech.name,
      stationId: selectedStation.id,
      stationAddress: _addressController.text.trim(),
      stationLat: _parseDouble(_latController.text),
      stationLng: _parseDouble(_lngController.text),
      googleMapsUrl: _mapsUrlController.text.trim().isEmpty
          ? _buildMapsUrlFromCoords()
          : _mapsUrlController.text.trim(),
      needsMaintenance: _requestType != 'other',
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (created != null) {
      _showSnack('تم إنشاء الطلب بنجاح');
      Navigator.pop(context, created.id);
    } else {
      _showSnack(provider.error ?? 'حدث خطأ أثناء الحفظ', isError: true);
    }
  }

  Future<void> _submitTechnicianReport() async {
    if (!_useManualStation &&
        (_selectedStationId == null || _selectedStationId!.trim().isEmpty)) {
      _showSnack(
        'يرجى اختيار المحطة أو التبديل إلى الإدخال اليدوي',
        isError: true,
      );
      return;
    }

    final selectedStation = !_useManualStation && _selectedStationId != null
        ? _stations.firstWhere(
            (station) => station.id == _selectedStationId,
            orElse: () => _fallbackStation(_selectedStationId!),
          )
        : null;

    final stationName = _useManualStation
        ? _stationNameController.text.trim()
        : (selectedStation?.stationName.trim() ?? '');
    if (stationName.isEmpty) {
      _showSnack('اسم المحطة مطلوب', isError: true);
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<StationMaintenanceProvider>();
    final created = await provider.createTechnicianReport(
      stationName: stationName,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      technicianNotes: _notesController.text.trim(),
      needsMaintenance: _needsMaintenance,
      photoFiles: _reportImages,
      videoFiles: _reportVideos,
      stationId: _useManualStation ? null : selectedStation?.id,
      stationAddress: _addressController.text.trim(),
      stationLat: _parseDouble(_latController.text),
      stationLng: _parseDouble(_lngController.text),
      googleMapsUrl: _mapsUrlController.text.trim().isEmpty
          ? _buildMapsUrlFromCoords()
          : _mapsUrlController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (created != null) {
      _showSnack('تم إرسال التقرير للمراجعة');
      Navigator.pop(context, created.id);
    } else {
      _showSnack(provider.error ?? 'حدث خطأ أثناء الحفظ', isError: true);
    }
  }

  Future<void> _pickReportImages({required ImageSource source}) async {
    final picker = ImagePicker();
    if (source == ImageSource.camera) {
      final file = await picker.pickImage(source: ImageSource.camera);
      if (file != null && mounted) {
        setState(() => _reportImages.add(file));
      }
      return;
    }

    final files = await picker.pickMultiImage();
    if (files.isNotEmpty && mounted) {
      setState(() => _reportImages.addAll(files));
    }
  }

  Future<void> _pickReportVideo({required ImageSource source}) async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: source);
    if (file != null && mounted) {
      setState(() => _reportVideos.add(file));
    }
  }

  Future<void> _pickLocationOnMap() async {
    final initialLat = _parseDouble(_latController.text);
    final initialLng = _parseDouble(_lngController.text);
    final result = await Navigator.push<TaskLocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskLocationPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
          initialAddress: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        ),
      ),
    );

    if (result == null) return;

    _latController.text = result.latitude.toStringAsFixed(6);
    _lngController.text = result.longitude.toStringAsFixed(6);

    if (result.address != null && result.address!.trim().isNotEmpty) {
      _addressController.text = result.address!.trim();
    } else {
      final parts = [
        result.city,
        result.district,
        result.street,
      ].whereType<String>().where((item) => item.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) {
        _addressController.text = parts.join(' - ');
      }
    }

    if (_mapsUrlController.text.trim().isEmpty) {
      final url = _buildMapsUrlFromCoords();
      if (url != null) {
        _mapsUrlController.text = url;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isTechnicianMode
        ? 'تقرير صيانة جديد'
        : _requestType == 'development'
        ? 'إنشاء تطوير محطة'
        : _requestType == 'other'
        ? 'إنشاء طلب محطة'
        : 'إنشاء صيانة محطة';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth < 900
              ? constraints.maxWidth
              : 900.0;
          final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 24.0;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  children: [
                    if (_isTechnicianMode) _buildTechnicianInfoCard(),
                    if (_isTechnicianMode) const SizedBox(height: 12),
                    TextFormField(
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: _isTechnicianMode
                            ? 'رقم التقرير'
                            : 'رقم الطلب',
                        hintText: 'يتم توليده تلقائياً بعد الحفظ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_isTechnicianMode) ...[
                      DropdownButtonFormField<String>(
                        value: _requestType,
                        decoration: const InputDecoration(
                          labelText: 'نوع الطلب',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'maintenance',
                            child: Text('صيانة'),
                          ),
                          DropdownMenuItem(
                            value: 'development',
                            child: Text('تطوير'),
                          ),
                          DropdownMenuItem(value: 'other', child: Text('أخرى')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _requestType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildStationSection(),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: _isTechnicianMode
                            ? 'عنوان التقرير'
                            : 'عنوان الطلب',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _isTechnicianMode
                              ? 'عنوان التقرير مطلوب'
                              : 'عنوان الطلب مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: _isTechnicianMode
                            ? 'تقرير عن المحطة التي تمت زيارتها'
                            : 'وصف الأعمال',
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (_isTechnicianMode &&
                            (value == null || value.trim().isEmpty)) {
                          return 'وصف التقرير مطلوب';
                        }
                        return null;
                      },
                    ),
                    if (_isTechnicianMode) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'ملاحظات'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildNeedsMaintenanceSelector(),
                    ],
                    const SizedBox(height: 16),
                    _buildLocationSection(),
                    if (_isTechnicianMode) ...[
                      const SizedBox(height: 16),
                      _buildAttachmentsSection(),
                    ],
                    if (!_isTechnicianMode) ...[
                      const SizedBox(height: 16),
                      _buildTechnicianSection(),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: Icon(
                        _isTechnicianMode
                            ? Icons.send_outlined
                            : Icons.check_circle_outline,
                      ),
                      label: Text(
                        _saving
                            ? 'جارٍ الحفظ...'
                            : _isTechnicianMode
                            ? 'إرسال التقرير'
                            : 'حفظ الطلب',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechnicianInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'أنشئ تقرير زيارة للمحطة وحدد إذا كانت تحتاج صيانة. سيظهر التقرير في قائمة التقارير ويصل للإدارة للمراجعة.',
              style: TextStyle(color: AppColors.mediumGray, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'بيانات المحطة',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_isTechnicianMode) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('اختيار من النظام'),
                selected: !_useManualStation,
                onSelected: (_) {
                  setState(() {
                    _useManualStation = false;
                    _stationNameController.clear();
                  });
                },
              ),
              ChoiceChip(
                label: const Text('إدخال يدوي'),
                selected: _useManualStation,
                onSelected: (_) {
                  setState(() {
                    _useManualStation = true;
                    _selectedStationId = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_loadingStations)
          const Center(child: CircularProgressIndicator())
        else if (!_useManualStation) ...[
          if (_stations.isEmpty)
            const Text(
              'لا توجد محطات مسجلة حالياً',
              style: TextStyle(color: AppColors.errorRed),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedStationId,
              decoration: const InputDecoration(labelText: 'اسم المحطة'),
              items: _stations
                  .map(
                    (station) => DropdownMenuItem<String>(
                      value: station.id,
                      child: Text(
                        station.stationCode.isNotEmpty
                            ? '${station.stationName} (${station.stationCode})'
                            : station.stationName,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                final selected = _stations.firstWhere(
                  (station) => station.id == value,
                  orElse: () => _stations.first,
                );
                final addressParts = [
                  selected.location,
                  selected.city,
                ].where((part) => part.trim().isNotEmpty).toList();
                setState(() {
                  _selectedStationId = value;
                  _stationNameController.text = selected.stationName;
                  if (addressParts.isNotEmpty) {
                    _addressController.text = addressParts.join(' - ');
                  }
                });
              },
              validator: (value) {
                if (_useManualStation) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'اسم المحطة مطلوب';
                }
                return null;
              },
            ),
        ] else ...[
          TextFormField(
            controller: _stationNameController,
            decoration: const InputDecoration(labelText: 'اسم المحطة يدوياً'),
            validator: (value) {
              if (_useManualStation &&
                  (value == null || value.trim().isEmpty)) {
                return 'اسم المحطة مطلوب';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNeedsMaintenanceSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'هل تحتاج المحطة إلى صيانة؟',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('نعم تحتاج صيانة'),
                selected: _needsMaintenance,
                onSelected: (_) => setState(() => _needsMaintenance = true),
              ),
              ChoiceChip(
                label: const Text('لا تحتاج حالياً'),
                selected: !_needsMaintenance,
                onSelected: (_) => setState(() => _needsMaintenance = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'موقع المحطة',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'العنوان أو الوصف المختصر للموقع',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: _pickLocationOnMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('اختيار من الخريطة'),
          ),
        ),
        if (_addressController.text.trim().isNotEmpty ||
            (_latController.text.trim().isNotEmpty &&
                _lngController.text.trim().isNotEmpty)) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Text(
              _addressController.text.trim().isNotEmpty
                  ? _addressController.text.trim()
                  : 'الموقع المختار: ${_latController.text}, ${_lngController.text}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'مرفقات التقرير',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'بدون حد',
                style: TextStyle(color: AppColors.mediumGray, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'يمكنك إضافة أي عدد من الصور أو الفيديوهات، سواء بالتصوير المباشر أو الإرفاق من الجهاز.',
            style: TextStyle(color: AppColors.mediumGray, height: 1.4),
          ),
          const SizedBox(height: 14),
          _buildImagePickerSection(),
          const SizedBox(height: 16),
          _buildVideoPickerSection(),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صور التقرير',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickReportImages(source: ImageSource.camera),
              icon: const Icon(Icons.photo_camera),
              label: const Text('التقاط صورة'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickReportImages(source: ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('إرفاق صور'),
            ),
          ],
        ),
        if (_reportImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('تم اختيار ${_reportImages.length} صورة'),
          const SizedBox(height: 8),
          ..._reportImages.asMap().entries.map(
            (entry) => _buildPickedFileTile(
              index: entry.key,
              file: entry.value,
              icon: Icons.image_outlined,
              onRemove: () => setState(() => _reportImages.removeAt(entry.key)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoPickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'فيديوهات التقرير',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickReportVideo(source: ImageSource.camera),
              icon: const Icon(Icons.videocam),
              label: const Text('تصوير فيديو'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickReportVideo(source: ImageSource.gallery),
              icon: const Icon(Icons.video_library),
              label: const Text('إرفاق فيديو'),
            ),
          ],
        ),
        if (_reportVideos.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('تم اختيار ${_reportVideos.length} فيديو'),
          const SizedBox(height: 8),
          ..._reportVideos.asMap().entries.map(
            (entry) => _buildPickedFileTile(
              index: entry.key,
              file: entry.value,
              icon: Icons.movie_outlined,
              onRemove: () => setState(() => _reportVideos.removeAt(entry.key)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPickedFileTile({
    required int index,
    required XFile file,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${index + 1}. ${file.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            tooltip: 'حذف',
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تعيين الفني',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_loadingTechnicians)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<String>(
            value: _selectedTechnicianId,
            decoration: const InputDecoration(labelText: 'اختر الفني'),
            items: _technicians
                .map(
                  (tech) => DropdownMenuItem<String>(
                    value: tech.id,
                    child: Text(tech.name.isNotEmpty ? tech.name : tech.email),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedTechnicianId = value),
            validator: (value) {
              if (_isTechnicianMode) return null;
              if (value == null || value.trim().isEmpty) {
                return 'يرجى اختيار الفني';
              }
              return null;
            },
          ),
      ],
    );
  }

  Station _fallbackStation(String id) {
    return Station(
      id: id,
      stationCode: '',
      stationName: _stationNameController.text.trim(),
      location: _addressController.text.trim(),
      city: '',
      managerName: '',
      managerPhone: '',
      fuelTypes: const [],
      pumps: const [],
      fuelPrices: const [],
      createdById: '',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      ),
    );
  }

  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  String? _buildMapsUrlFromCoords() {
    final lat = _parseDouble(_latController.text);
    final lng = _parseDouble(_lngController.text);
    if (lat == null || lng == null) return null;
    return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
  }
}
