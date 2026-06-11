import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';
import 'welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? initialMessage;
  const LoginScreen({super.key, this.initialMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _loadSavedCredentials();
    if (widget.initialMessage != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showSnackBar(widget.initialMessage!, Colors.orange));
    }
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await StorageService.loadCredentials();
    if (saved != null && mounted) {
      setState(() {
        _idController.text = saved.username;
        _passwordController.text = saved.password;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final username = _idController.text.trim();
    final password = _passwordController.text.trim();
    final results = await Future.wait([
      AuthService.login(username, password),
      LocationService.getLocation(),
    ]);
    if (!mounted) return;
    setState(() => _isLoading = false);
    final response = results[0] as LoginResponse;
    final location = results[1] as String;
    final isSuccess = response.status == AuthStatus.success;
    LogService.logAttempt(username: username, location: location, success: isSuccess);
    switch (response.status) {
      case AuthStatus.success:
        if (_rememberMe) {
          await StorageService.saveCredentials(
              username: username, password: password, name: response.employeeName);
        } else {
          await StorageService.clearCredentials();
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, animation, __) =>
              WelcomeScreen(employeeName: response.employeeName, employeeId: username),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ));
      case AuthStatus.wrongCredentials:
        _showSnackBar('رقم الهوية أو كلمة المرور غير صحيحة', const Color(0xFFEF5350));
      case AuthStatus.networkError:
        _showSnackBar('تعذّر الاتصال، تحقق من الإنترنت', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── خلفية متدرجة ──────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Color(0xFF040D1E),
                      Color(0xFF07163A),
                      Color(0xFF0B2060),
                    ],
                    stops: [
                      0,
                      0.4 + _bgController.value * 0.2,
                      1,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── دوائر زخرفية ──────────────────────────────────
          Positioned(
            top: -size.height * 0.12,
            right: -size.width * 0.22,
            child: _GlowCircle(size: size.width * 0.75,
                color: const Color(0xFF1565C0).withOpacity(0.18)),
          ),
          Positioned(
            bottom: size.height * 0.1,
            left: -size.width * 0.28,
            child: _GlowCircle(size: size.width * 0.65,
                color: const Color(0xFF0D47A1).withOpacity(0.15)),
          ),
          Positioned(
            top: size.height * 0.35,
            left: size.width * 0.55,
            child: _GlowCircle(size: size.width * 0.3,
                color: const Color(0xFF42A5F5).withOpacity(0.10)),
          ),

          // ── المحتوى ────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.065),

                  // شعار PEF
                  _buildLogo().animate()
                      .fadeIn(duration: 700.ms)
                      .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack),

                  SizedBox(height: size.height * 0.05),

                  // بطاقة تسجيل الدخول
                  _buildCard().animate()
                      .fadeIn(delay: 350.ms, duration: 700.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                  const SizedBox(height: 28),

                  // تذييل
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 15, color: Colors.white.withOpacity(0.45)),
                      const SizedBox(width: 7),
                      Text('بيانات محمية ومشفّرة',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 12.5)),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() => Column(
        children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
              ),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.55),
                    blurRadius: 32,
                    offset: const Offset(0, 8)),
                BoxShadow(
                    color: const Color(0xFF42A5F5).withOpacity(0.25),
                    blurRadius: 60,
                    spreadRadius: 8),
              ],
              border: Border.all(
                  color: Colors.white.withOpacity(0.25), width: 1.5),
            ),
            child: Icon(Icons.eco_rounded,
                size: 42, color: Colors.green.shade300),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFBBDEFB)],
            ).createShader(bounds),
            child: const Text('PEF',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 8)),
          ),
          const SizedBox(height: 5),
          Text('جمعية أصدقاء البيئة',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75), fontSize: 13.5)),
          const SizedBox(height: 2),
          Text('نظام إدارة الموارد البشرية',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ],
      );

  Widget _buildCard() => Container(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.2),
                blurRadius: 50,
                offset: const Offset(0, 20)),
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 80,
                offset: const Offset(0, 30)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // عنوان البطاقة
              Row(
                children: [
                  Container(
                    width: 4, height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تسجيل الدخول',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0A1628))),
                      Text('أدخل بياناتك للمتابعة',
                          style: TextStyle(
                              fontSize: 11.5, color: Color(0xFF9EA3B0))),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // حقل رقم الهوية
              _FieldLabel(label: 'رقم الهوية الوطنية'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _idController,
                keyboardType: TextInputType.number,
                maxLength: 9,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: Color(0xFF0D47A1)),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: _buildInputDecoration(
                  hint: '_ _ _ _ _ _ _ _ _',
                  icon: Icons.badge_rounded,
                ).copyWith(
                  counterText: '',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 22,
                      letterSpacing: 6),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'يرجى إدخال رقم الهوية';
                  if (v.length != 9) return 'رقم الهوية يجب أن يكون 9 أرقام';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // حقل كلمة المرور
              _FieldLabel(label: 'كلمة المرور'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textDirection: TextDirection.ltr,
                decoration: _buildInputDecoration(
                  hint: '••••••••',
                  icon: Icons.lock_rounded,
                  suffix: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF1565C0),
                        size: 21,
                      ),
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'يرجى إدخال كلمة المرور';
                  if (v.length < 4) return 'كلمة المرور قصيرة جداً';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // تذكرني
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        gradient: _rememberMe
                            ? const LinearGradient(
                                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)])
                            : null,
                        color: _rememberMe ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _rememberMe
                                ? const Color(0xFF1565C0)
                                : Colors.grey.shade300,
                            width: 1.8),
                      ),
                      child: _rememberMe
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text('تذكرني — لا تطلب تسجيل الدخول مجدداً',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade500)),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // زر الدخول
              GestureDetector(
                onTap: _isLoading ? null : _handleLogin,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [const Color(0xFF1565C0).withOpacity(0.5),
                             const Color(0xFF42A5F5).withOpacity(0.5)]
                          : const [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8)),
                          ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login_rounded,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text('دخول',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F8FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade100, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF1565C0), width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF5350))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFEF5350), width: 1.8)),
      );
}

// ── عنوان الحقل ───────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) => Text(label,
      textAlign: TextAlign.right,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2D3748)));
}

// ── دائرة توهج ────────────────────────────────────────────────
class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
