import 'package:flutter/material.dart';
import 'package:order_tracker/utils/constants.dart';

class ExportOptions extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportExcel;

  const ExportOptions({
    super.key,
    required this.onExportPDF,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'خيارات التصدير',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),

          // PDF Export
          ListTile(
            leading: const Icon(
              Icons.picture_as_pdf,
              color: AppColors.errorRed,
            ),
            title: const Text('تصدير إلى PDF'),
            subtitle: const Text('تنسيق PDF للطباعة والمشاركة'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              onExportPDF();
            },
          ),

          const Divider(),

          // Excel Export
          ListTile(
            leading: const Icon(
              Icons.table_chart,
              color: AppColors.successGreen,
            ),
            title: const Text('تصدير إلى Excel'),
            subtitle: const Text('تنسيق Excel للتحليل'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              onExportExcel();
            },
          ),

          const Divider(),

          // Print
          ListTile(
            leading: const Icon(Icons.print, color: AppColors.primaryBlue),
            title: const Text('طباعة مباشرة'),
            subtitle: const Text('طباعة التقرير مباشرة'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              // سيتم تطويرها
            },
          ),

          const SizedBox(height: 20),

          // Format Options
          const Text(
            'خيارات التنسيق:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFormatOption('A4', 'شائع'),
              _buildFormatOption('A3', 'كبير'),
              _buildFormatOption('خط كبير', 'واضح'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(String title, String subtitle) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGray),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(child: Text(title)),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 10, color: AppColors.mediumGray),
        ),
      ],
    );
  }
}
