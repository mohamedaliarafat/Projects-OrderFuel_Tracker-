import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:order_tracker/models/blocked_login_device.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/blocked_device_provider.dart';
import 'package:order_tracker/utils/constants.dart';

class BlockedDevicesScreen extends StatelessWidget {
  const BlockedDevicesScreen({super.key});

  static const String routeName = '/auth/blocked-devices';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManageBlockedDevices =
        auth.user?.role == 'owner' || auth.user?.role == 'admin';

    if (!canManageBlockedDevices) {
      return Scaffold(
        appBar: AppBar(title: const Text('الأجهزة المحظورة')),
        body: const Center(child: Text('لا تملك صلاحية الوصول إلى هذه الشاشة')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => BlockedDeviceProvider()..fetchDevices(),
      child: const _BlockedDevicesView(),
    );
  }
}

class _BlockedDevicesView extends StatelessWidget {
  const _BlockedDevicesView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BlockedDeviceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأجهزة المحظورة'),
        actions: [
          IconButton(
            onPressed: provider.isLoading
                ? null
                : () => context.read<BlockedDeviceProvider>().fetchDevices(),
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<BlockedDeviceProvider>().fetchDevices(),
        child: Builder(
          builder: (context) {
            if (provider.isLoading && provider.devices.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null && provider.devices.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Text(provider.error!, textAlign: TextAlign.center),
                    ),
                  ),
                ],
              );
            }

            if (provider.devices.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(
                    height: 420,
                    child: Center(child: Text('لا توجد أجهزة محظورة حالياً')),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = provider.devices[index];
                return _BlockedDeviceCard(device: device);
              },
            );
          },
        ),
      ),
    );
  }
}

class _BlockedDeviceCard extends StatelessWidget {
  const _BlockedDeviceCard({required this.device});

  final BlockedLoginDevice device;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BlockedDeviceProvider>();

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.phonelink_lock_outlined,
                    color: AppColors.errorRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.deviceName.isEmpty
                            ? device.deviceId
                            : device.deviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المنصة: ${device.platform} • المحاولات: ${device.failedAttempts}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () => _confirmUnblock(context, device.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                  ),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('فك الحظر'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _infoLine('سبب الحظر', device.blockReason),
            if (device.lastFailureReason.isNotEmpty &&
                device.lastFailureReason != device.blockReason)
              _infoLine('آخر سبب فشل', device.lastFailureReason),
            _infoLine('طريقة الدخول', _loginTypeLabel(device.lastLoginType)),
            _infoLine('آخر قيمة مدخلة', device.lastIdentifier),
            if ((device.matchedUserEmail ?? '').isNotEmpty)
              _infoLine('المستخدم المرتبط', device.matchedUserEmail!),
            if ((device.matchedUsername ?? '').isNotEmpty)
              _infoLine('اسم المستخدم', device.matchedUsername!),
            if (device.blockedAt != null)
              _infoLine(
                'وقت الحظر',
                DateFormat('yyyy-MM-dd HH:mm').format(device.blockedAt!),
              ),
            if ((device.ipAddress ?? '').isNotEmpty)
              _infoLine('IP', device.ipAddress!),
            if ((device.userAgent ?? '').isNotEmpty)
              _infoLine('User-Agent', device.userAgent!),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: AppColors.darkGray, height: 1.45),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }

  String _loginTypeLabel(String type) {
    switch (type) {
      case 'phone':
        return 'رقم الجوال';
      case 'username':
        return 'اسم المستخدم';
      case 'email':
        return 'البريد الإلكتروني';
      default:
        return type;
    }
  }

  Future<void> _confirmUnblock(
    BuildContext context,
    String deviceRecordId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فك حظر الجهاز'),
        content: const Text(
          'هل تريد السماح لهذا الجهاز بتسجيل الدخول مرة أخرى؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
            ),
            child: const Text('فك الحظر'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<BlockedDeviceProvider>().unblockDevice(deviceRecordId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم فك حظر الجهاز بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
