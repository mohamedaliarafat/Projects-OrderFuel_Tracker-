import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:order_tracker/models/station_maintenance_models.dart';
import 'package:order_tracker/utils/constants.dart';

const double _pageMargin = 8;
const double _sectionGap = 5;
const double _headerFontSize = 10;
const double _bodyFontSize = 6.8;
const double _headerCellFontSize = 7.1;
const double _sectionTitleFontSize = 8.6;

Future<Uint8List> buildStationMaintenanceReportPdf(
  StationMaintenanceRequest request,
) async {
  final pdf = pw.Document();
  final logo = pw.MemoryImage(
    (await rootBundle.load(AppImages.logo)).buffer.asUint8List(),
  );
  final regularFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
  );
  final boldFont = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(_pageMargin),
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildHeader(logo, request),
          pw.SizedBox(height: _sectionGap),
          _buildOverviewTable(request),
          pw.SizedBox(height: _sectionGap),
          _buildNarrativeSection(request),
          pw.SizedBox(height: _sectionGap),
          _buildFinancialTable(request),
          pw.SizedBox(height: _sectionGap),
          _buildReviewTable(request),
          pw.SizedBox(height: _sectionGap),
          _buildFooter(),
        ],
      ),
    ),
  );

  return pdf.save();
}

pw.Widget _buildHeader(
  pw.MemoryImage logoImage,
  StationMaintenanceRequest request,
) {
  final reportTitle = request.entryType == 'technician_report'
      ? 'تقرير زيارة وصيانة محطة'
      : 'طلب صيانة / تطوير محطة';

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Directionality(
      textDirection: pw.TextDirection.ltr,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 42,
            height: 42,
            alignment: pw.Alignment.center,
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  reportTitle,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: _headerFontSize,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'شركة البحيرة العربية للنقليات',
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 7.2),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'رقم المرجع: ${_safe(request.requestNumber)} | تاريخ الإصدار: ${_formatDate(request.createdAt)}',
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 6.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _buildOverviewTable(StationMaintenanceRequest request) {
  return _buildCompactTable(
    headers: const [
      'رقم المرجع',
      'نوع السجل',
      'نوع الطلب',
      'المحطة',
      'الفني',
      'الحالة',
      'تحتاج صيانة',
      'تاريخ الزيارة',
    ],
    data: [
      [
        _compactText(_safe(request.requestNumber), 22),
        request.entryType == 'technician_report' ? 'تقرير فني' : 'طلب إدارة',
        _typeLabel(request.type),
        _compactText(_safe(request.stationName), 22),
        _compactText(_safe(request.assignedToName), 18),
        _statusLabel(request.status),
        request.needsMaintenance ? 'نعم' : 'لا',
        _formatDate(request.submittedAt ?? request.createdAt),
      ],
    ],
  );
}

pw.Widget _buildNarrativeSection(StationMaintenanceRequest request) {
  final rows = <List<String>>[
    [_compactText(_safe(request.description), 120), 'وصف التقرير / الطلب'],
    [_compactText(_safe(request.technicianNotes), 100), 'ملاحظات الفني'],
    [_compactText(_safe(request.stationLocation?.address), 80), 'عنوان المحطة'],
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _buildSectionTitle('تفاصيل التقرير'),
      pw.SizedBox(height: 3),
      _buildCompactTable(
        headers: const ['القيمة', 'العنوان'],
        data: rows,
        columnWidths: {
          0: const pw.FlexColumnWidth(2.2),
          1: const pw.FlexColumnWidth(1),
        },
      ),
    ],
  );
}

pw.Widget _buildFinancialTable(StationMaintenanceRequest request) {
  final summary = request.summary;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _buildSectionTitle('الملخص المالي والمرفقات'),
      pw.SizedBox(height: 3),
      _buildCompactTable(
        headers: const [
          'صور قبل',
          'صور بعد',
          'فيديوهات',
          'ملفات فواتير',
          'إجمالي قبل الضريبة',
          'الضريبة',
          'الإجمالي',
        ],
        data: [
          [
            request.beforePhotos.length.toString(),
            request.afterPhotos.length.toString(),
            request.videos.length.toString(),
            request.invoiceFiles.length.toString(),
            summary.subtotal.toStringAsFixed(2),
            summary.taxAmount.toStringAsFixed(2),
            summary.total.toStringAsFixed(2),
          ],
        ],
      ),
    ],
  );
}

