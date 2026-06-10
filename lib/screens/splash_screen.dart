import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final saved = await StorageService.loadCredentials();
    if (saved == null) {
      _goLogin(null);
      return;
    }

    final response = await AuthService.login(saved.username, saved.password);
    if (!mounted) return;

    switch (response.status) {
      case AuthStatus.success:
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, a, __) => WelcomeScreen(
              employeeName: response.employeeName,
              employeeId: saved.username,
            ),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      case AuthStatus.wrongCredentials:
        await StorageService.clearCredentials();
        _goLogin('انتهت صلاحية بيانات الدخول المحفوظة');
      case AuthStatus.networkError:
        _goLogin('تعذّر الاتصال — يرجى تسجيل الدخول يدوياً');
    }
  }

  void _goLogin(String? message) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => LoginScreen(initialMessage: message),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.4), width: 2),
              ),
              child: Icon(
                Icons.eco_rounded,
                size: 56,
                color: Colors.green.shade300,
              ),
            )
                .animate()
                .fadeIn(duration: 700.ms)
                .scale(begin: const Offset(0.4, 0.4)),
            const SizedBox(height: 28),
            const Text(
              'PEF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              'جمعية أصدقاء البيئة',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 16),
            ).animate().fadeIn(delay: 380.ms, duration: 600.ms),
            const SizedBox(height: 4),
            Text(
              'قسم الموارد البشرية',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 13),
            ).animate().fadeIn(delay: 450.ms, duration: 600.ms),
            const SizedBox(height: 6),
            Text(
              'نظام الحضور والانصراف',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11),
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
            const SizedBox(height: 64),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2.5,
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
