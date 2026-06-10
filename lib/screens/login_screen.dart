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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(widget.initialMessage!, Colors.orange);
      });
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

    LogService.logAttempt(
      username: username,
      location: location,
      success: isSuccess,
    );

    switch (response.status) {
      case AuthStatus.success:
        if (_rememberMe) {
          await StorageService.saveCredentials(
            username: username,
            password: password,
            name: response.employeeName,
          );
        } else {
          await StorageService.clearCredentials();
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => WelcomeScreen(
              employeeName: response.employeeName,
              employeeId: username,
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      case AuthStatus.wrongCredentials:
        _showSnackBar('رقم الهوية أو كلمة المرور غير صحيحة', Colors.redAccent);
      case AuthStatus.networkError:
        _showSnackBar('تعذّر الاتصال، تحقق من الإنترنت', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF071235),
              Color(0xFF0D2B6B),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.07),

                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.eco_rounded,
                    size: 50,
                    color: Colors.green.shade300,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 700.ms)
                    .scale(begin: const Offset(0.4, 0.4)),

                const SizedBox(height: 18),

                const Text(
                  'PEF',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 5,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 4),

                Text(
                  'جمعية أصدقاء البيئة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ).animate().fadeIn(delay: 270.ms, duration: 600.ms),

                Text(
                  'قسم الموارد البشرية',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ).animate().fadeIn(delay: 320.ms, duration: 600.ms),

                const SizedBox(height: 18),

                const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 380.ms, duration: 600.ms)
                    .slideY(begin: -0.3),

                const SizedBox(height: 5),

                Text(
                  'أدخل رقم الهوية وكلمة المرور للمتابعة',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ).animate().fadeIn(delay: 420.ms, duration: 600.ms),

                SizedBox(height: size.height * 0.055),

                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 35,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLabel('رقم الهوية'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _idController,
                          keyboardType: TextInputType.number,
                          maxLength: 9,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                            color: Color(0xFF1A237E),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          decoration: _inputDecoration(
                            hint: '_ _ _ _ _ _ _ _ _',
                            icon: Icons.badge_outlined,
                          ).copyWith(
                            counterText: '',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 20,
                              letterSpacing: 4,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال رقم الهوية';
                            }
                            if (value.length != 9) {
                              return 'رقم الهوية يجب أن يكون 9 أرقام';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 22),

                        _buildLabel('كلمة المرور'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textDirection: TextDirection.ltr,
                          decoration: _inputDecoration(
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF0D47A1),
                                size: 22,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال كلمة المرور';
                            }
                            if (value.length < 4) {
                              return 'كلمة المرور قصيرة جداً';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ── تذكرني ──────────────────────────
                        GestureDetector(
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _rememberMe
                                      ? const Color(0xFF0D47A1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _rememberMe
                                        ? const Color(0xFF0D47A1)
                                        : Colors.grey.shade400,
                                    width: 1.8,
                                  ),
                                ),
                                child: _rememberMe
                                    ? const Icon(Icons.check,
                                        size: 15, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'تذكرني — لا تطلب تسجيل الدخول مجدداً',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF0D47A1).withOpacity(0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded, size: 22),
                                      SizedBox(width: 10),
                                      Text(
                                        'دخول',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 700.ms)
                    .slideY(begin: 0.25),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 16, color: Colors.white.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text(
                      'بيانات محمية ومشفّرة',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF333333),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF0D47A1), size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF4F6FF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFF3949AB), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }
}