pw.Widget _buildReviewTable(StationMaintenanceRequest request) {
  final review = request.review;
  final rating = request.rating;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _buildSectionTitle('نتيجة المراجعة'),
      pw.SizedBox(height: 3),
      _buildCompactTable(
        headers: const [
          'القرار',
          'ملاحظات الإدارة',
          'تم بواسطة',
          'تاريخ المراجعة',
          'التقييم',
          'ملاحظة التقييم',
        ],
        data: [
          [
            review == null ? '-' : _reviewDecisionLabel(review.decision),
            _compactText(
              review?.notes?.trim().isNotEmpty == true
                  ? review!.notes!.trim()
                  : '-',
              55,
            ),
            _compactText(_safe(review?.reviewedByName), 22),
            _formatDate(review?.reviewedAt),
            rating == null ? '-' : rating.score.toStringAsFixed(1),
            _compactText(
              rating?.note?.trim().isNotEmpty == true
                  ? rating!.note!.trim()
                  : '-',
              45,
            ),
          ],
        ],
      ),
    ],
  );
}

pw.Widget _buildFooter() {
  return pw.Column(
    children: [
      pw.Divider(color: PdfColors.grey500, height: 1),
      pw.SizedBox(height: 5),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'توقيع مسؤول الصيانة',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('----------------------'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'اعتماد الإدارة',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('----------------------'),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'المملكة العربية السعودية - نظام نبراس | شركة البحيرة العربية',
        style: const pw.TextStyle(fontSize: 5.8),
      ),
    ],
  );
}

pw.Widget _buildSectionTitle(String title) {
  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Text(
      title,
      textAlign: pw.TextAlign.right,
      style: pw.TextStyle(
        fontSize: _sectionTitleFontSize,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

pw.Widget _buildCompactTable({
  required List<String> headers,
  required List<List<String>> data,
  Map<int, pw.TableColumnWidth>? columnWidths,
}) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.45),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
    headerStyle: pw.TextStyle(
      fontSize: _headerCellFontSize,
      fontWeight: pw.FontWeight.bold,
    ),
    cellStyle: const pw.TextStyle(fontSize: _bodyFontSize),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    columnWidths: columnWidths,
    headerAlignment: pw.Alignment.center,
    cellAlignments: {
      for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerRight,
    },
  );
}

String _safe(String? value) {
  if (value == null || value.trim().isEmpty) return '-';
  return value.trim();
}

String _compactText(String? value, int maxLength) {
  final normalized = _safe(value).replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.length <= maxLength) return normalized;
  return '${normalized.substring(0, maxLength - 3)}...';
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('yyyy-MM-dd HH:mm').format(value);
}

String _statusLabel(String status) {
  switch (status) {
    case 'assigned':
      return 'مسند';
    case 'in_progress':
      return 'قيد التنفيذ';
    case 'under_review':
      return 'تحت المراجعة';
    case 'needs_revision':
      return 'رد بملاحظة';
    case 'approved':
      return 'مقبول';
    case 'rejected':
      return 'مرفوض';
    case 'closed':
      return 'مغلق';
    default:
      return status;
  }
}

String _typeLabel(String type) {
  if (type == 'development') {
    return 'تطوير محطة';
  }
  if (type == 'other') {
    return 'أخرى';
  }
  return 'صيانة محطة';
}

String _reviewDecisionLabel(String decision) {
  switch (decision) {
    case 'approved':
      return 'قبول';
    case 'rejected':
      return 'رفض';
    case 'needs_revision':
      return 'رد بملاحظة';
    default:
      return decision;
  }
}
