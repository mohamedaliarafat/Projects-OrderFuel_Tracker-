import 'package:flutter/material.dart';
import 'package:order_tracker/utils/constants.dart';

class AttachmentItem extends StatelessWidget {
  final String fileName;
  final String fileSize;
  final VoidCallback onDelete;
  final bool canDelete;
  final bool isDesktop;

  const AttachmentItem({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.onDelete,
    this.canDelete = true,
    this.isDesktop = false,
  });

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();

    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();

    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool isMobile = width < 500;
        final bool isTablet = width >= 500 && width < 900;
        final bool isDesktop = width >= 900;

        final double iconSize = isMobile
            ? 20
            : isTablet
            ? 22
            : 24;
        final double containerPadding = isMobile ? 10 : 12;
        final double textTitleSize = isMobile ? 14 : 15;
        final double textSubSize = isMobile ? 11 : 12;
        final double actionIconSize = isMobile ? 18 : 20;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // File Icon
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: _getFileColor(fileName).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getFileIcon(fileName),
                  color: _getFileColor(fileName),
                  size: iconSize,
                ),
              ),

              const SizedBox(width: 12),

              // File Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: textTitleSize,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileSize,
                      style: TextStyle(
                        color: AppColors.mediumGray,
                        fontSize: textSubSize,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete Button
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: actionIconSize,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'حذف الملف',
                ),
            ],
          ),
        );
      },
    );
  }
}
