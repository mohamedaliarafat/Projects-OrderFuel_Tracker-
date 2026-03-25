import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:order_tracker/utils/app_routes.dart';
import 'package:order_tracker/utils/constants.dart';
import 'package:order_tracker/utils/role_route_policy.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';

enum LoginIdentifierType { phone, username, email }

extension on LoginIdentifierType {
  String get apiValue {
    switch (this) {
      case LoginIdentifierType.phone:
        return 'phone';
      case LoginIdentifierType.username:
        return 'username';
      case LoginIdentifierType.email:
        return 'email';
    }
  }

  String get label {
    switch (this) {
      case LoginIdentifierType.phone:
        return 'رقم الجوال';
      case LoginIdentifierType.username:
        return 'اسم المستخدم';
      case LoginIdentifierType.email:
        return 'البريد الإلكتروني';
    }
  }

  String get helperText {
    switch (this) {
      case LoginIdentifierType.phone:
        return 'سيصل رمز التحقق إلى البريد المسجل لهذا الجوال';
      case LoginIdentifierType.username:
        return 'سيصل رمز التحقق إلى البريد المرتبط باسم المستخدم';
      case LoginIdentifierType.email:
        return 'سيصل رمز التحقق إلى نفس البريد الإلكتروني';
    }
  }

  IconData get icon {
    switch (this) {
      case LoginIdentifierType.phone:
        return Icons.phone_android_outlined;
      case LoginIdentifierType.username:
        return Icons.alternate_email;
      case LoginIdentifierType.email:
        return Icons.email_outlined;
    }
  }

