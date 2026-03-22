import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/models/managed_auth_device.dart';
import 'package:order_tracker/models/models.dart';
import 'package:order_tracker/providers/auth_provider.dart';
import 'package:order_tracker/providers/managed_devices_provider.dart';
import 'package:order_tracker/providers/user_management_provider.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:provider/provider.dart';

class AuthDevicesScreen extends StatelessWidget {
  const AuthDevicesScreen({super.key});

  static const String routeName = '/auth/devices';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.user?.role == 'owner';

    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('إدارة الأجهزة')),
        body: const Center(child: Text('هذه الشاشة متاحة للمالك فقط')),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ManagedDevicesProvider()..fetchDevices(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserManagementProvider()..fetchAllUsers(),
        ),
      ],
      child: const _ManagedDevicesView(),
    );
  }
}

class _ManagedDevicesView extends StatelessWidget {
  const _ManagedDevicesView();

  @override
  Widget build(BuildContext context) {
    final devicesProvider = context.watch<ManagedDevicesProvider>();
    final usersProvider = context.watch<UserManagementProvider>();
    final userEntries = _collectManagedUsers(
      usersProvider.users,
      devicesProvider.devices,
    );
    final activeUserEntries = userEntries
        .where((entry) => entry.activeSessionDevices.isNotEmpty)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأجهزة'),
        actions: [
          IconButton(
            onPressed: devicesProvider.isLoading || usersProvider.isLoading
                ? null
                : () => _refresh(context),
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
          IconButton(
            onPressed:
                devicesProvider.isSaving || devicesProvider.activeSessions == 0
                ? null
                : () => _confirmLogoutAll(context),
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل خروج جميع الأجهزة',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: Builder(
          builder: (context) {
            if (devicesProvider.isLoading &&
                usersProvider.isLoading &&
                devicesProvider.devices.isEmpty &&
                usersProvider.users.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final errors = <String>[
              if (devicesProvider.error != null &&
                  devicesProvider.error!.trim().isNotEmpty)
                devicesProvider.error!,
              if (usersProvider.error != null &&
                  usersProvider.error!.trim().isNotEmpty)
                usersProvider.error!,
            ];

            if (errors.isNotEmpty &&
                devicesProvider.devices.isEmpty &&
                usersProvider.users.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Text(
                        errors.join('\n\n'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (errors.isNotEmpty) ...[
                  _InlineErrorBanner(message: errors.join('\n')),
                  const SizedBox(height: 16),
                ],
                _SummarySection(
                  totalUsers: usersProvider.users.length,
                  totalVisibleUsers: userEntries.length,
                  activeUsers: activeUserEntries.length,
                  totalDevices: devicesProvider.totalDevices,
                  activeSessions: devicesProvider.activeSessions,
                  blockedUsers: userEntries
                      .where((entry) => entry.isBlocked)
                      .length,
                  blockedDevices: devicesProvider.blockedDevices,
                ),
                const SizedBox(height: 18),
                _BulkSessionActionCard(
                  activeUsers: activeUserEntries.length,
                  activeSessions: devicesProvider.activeSessions,
                  isSaving: devicesProvider.isSaving,
                  onLogoutAll: devicesProvider.activeSessions == 0
                      ? null
                      : () => _confirmLogoutAll(context),
                ),
                const SizedBox(height: 18),
                const _SectionHeader(
                  title: 'المستخدمون المسجلون دخول حالياً',
                  subtitle:
                      'يعرض كل حساب يملك جلسة نشطة الآن، ويمكنك إنهاء جميع جلساتهم دفعة واحدة.',
                ),
                const SizedBox(height: 12),
                if (activeUserEntries.isEmpty)
                  const _EmptySection(
                    message: 'لا يوجد أي مستخدم مسجل دخول حالياً',
                  )
                else
                  ...activeUserEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ManagedUserCard(entry: entry),
                    ),
                  ),
                const SizedBox(height: 8),
                const _SectionHeader(
                  title: 'المستخدمون مع أجهزتهم',
                  subtitle:
                      'يعرض كل المستخدمين المسجلين في النظام، مع أجهزتهم المرتبطة وجلساتهم النشطة الحالية.',
                ),
                const SizedBox(height: 12),
                if (userEntries.isEmpty)
                  const _EmptySection(message: 'لا يوجد مستخدمون لعرضهم حالياً')
                else
                  ...userEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ManagedUserCard(entry: entry),
                    ),
                  ),
                const SizedBox(height: 8),
                const _SectionHeader(
                  title: 'كل الأجهزة المسجلة',
                  subtitle:
                      'عرض مستقل لكل جهاز مسجل مع تفاصيل الجلسة الحالية والحظر وتسجيل الخروج.',
                ),
                const SizedBox(height: 12),
                if (devicesProvider.devices.isEmpty)
                  const _EmptySection(message: 'لا توجد أجهزة مسجلة حالياً')
                else
                  ...devicesProvider.devices.map(
                    (device) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ManagedDeviceCard(device: device),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<ManagedDevicesProvider>().fetchDevices(),
      context.read<UserManagementProvider>().fetchAllUsers(),
    ]);
  }

  Future<void> _confirmLogoutAll(BuildContext context) async {
    final provider = context.read<ManagedDevicesProvider>();
    final shouldLogoutCurrentDevice =
        provider.currentDeviceId != null &&
        provider.devices.any(
          (device) =>
              device.deviceId == provider.currentDeviceId && device.isLoggedIn,
        );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل خروج جميع الأجهزة'),
        content: const Text(
          'سيتم إنهاء جميع الجلسات النشطة على كل الأجهزة المسجلة. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningOrange,
            ),
            child: const Text('تنفيذ'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final affectedDevices = await provider.logoutAllDevices();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل خروج $affectedDevices جهاز بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (shouldLogoutCurrentDevice) {
        await _DeviceActionHandler.logoutLocally(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.toString());
    }
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.totalUsers,
    required this.totalVisibleUsers,
    required this.activeUsers,
    required this.totalDevices,
    required this.activeSessions,
    required this.blockedUsers,
    required this.blockedDevices,
  });

  final int totalUsers;
  final int totalVisibleUsers;
  final int activeUsers;
  final int totalDevices;
  final int activeSessions;
  final int blockedUsers;
  final int blockedDevices;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryCard(
          title: 'المستخدمون',
          value: totalUsers.toString(),
          icon: Icons.people_alt_outlined,
          color: AppColors.primaryDarkBlue,
        ),
        _SummaryCard(
          title: 'المعروضون هنا',
          value: totalVisibleUsers.toString(),
          icon: Icons.groups_2_outlined,
          color: AppColors.primaryBlue,
        ),
        _SummaryCard(
          title: 'المستخدمون النشطون',
          value: activeUsers.toString(),
          icon: Icons.how_to_reg_outlined,
          color: AppColors.successGreen,
        ),
        _SummaryCard(
          title: 'الأجهزة المسجلة',
          value: totalDevices.toString(),
          icon: Icons.devices_outlined,
          color: AppColors.infoBlue,
        ),
        _SummaryCard(
          title: 'الجلسات النشطة',
          value: activeSessions.toString(),
          icon: Icons.verified_user_outlined,
          color: AppColors.successGreen,
        ),
        _SummaryCard(
          title: 'المستخدمون المحظورون',
          value: blockedUsers.toString(),
          icon: Icons.person_off_outlined,
          color: AppColors.warningOrange,
        ),
        _SummaryCard(
          title: 'الأجهزة المحظورة',
          value: blockedDevices.toString(),
          icon: Icons.phonelink_lock_outlined,
          color: AppColors.errorRed,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}

class _BulkSessionActionCard extends StatelessWidget {
  const _BulkSessionActionCard({
    required this.activeUsers,
    required this.activeSessions,
    required this.isSaving,
    required this.onLogoutAll,
  });

  final int activeUsers;
  final int activeSessions;
  final bool isSaving;
  final VoidCallback? onLogoutAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryDarkBlue.withOpacity(0.12)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الجلسات النشطة على النظام',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'يوجد الآن $activeUsers مستخدم نشط بعدد $activeSessions جلسة نشطة.',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: isSaving ? null : onLogoutAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.logout),
            label: Text(
              activeSessions == 0
                  ? 'لا توجد جلسات نشطة'
                  : 'تسجيل خروج جميع المستخدمين',
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagedUserCard extends StatelessWidget {
  const _ManagedUserCard({required this.entry});

  final _ManagedUserEntry entry;

  @override
  Widget build(BuildContext context) {
    final devicesProvider = context.watch<ManagedDevicesProvider>();
    final usersProvider = context.watch<UserManagementProvider>();
    final activeSessionCount = entry.activeSessionDevices.length;

    final statusLabel = entry.isBlocked
        ? 'المستخدم محظور'
        : activeSessionCount > 0
        ? 'نشط حالياً'
        : 'مسجل بالنظام';
    final statusColor = entry.isBlocked
        ? AppColors.errorRed
        : activeSessionCount > 0
        ? AppColors.successGreen
        : AppColors.primaryDarkBlue;

    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  entry.displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _StatusChip(label: statusLabel, color: statusColor),
                _StatusChip(
                  label: '${entry.devices.length} جهاز مسجل',
                  color: AppColors.primaryBlue,
                ),
                if (activeSessionCount > 0)
                  _StatusChip(
                    label: '$activeSessionCount جلسة نشطة',
                    color: AppColors.successGreen,
                  )
                else if (!entry.isBlocked)
                  const _StatusChip(
                    label: 'لا توجد جلسة نشطة',
                    color: AppColors.warningOrange,
                  ),
                if (!entry.hasControllableAccount)
                  const _StatusChip(
                    label: 'حساب من سجل الأجهزة',
                    color: AppColors.warningOrange,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                if (entry.email.isNotEmpty) _InlineMeta(text: entry.email),
                if (entry.username.isNotEmpty)
                  _InlineMeta(text: 'اسم المستخدم: ${entry.username}'),
                if (entry.phone.isNotEmpty)
                  _InlineMeta(text: 'الجوال: ${entry.phone}'),
                if (entry.role.isNotEmpty)
                  _InlineMeta(text: 'الدور: ${entry.role}'),
                if (entry.company.isNotEmpty)
                  _InlineMeta(text: 'الشركة: ${entry.company}'),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (entry.hasControllableAccount)
                  entry.isBlocked
                      ? OutlinedButton.icon(
                          onPressed:
                              usersProvider.isSaving || devicesProvider.isSaving
                              ? null
                              : () => _UserActionHandler.toggleUserBlock(
                                  context,
                                  entry: entry,
                                  block: false,
                                ),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('فك حظر المستخدم'),
                        )
                      : ElevatedButton.icon(
                          onPressed:
                              usersProvider.isSaving || devicesProvider.isSaving
                              ? null
                              : () => _UserActionHandler.toggleUserBlock(
                                  context,
                                  entry: entry,
                                  block: true,
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorRed,
                          ),
                          icon: const Icon(Icons.person_off),
                          label: const Text('حظر المستخدم'),
                        ),
                OutlinedButton.icon(
                  onPressed: devicesProvider.isSaving || activeSessionCount == 0
                      ? null
                      : () => _UserActionHandler.logoutUserSessions(
                          context,
                          entry,
                        ),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل خروج المستخدم'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (entry.devices.isEmpty)
              const _EmptyPanel(
                message:
                    'لا يوجد جهاز مسجل أو جلسة مرتبطة لهذا المستخدم حالياً',
              )
            else
              Column(
                children: entry.devices
                    .map(
                      (deviceLink) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ManagedUserDeviceTile(deviceLink: deviceLink),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _ManagedUserDeviceTile extends StatelessWidget {
  const _ManagedUserDeviceTile({required this.deviceLink});

  final _ManagedUserDeviceLink deviceLink;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagedDevicesProvider>();
    final device = deviceLink.device;
    final isCurrentDevice = provider.isCurrentDevice(device.deviceId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                device.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              _StatusChip(
                label: device.blocked
                    ? 'الجهاز محظور'
                    : device.isLoggedIn
                    ? 'نشط'
                    : 'غير متصل',
                color: _DeviceActionHandler.statusColor(device),
              ),
              _StatusChip(
                label: deviceLink.isSessionOwner
                    ? 'جلسة هذا المستخدم'
                    : 'جهاز مرتبط بالحساب',
                color: deviceLink.isSessionOwner
                    ? AppColors.primaryDarkBlue
                    : AppColors.warningOrange,
              ),
              if (isCurrentDevice)
                const _StatusChip(
                  label: 'هذا الجهاز',
                  color: AppColors.primaryDarkBlue,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _InlineMeta(
                text:
                    'المنصة: ${_DeviceActionHandler.platformLabel(device.platform)}',
              ),
              if (device.ipAddress.isNotEmpty)
                _InlineMeta(text: 'الاتصال: ${device.ipAddress}'),
              if (device.lastLoginType.isNotEmpty)
                _InlineMeta(
                  text:
                      'طريقة الدخول: ${_DeviceActionHandler.loginTypeLabel(device.lastLoginType)}',
                ),
            ],
          ),
          if (!deviceLink.isSessionOwner &&
              _DeviceActionHandler.currentUserLabel(device).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'المستخدم الحالي على الجهاز: ${_DeviceActionHandler.currentUserLabel(device)}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (device.blocked)
                OutlinedButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () => _DeviceActionHandler.confirmUnblock(
                          context,
                          device,
                        ),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('فك حظر الجهاز'),
                )
              else
                ElevatedButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () => _DeviceActionHandler.promptBlockDevice(
                          context,
                          device,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                  ),
                  icon: const Icon(Icons.block),
                  label: const Text('حظر الجهاز'),
                ),
              OutlinedButton.icon(
                onPressed: provider.isSaving || !device.isLoggedIn
                    ? null
                    : () => _DeviceActionHandler.confirmLogoutDevice(
                        context,
                        device,
                      ),
                icon: const Icon(Icons.logout),
                label: Text(
                  deviceLink.isSessionOwner
                      ? 'تسجيل خروجه من الجهاز'
                      : 'تسجيل خروج الجهاز',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManagedDeviceCard extends StatelessWidget {
  const _ManagedDeviceCard({required this.device});

  final ManagedAuthDevice device;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagedDevicesProvider>();
    final isCurrentDevice = provider.isCurrentDevice(device.deviceId);
    final currentUserLabel = _DeviceActionHandler.currentUserLabel(device);

    return Card(
      elevation: 1.2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _DeviceActionHandler.statusColor(
                      device,
                    ).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _DeviceActionHandler.statusIcon(device),
                    color: _DeviceActionHandler.statusColor(device),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            device.displayName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _StatusChip(
                            label: device.blocked
                                ? 'محظور'
                                : device.isLoggedIn
                                ? 'نشط'
                                : 'غير متصل',
                            color: _DeviceActionHandler.statusColor(device),
                          ),
                          if (isCurrentDevice)
                            const _StatusChip(
                              label: 'هذا الجهاز',
                              color: AppColors.primaryDarkBlue,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'المنصة: ${_DeviceActionHandler.platformLabel(device.platform)}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      if (currentUserLabel.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'المستخدم الحالي: $currentUserLabel',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (device.blocked)
                  OutlinedButton.icon(
                    onPressed: provider.isSaving
                        ? null
                        : () => _DeviceActionHandler.confirmUnblock(
                            context,
                            device,
                          ),
                    icon: const Icon(Icons.lock_open),
                    label: const Text('فك الحظر'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: provider.isSaving
                        ? null
                        : () => _DeviceActionHandler.promptBlockDevice(
                            context,
                            device,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                    ),
                    icon: const Icon(Icons.block),
                    label: const Text('حظر الجهاز'),
                  ),
                OutlinedButton.icon(
                  onPressed: provider.isSaving || !device.isLoggedIn
                      ? null
                      : () => _DeviceActionHandler.confirmLogoutDevice(
                          context,
                          device,
                        ),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل خروج الجهاز'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (device.linkedUsers.isNotEmpty) ...[
              const _SectionMiniTitle('الحسابات المرتبطة بالجهاز'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: device.linkedUsers
                    .map(
                      (user) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          user.email.isNotEmpty
                              ? '${user.displayLabel} • ${user.email}'
                              : user.displayLabel,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 14),
            ],
            _InfoLine(
              label: 'عنوان الاتصال',
              value: device.ipAddress.isEmpty ? '-' : device.ipAddress,
            ),
            _InfoLine(
              label: 'المعرف الأخير',
              value: device.lastIdentifier.isEmpty
                  ? '-'
                  : device.lastIdentifier,
            ),
            _InfoLine(
              label: 'طريقة الدخول الأخيرة',
              value: _DeviceActionHandler.loginTypeLabel(device.lastLoginType),
            ),
            _InfoLine(
              label: 'آخر ظهور',
              value: _DeviceActionHandler.formatDate(device.lastSeenAt),
            ),
            _InfoLine(
              label: 'آخر دخول',
              value: _DeviceActionHandler.formatDate(device.lastLoginAt),
            ),
            if (device.currentSessionStartedAt != null)
              _InfoLine(
                label: 'بداية الجلسة الحالية',
                value: _DeviceActionHandler.formatDate(
                  device.currentSessionStartedAt,
                ),
              ),
            if (device.lastLogoutAt != null)
              _InfoLine(
                label: 'آخر تسجيل خروج',
                value:
                    '${_DeviceActionHandler.formatDate(device.lastLogoutAt)}${device.lastLogoutReason.isNotEmpty ? ' • ${device.lastLogoutReason}' : ''}',
              ),
            if (device.blockReason.isNotEmpty)
              _InfoLine(label: 'سبب الحظر', value: device.blockReason),
            if (device.userAgent.isNotEmpty)
              _InfoLine(label: 'المتصفح/العميل', value: device.userAgent),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}

class _SectionMiniTitle extends StatelessWidget {
  const _SectionMiniTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 180, child: Center(child: Text(message)));
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: Colors.grey[700]));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
            TextSpan(text: value.trim().isEmpty ? '-' : value.trim()),
          ],
        ),
      ),
    );
  }
}

class _DeviceActionHandler {
  const _DeviceActionHandler._();

  static Color statusColor(ManagedAuthDevice device) {
    if (device.blocked) return AppColors.errorRed;
    if (device.isLoggedIn) return AppColors.successGreen;
    return AppColors.warningOrange;
  }

  static IconData statusIcon(ManagedAuthDevice device) {
    if (device.blocked) return Icons.phonelink_lock_outlined;
    if (device.isLoggedIn) return Icons.devices;
    return Icons.devices_other_outlined;
  }

  static String currentUserLabel(ManagedAuthDevice device) {
    if (device.currentSessionUser != null &&
        device.currentSessionUser!.displayLabel.trim().isNotEmpty) {
      return device.currentSessionUser!.displayLabel.trim();
    }

    if (device.isLoggedIn) {
      final candidates = [
        device.matchedUserName,
        device.matchedUsername,
        device.matchedUserEmail,
      ];
      for (final candidate in candidates) {
        if ((candidate ?? '').trim().isNotEmpty) {
          return candidate!.trim();
        }
      }
    }

    return '';
  }

  static Future<void> promptBlockDevice(
    BuildContext context,
    ManagedAuthDevice device,
  ) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حظر الجهاز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'يمكنك إدخال سبب الحظر ليظهر داخل لوحة الإدارة. ترك الحقل فارغاً سيستخدم سبباً افتراضياً.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'سبب الحظر',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('حظر'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final updatedDevice = await context
          .read<ManagedDevicesProvider>()
          .blockDevice(device.id, reason: controller.text);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حظر الجهاز بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (context.read<ManagedDevicesProvider>().isCurrentDevice(
        updatedDevice.deviceId,
      )) {
        await logoutLocally(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.toString());
    }
  }

  static Future<void> confirmUnblock(
    BuildContext context,
    ManagedAuthDevice device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فك حظر الجهاز'),
        content: const Text('هل تريد السماح لهذا الجهاز بالدخول مرة أخرى؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('فك الحظر'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ManagedDevicesProvider>().unblockDevice(device.id);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم فك حظر الجهاز بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.toString());
    }
  }

  static Future<void> confirmLogoutDevice(
    BuildContext context,
    ManagedAuthDevice device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل خروج الجهاز'),
        content: const Text('هل تريد إنهاء الجلسة الحالية لهذا الجهاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل خروج'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final updatedDevice = await context
          .read<ManagedDevicesProvider>()
          .logoutDevice(device.id);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل خروج الجهاز بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (context.read<ManagedDevicesProvider>().isCurrentDevice(
        updatedDevice.deviceId,
      )) {
        await logoutLocally(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.toString());
    }
  }

  static Future<void> logoutLocally(BuildContext context) async {
    await context.read<AuthProvider>().logout(notifyServer: false);
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  static String formatDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }

  static String platformLabel(String value) {
    switch (value) {
      case 'android':
        return 'Android';
      case 'ios':
        return 'iOS';
      case 'desktop':
        return 'Desktop';
      case 'web':
        return 'Web';
      default:
        return value.isEmpty ? 'غير معروف' : value;
    }
  }

  static String loginTypeLabel(String value) {
    switch (value) {
      case 'phone':
        return 'رقم الجوال';
      case 'username':
        return 'اسم المستخدم';
      case 'email':
        return 'البريد الإلكتروني';
      default:
        return value.isEmpty ? '-' : value;
    }
  }
}

class _UserActionHandler {
  const _UserActionHandler._();

  static Future<void> toggleUserBlock(
    BuildContext context, {
    required _ManagedUserEntry entry,
    required bool block,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(block ? 'حظر المستخدم' : 'فك حظر المستخدم'),
        content: Text(
          block
              ? 'سيتم حظر ${entry.displayName} ومنعه من استخدام النظام. هل تريد المتابعة؟'
              : 'سيتم السماح لـ ${entry.displayName} بالدخول إلى النظام مرة أخرى. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: block
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed)
                : null,
            child: Text(block ? 'حظر' : 'فك الحظر'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final devicesProvider = context.read<ManagedDevicesProvider>();
    final activeDeviceIds = entry.activeSessionDevices
        .map((deviceLink) => deviceLink.device.id)
        .toList(growable: false);
    final shouldLogoutCurrentDevice = entry.activeSessionDevices.any(
      (deviceLink) =>
          devicesProvider.isCurrentDevice(deviceLink.device.deviceId),
    );

    try {
      await context.read<UserManagementProvider>().toggleBlock(entry.id, block);
      if (block && activeDeviceIds.isNotEmpty) {
        await devicesProvider.logoutDevices(activeDeviceIds);
      }
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            block
                ? 'تم حظر المستخدم وإسقاط جلساته النشطة'
                : 'تم فك حظر المستخدم بنجاح',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (block && shouldLogoutCurrentDevice) {
        await _DeviceActionHandler.logoutLocally(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.toString());
    }
  }

  static Future<void> logoutUserSessions(
    BuildContext context,
    _ManagedUserEntry entry,
  ) async {
    final activeDevices = entry.activeSessionDevices;
    if (activeDevices.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل خروج المستخدم'),
        content: Text(
          'سيتم إنهاء ${activeDevices.length} جلسة نشطة تخص ${entry.displayName}. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل خروج'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final devicesProvider = context.read<ManagedDevicesProvider>();
    final shouldLogoutCurrentDevice = activeDevices.any(
      (deviceLink) =>
          devicesProvider.isCurrentDevice(deviceLink.device.deviceId),
    );

    try {
      final affectedDevices = await devicesProvider.logoutDevices(
        activeDevices.map((deviceLink) => deviceLink.device.id),
      );
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل خروج $affectedDevices جهاز للمستخدم بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (shouldLogoutCurrentDevice) {
        await _DeviceActionHandler.logoutLocally(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.toString());
    }
  }
}

List<_ManagedUserEntry> _collectManagedUsers(
  List<User> users,
  List<ManagedAuthDevice> devices,
) {
  final builders = <String, _ManagedUserEntryBuilder>{};
  final userIdByEmail = <String, String>{};
  final userIdByUsername = <String, String>{};
  final userIdByPhone = <String, String>{};

  for (final user in users) {
    builders[user.id] = _ManagedUserEntryBuilder.fromSystemUser(user);

    final normalizedEmail = _normalizeLookupEmail(user.email);
    if (normalizedEmail.isNotEmpty) {
      userIdByEmail[normalizedEmail] = user.id;
    }

    final normalizedUsername = _normalizeLookupUsername(user.username);
    if (normalizedUsername.isNotEmpty) {
      userIdByUsername[normalizedUsername] = user.id;
    }

    final normalizedPhone = _normalizeLookupPhone(user.phone ?? '');
    if (normalizedPhone.isNotEmpty) {
      userIdByPhone[normalizedPhone] = user.id;
    }
  }

  for (final device in devices) {
    if (device.currentSessionUser != null) {
      _upsertManagedUser(
        builders,
        device.currentSessionUser!,
      ).attachDevice(device, isSessionOwner: true);
    }

    for (final linkedUser in device.linkedUsers) {
      final linkedUserId = _resolvedManagedUserId(linkedUser);
      final currentSessionUserId = device.currentSessionUser != null
          ? _resolvedManagedUserId(device.currentSessionUser!)
          : '';

      _upsertManagedUser(builders, linkedUser).attachDevice(
        device,
        isSessionOwner:
            currentSessionUserId.isNotEmpty &&
            currentSessionUserId == linkedUserId,
      );
    }

    final resolvedUserId = _resolveSystemUserIdForDevice(
      device,
      builders: builders,
      userIdByEmail: userIdByEmail,
      userIdByUsername: userIdByUsername,
      userIdByPhone: userIdByPhone,
    );

    if (resolvedUserId != null) {
      builders[resolvedUserId]!.attachDevice(
        device,
        isSessionOwner: device.isLoggedIn && device.currentSessionUser == null,
      );
    }
  }

  final entries = builders.values
      .map((builder) => builder.build())
      .toList(growable: false);

  entries.sort((a, b) {
    final blockedCompare = a.isBlocked == b.isBlocked
        ? 0
        : a.isBlocked
        ? 1
        : -1;
    if (blockedCompare != 0) return blockedCompare;

    final activeCompare = b.activeSessionDevices.length.compareTo(
      a.activeSessionDevices.length,
    );
    if (activeCompare != 0) return activeCompare;

    final devicesCompare = b.devices.length.compareTo(a.devices.length);
    if (devicesCompare != 0) return devicesCompare;

    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });

  return entries;
}

String? _resolveSystemUserIdForDevice(
  ManagedAuthDevice device, {
  required Map<String, _ManagedUserEntryBuilder> builders,
  required Map<String, String> userIdByEmail,
  required Map<String, String> userIdByUsername,
  required Map<String, String> userIdByPhone,
}) {
  final matchedUserId = (device.matchedUserId ?? '').trim();
  if (matchedUserId.isNotEmpty && builders.containsKey(matchedUserId)) {
    return matchedUserId;
  }

  final matchedEmail = _normalizeLookupEmail(device.matchedUserEmail ?? '');
  if (matchedEmail.isNotEmpty && userIdByEmail.containsKey(matchedEmail)) {
    return userIdByEmail[matchedEmail];
  }

  final matchedUsername = _normalizeLookupUsername(
    device.matchedUsername ?? '',
  );
  if (matchedUsername.isNotEmpty &&
      userIdByUsername.containsKey(matchedUsername)) {
    return userIdByUsername[matchedUsername];
  }

  final lastIdentifier = device.lastIdentifier;
  switch (device.lastLoginType) {
    case 'email':
      return userIdByEmail[_normalizeLookupEmail(lastIdentifier)];
    case 'username':
      return userIdByUsername[_normalizeLookupUsername(lastIdentifier)];
    case 'phone':
      return userIdByPhone[_normalizeLookupPhone(lastIdentifier)];
    default:
      return null;
  }
}

_ManagedUserEntryBuilder _upsertManagedUser(
  Map<String, _ManagedUserEntryBuilder> builders,
  ManagedDeviceUser user,
) {
  final resolvedId = _resolvedManagedUserId(user);

  return builders.putIfAbsent(
    resolvedId,
    () => _ManagedUserEntryBuilder.fromManagedUser(id: resolvedId, user: user),
  )..mergeManagedUser(user);
}

String _resolvedManagedUserId(ManagedDeviceUser user) {
  if (user.id.trim().isNotEmpty) {
    return user.id.trim();
  }
  return 'virtual:${user.email}:${user.username}:${user.phone}:${user.name}';
}

String _normalizeLookupEmail(String value) {
  return value.trim().toLowerCase();
}

String _normalizeLookupUsername(String value) {
  return value.trim().toLowerCase();
}

String _normalizeLookupPhone(String value) {
  return value.replaceAll(RegExp(r'\s+'), '').trim();
}

class _ManagedUserEntry {
  const _ManagedUserEntry({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.company,
    required this.isBlocked,
    required this.devices,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String role;
  final String company;
  final bool isBlocked;
  final List<_ManagedUserDeviceLink> devices;

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (username.trim().isNotEmpty) return username.trim();
    if (email.trim().isNotEmpty) return email.trim();
    if (phone.trim().isNotEmpty) return phone.trim();
    return 'مستخدم غير معروف';
  }

  bool get hasControllableAccount => !id.startsWith('virtual:');

  List<_ManagedUserDeviceLink> get activeSessionDevices => devices
      .where(
        (deviceLink) =>
            deviceLink.isSessionOwner && deviceLink.device.isLoggedIn,
      )
      .toList(growable: false);
}

class _ManagedUserDeviceLink {
  const _ManagedUserDeviceLink({
    required this.device,
    required this.isSessionOwner,
  });

  final ManagedAuthDevice device;
  final bool isSessionOwner;
}

class _ManagedUserEntryBuilder {
  _ManagedUserEntryBuilder({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.company,
    required this.isBlocked,
  });

  factory _ManagedUserEntryBuilder.fromSystemUser(User user) {
    return _ManagedUserEntryBuilder(
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      phone: user.phone ?? '',
      role: user.role,
      company: user.company,
      isBlocked: user.isBlocked,
    );
  }

  factory _ManagedUserEntryBuilder.fromManagedUser({
    required String id,
    required ManagedDeviceUser user,
  }) {
    return _ManagedUserEntryBuilder(
      id: id,
      name: user.name,
      username: user.username,
      email: user.email,
      phone: user.phone,
      role: user.role,
      company: user.company,
      isBlocked: false,
    );
  }

  final String id;
  final List<_ManagedUserDeviceLink> _devices = [];
  final Set<String> _attachedDeviceIds = <String>{};
  String name;
  String username;
  String email;
  String phone;
  String role;
  String company;
  bool isBlocked;

  void mergeManagedUser(ManagedDeviceUser user) {
    if (name.trim().isEmpty && user.name.trim().isNotEmpty) {
      name = user.name;
    }
    if (username.trim().isEmpty && user.username.trim().isNotEmpty) {
      username = user.username;
    }
    if (email.trim().isEmpty && user.email.trim().isNotEmpty) {
      email = user.email;
    }
    if (phone.trim().isEmpty && user.phone.trim().isNotEmpty) {
      phone = user.phone;
    }
    if (role.trim().isEmpty && user.role.trim().isNotEmpty) {
      role = user.role;
    }
    if (company.trim().isEmpty && user.company.trim().isNotEmpty) {
      company = user.company;
    }
  }

  void attachDevice(ManagedAuthDevice device, {required bool isSessionOwner}) {
    if (_attachedDeviceIds.contains(device.id)) {
      final index = _devices.indexWhere(
        (entry) => entry.device.id == device.id,
      );
      if (index >= 0 && isSessionOwner && !_devices[index].isSessionOwner) {
        _devices[index] = _ManagedUserDeviceLink(
          device: device,
          isSessionOwner: true,
        );
      }
      return;
    }

    _attachedDeviceIds.add(device.id);
    _devices.add(
      _ManagedUserDeviceLink(device: device, isSessionOwner: isSessionOwner),
    );
  }

  _ManagedUserEntry build() {
    final devices = List<_ManagedUserDeviceLink>.from(_devices)
      ..sort((a, b) {
        final sessionCompare = a.isSessionOwner == b.isSessionOwner
            ? 0
            : a.isSessionOwner
            ? -1
            : 1;
        if (sessionCompare != 0) return sessionCompare;

        final activeCompare = a.device.isLoggedIn == b.device.isLoggedIn
            ? 0
            : a.device.isLoggedIn
            ? -1
            : 1;
        if (activeCompare != 0) return activeCompare;

        return a.device.displayName.toLowerCase().compareTo(
          b.device.displayName.toLowerCase(),
        );
      });

    return _ManagedUserEntry(
      id: id,
      name: name,
      username: username,
      email: email,
      phone: phone,
      role: role,
      company: company,
      isBlocked: isBlocked,
      devices: devices,
    );
  }
}

void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.errorRed,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