  TextInputType get keyboardType {
    switch (this) {
      case LoginIdentifierType.phone:
        return TextInputType.phone;
      case LoginIdentifierType.username:
        return TextInputType.text;
      case LoginIdentifierType.email:
        return TextInputType.emailAddress;
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierFormKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  VideoPlayerController? _videoController;
  LoginIdentifierType _selectedType = LoginIdentifierType.phone;
  bool _otpStep = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(
          const Duration(milliseconds: 450),
          _initializeBackgroundVideo,
        );
      });
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeBackgroundVideo() async {
    if (!mounted || _videoController != null) return;

    final controller = VideoPlayerController.asset('assets/videos/v1.mp4');
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
      });
    } catch (_) {
      await controller.dispose();
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (context.read<AuthProvider>().isLoading) return;

    if (_otpStep) {
      await _verifyOtp();
      return;
    }
    await _requestOtp();
  }

  Future<void> _requestOtp() async {
    if (!_identifierFormKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.requestLoginOtp(
      loginType: _selectedType.apiValue,
      identifier: _identifierController.text.trim(),
    );

    if (!mounted) return;

    if (!success) {
      _showError(authProvider.error ?? 'تعذر إرسال رمز التحقق');
      return;
    }

    setState(() {
      _otpStep = true;
      _clearOtpFields();
    });

    _otpFocusNodes.first.requestFocus();

    final maskedEmail = authProvider.pendingMaskedEmail;
    if (maskedEmail != null && maskedEmail.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرسال رمز التحقق إلى $maskedEmail'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _currentOtp();
    if (otp.length != 6) {
      _showError('أدخل رمز تحقق مكوناً من 6 أرقام');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyLoginOtp(otp);

    if (!mounted) return;

    if (!success) {
      _showError(authProvider.error ?? 'فشل التحقق من الرمز');
      return;
    }

    final pendingRoute = authProvider.consumePendingRoute();
    if (pendingRoute != null &&
        pendingRoute.trim().isNotEmpty &&
        isRouteAllowedForRole(
          role: authProvider.role,
          routeName: pendingRoute,
        )) {
      Navigator.pushNamedAndRemoveUntil(context, pendingRoute, (_) => false);
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      _homeRouteByRole(authProvider.role),
      (_) => false,
    );
  }

  void _resetOtpFlow() {
    context.read<AuthProvider>().cancelPendingOtp();
    setState(() {
      _otpStep = false;
      _clearOtpFields();
    });
  }

  void _clearOtpFields() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
  }

  String _currentOtp() {
    return _otpControllers.map((controller) => controller.text.trim()).join();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateIdentifier(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'هذا الحقل مطلوب';
    }

    switch (_selectedType) {
      case LoginIdentifierType.phone:
        return input.length < 8 ? 'رقم الجوال غير صحيح' : null;
      case LoginIdentifierType.username:
        return input.contains(' ')
            ? 'اسم المستخدم لا يجب أن يحتوي على مسافات'
            : null;
      case LoginIdentifierType.email:
        return input.contains('@') ? null : 'البريد الإلكتروني غير صالح';
    }
  }

  void _handleOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String _homeRouteByRole(String? role) {
    switch (role) {
      case 'station_boy':
        return AppRoutes.sessionsList;
      case 'maintenance':
      case 'maintenance_car_management':
        return AppRoutes.maintenanceDashboard;
      case 'maintenance_station':
        return AppRoutes.stationMaintenanceTechnician;
      case 'employee':
        return AppRoutes.marketingStations;
      case 'finance_manager':
        return AppRoutes.custodyDocuments;
      case 'sales_manager_statiun':
      case 'owner_station':
        return AppRoutes.mainHome;
      case 'driver':
        return AppRoutes.driverHome;
      default:
        return AppRoutes.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final maskedEmail = authProvider.pendingMaskedEmail;
    final videoController = _videoController;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child:
                videoController != null && videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoController.value.size.width,
                      height: videoController.value.size.height,
                      child: VideoPlayer(videoController),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryDarkBlue,
                          Color(0xFF162C7A),
                          AppColors.primaryBlue,
                        ],
                      ),
                    ),
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  AppColors.primaryDarkBlue.withOpacity(0.85),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: size.width > 500 ? 470 : size.width,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: 'logo',
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 180,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppStrings.login,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _otpStep
                              ? 'أدخل رمز التحقق المكون من 6 أرقام لإكمال الدخول'
                              : 'اختر طريقة الدخول ثم أرسل رمز التحقق إلى البريد المسجل',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildMethodSelector(),
                        const SizedBox(height: 18),
                        Text(
                          _selectedType.helperText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _otpStep
                              ? _buildOtpSection(maskedEmail)
                              : _buildIdentifierSection(),
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : _handlePrimaryAction,
                          text: authProvider.isLoading
                              ? 'جاري التحميل...'
                              : _otpStep
                              ? 'تحقق من الرمز'
                              : 'إرسال رمز التحقق',
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              Colors.blue.shade300,
                            ],
                          ),
                          isLoading: authProvider.isLoading,
                          width: double.infinity,
                          height: 54,
                        ),
                        const SizedBox(height: 14),
                        if (_otpStep)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _requestOtp,
                                child: const Text(
                                  'إعادة إرسال الرمز',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              TextButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _resetOtpFlow,
                                child: const Text(
                                  'تغيير طريقة الدخول',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        Text(
                          'شركة البحيرة العربية © 2026',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: LoginIdentifierType.values.map((type) {
        final selected = _selectedType == type;
        return ChoiceChip(
          showCheckmark: false,
          label: Text(type.label),
          avatar: Icon(
            type.icon,
            size: 18,
            color: selected ? Colors.white : AppColors.primaryDarkBlue,
          ),
          selected: selected,
          selectedColor: AppColors.primaryDarkBlue,
          backgroundColor: Colors.white.withOpacity(0.96),
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.primaryDarkBlue,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: selected
                ? AppColors.primaryDarkBlue
                : Colors.white.withOpacity(0.7),
          ),
          onSelected: (_) {
            if (_selectedType == type) return;
            setState(() {
              _selectedType = type;
              _identifierController.clear();
              _otpStep = false;
              _clearOtpFields();
            });
            context.read<AuthProvider>().cancelPendingOtp();
          },
        );
      }).toList(),
    );
  }

  Widget _buildIdentifierSection() {
    return Form(
      key: _identifierFormKey,
      child: Column(
        key: const ValueKey<String>('identifier'),
        children: [
          CustomTextField(
            controller: _identifierController,
            labelText: _selectedType.label,
            prefixIcon: _selectedType.icon,
            keyboardType: _selectedType.keyboardType,
            textInputAction: TextInputAction.done,
            validator: _validateIdentifier,
            onFieldSubmitted: (_) => _handlePrimaryAction(),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection(String? maskedEmail) {
    return Column(
      key: const ValueKey<String>('otp'),
      children: [
        if (maskedEmail != null && maskedEmail.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم إرسال الرمز إلى $maskedEmail',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(6, _buildOtpBox),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    final isLastBox = index == _otpControllers.length - 1;

    return SizedBox(
      width: 48,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textInputAction: isLastBox
            ? TextInputAction.done
            : TextInputAction.next,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDarkBlue,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withOpacity(0.94),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) => _handleOtpChanged(index, value),
        onFieldSubmitted: (_) {
          if (!isLastBox) {
            _otpFocusNodes[index + 1].requestFocus();
            return;
          }
          _handlePrimaryAction();
        },
      ),
    );
  }
}
