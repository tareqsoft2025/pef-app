import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/attendance_service.dart';
import '../services/location_service.dart';
import '../services/msg_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'attendance_history_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'task_screen.dart';
import 'task_history_screen.dart';
import 'profile_screen.dart';
import 'leave_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final String employeeName;
  final String employeeId;

  const WelcomeScreen({
    super.key,
    required this.employeeName,
    required this.employeeId,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Timer _clockTimer;
  Timer? _pollTimer;
  DateTime _now = DateTime.now();
  String _location = 'جاري تحديد الموقع...';
  bool _locationReady = false;
  bool _isRecording = false;
  bool _isRefreshing = false;
  bool _checkingStatus = true;
  bool _checkedInToday = false;
  bool _checkedOutToday = false;
  int _newNotifCount = 0;
  int _newMsgCount = 0;
  int _lastKnownMsgCount = 0;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _fetchLocation();
    _checkTodayStatus();
    _loadNotifCount();
    _loadMsgCount();
    _checkDailyGreeting();
    _startPolling();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── فحص الرسائل تلقائياً كل 45 ثانية ─────────────────
  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      final newCount = await MsgService.getUnseenCount(widget.employeeId);
      if (!mounted) return;
      if (newCount > _lastKnownMsgCount) {
        _showNewMessageBanner();
        setState(() {
          _newMsgCount = newCount;
          _lastKnownMsgCount = newCount;
        });
      } else {
        setState(() => _newMsgCount = newCount);
      }
      // تحديث الإشعارات أيضاً
      final notifCount = await NotificationService.getUnseenCount();
      if (mounted) setState(() => _newNotifCount = notifCount);
    });
  }

  void _showNewMessageBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MessagesScreen(
                  employeeId: widget.employeeId,
                  employeeName: widget.employeeName,
                ),
              ),
            ).then((_) => _loadMsgCount());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mail_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('رسالة جديدة من HR',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Text('اضغط للعرض',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── تحديث شامل ────────────────────────────────────────
  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future.wait([
      _checkTodayStatus(),
      _loadNotifCount(),
      _loadMsgCountSilent(),
    ]);
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _loadMsgCountSilent() async {
    final newCount = await MsgService.getUnseenCount(widget.employeeId);
    if (!mounted) return;
    final hadNew = newCount > _lastKnownMsgCount;
    setState(() => _newMsgCount = newCount);
    if (hadNew) {
      _lastKnownMsgCount = newCount;
      _showNewMessageBanner();
    }
  }

  // ── جلب الموقع ─────────────────────────────────────────
  Future<void> _fetchLocation() async {
    final loc = await LocationService.getLocation();
    if (mounted) setState(() { _location = loc; _locationReady = true; });
  }

  // ── التحقق من حضور اليوم ───────────────────────────────
  Future<void> _checkTodayStatus() async {
    setState(() => _checkingStatus = true);
    final status = await AttendanceService.getTodayStatus(widget.employeeId);
    if (mounted) {
      setState(() {
        _checkedInToday = status.checkedIn;
        _checkedOutToday = status.checkedOut;
        _checkingStatus = false;
      });
    }
  }

  Future<void> _loadNotifCount() async {
    final c = await NotificationService.getUnseenCount();
    if (mounted) setState(() => _newNotifCount = c);
  }

  Future<void> _loadMsgCount() async {
    final c = await MsgService.getUnseenCount(widget.employeeId);
    if (mounted) {
      setState(() {
        _newMsgCount = c;
        _lastKnownMsgCount = c;
      });
    }
  }

  // ── رسالة الترحيب اليومية ──────────────────────────────
  Future<void> _checkDailyGreeting() async {
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final today = '${_now.day}_${_now.month}_${_now.year}';
    final key = 'last_greeting_${widget.employeeId}';
    if (prefs.getString(key) == today) return;
    await prefs.setString(key, today);
    if (mounted) _showGreetingDialog();
  }

  String get _greetingText {
    final h = _now.hour;
    if (h >= 5 && h < 12) return 'صباح الخير';
    if (h >= 12 && h < 18) return 'مساء الخير';
    return 'مساء النور';
  }

  String get _greetingIcon {
    final h = _now.hour;
    if (h >= 5 && h < 12) return '☀️';
    if (h >= 12 && h < 18) return '🌤️';
    return '🌙';
  }

  void _showGreetingDialog() {
    final name = widget.employeeName.isNotEmpty
        ? widget.employeeName
        : 'الموظف الكريم';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // رأس الديالوج
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D1B4B), Color(0xFF1565C0)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 66, height: 66,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.eco_rounded,
                        color: Colors.green.shade300, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text('PEF',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5)),
                  const SizedBox(height: 4),
                  Text('جمعية أصدقاء البيئة',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  Text('قسم الموارد البشرية',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55), fontSize: 11)),
                ],
              ),
            ),
            // محتوى الديالوج
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                children: [
                  Text('$_greetingText $_greetingIcon',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E))),
                  const SizedBox(height: 8),
                  Text(name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D47A1))),
                  const SizedBox(height: 6),
                  Text(_formatDateArabic(_now),
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'نتمنى لك يوماً مثمراً ومليئاً بالإنجازات',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2E7D32),
                          height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('حسناً',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().scale(
            begin: const Offset(0.85, 0.85),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  // ── تسجيل الحضور / الانصراف ────────────────────────────
  Future<void> _record(String type) async {
    if (_isRecording) return;
    setState(() => _isRecording = true);

    final date = _fmtDate(_now);
    final time = _fmtTime(_now);

    final sent = await AttendanceService.record(
      username: widget.employeeId,
      name: widget.employeeName,
      date: date, time: time,
      location: _location, type: type,
    );

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      if (type == 'حضور') _checkedInToday = true;
      if (type == 'انصراف') _checkedOutToday = true;
    });
    _showResult(type, date, time, sent);
  }

  void _showResult(String type, String date, String time, bool synced) {
    final isIn = type == 'حضور';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: (isIn
                          ? const Color(0xFF43A047)
                          : const Color(0xFFE53935))
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIn
                      ? Icons.check_circle_rounded
                      : Icons.exit_to_app_rounded,
                  size: 42,
                  color: isIn
                      ? const Color(0xFF43A047)
                      : const Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 16),
              Text('تم تسجيل $type بنجاح',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isIn
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828))),
              const SizedBox(height: 14),
              _infoRow(Icons.badge_outlined, widget.employeeName),
              _infoRow(Icons.calendar_today_outlined, date),
              _infoRow(Icons.access_time_rounded, time),
              _infoRow(Icons.location_on_outlined, _location),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    synced
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    size: 14,
                    color: synced ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    synced ? 'تمت المزامنة' : 'تحقق من الاتصال',
                    style: TextStyle(
                        fontSize: 12,
                        color: synced ? Colors.green : Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIn
                        ? const Color(0xFF43A047)
                        : const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('حسناً',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF333333)),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  // ── تسجيل الخروج ───────────────────────────────────────
  Future<void> _logout() async {
    await StorageService.clearCredentials();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.employeeName.isNotEmpty
        ? widget.employeeName
        : 'الموظف الكريم';

    return Scaffold(
      body: Column(
        children: [
          // ══ القسم العلوي (Gradient) ══════════════════════
          Container(
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
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 22),
                child: Column(
                  children: [
                    // ─── شريط الرأس ─────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Icon(Icons.eco_rounded,
                              color: Colors.green.shade300, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PEF',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3)),
                            Text('جمعية أصدقاء البيئة',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.72),
                                    fontSize: 11)),
                            Text('قسم الموارد البشرية',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 9.5)),
                          ],
                        ),
                        const Spacer(),
                        // زر التحديث
                        _isRefreshing
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white54, strokeWidth: 2),
                              )
                            : IconButton(
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh_rounded,
                                    color: Colors.white54, size: 20),
                                tooltip: 'تحديث',
                              ),
                        _BadgeButton(
                          icon: Icons.mail_rounded,
                          count: _newMsgCount,
                          badgeColor: const Color(0xFF42A5F5),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MessagesScreen(
                                employeeId: widget.employeeId,
                                employeeName: widget.employeeName,
                              ),
                            ),
                          ).then((_) => _loadMsgCount()),
                        ),
                        _BadgeButton(
                          icon: Icons.notifications_rounded,
                          count: _newNotifCount,
                          badgeColor: Colors.redAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen()),
                          ).then((_) => _loadNotifCount()),
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.white38, size: 20),
                          tooltip: 'تسجيل الخروج',
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: 18),

                    // ─── بطاقة الموظف ────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.14)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                Text('هوية: ${widget.employeeId}',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.55),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _locationReady
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _locationReady
                                    ? Colors.green.withOpacity(0.4)
                                    : Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _locationReady
                                      ? Icons.gps_fixed_rounded
                                      : Icons.location_searching_rounded,
                                  size: 12,
                                  color: _locationReady
                                      ? Colors.green.shade300
                                      : Colors.white38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _locationReady ? 'GPS ✓' : '...',
                                  style: TextStyle(
                                      color: _locationReady
                                          ? Colors.green.shade300
                                          : Colors.white38,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 22),

                    // ─── الساعة الحية ────────────────────
                    Text(
                      _fmtTime(_now),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 58,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 4,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    Text(
                      _formatDateArabic(_now),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13,
                          letterSpacing: 0.3),
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // ══ القسم السفلي (أبيض) ═════════════════════════
          Expanded(
            child: Container(
              color: const Color(0xFFF4F6FB),
              child: _checkingStatus
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF0D47A1), strokeWidth: 2.5))
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      color: const Color(0xFF0D47A1),
                      child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // ─ شارات الحالة ──────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _StatusBadge(
                                  label: 'الحضور',
                                  done: _checkedInToday,
                                  color: const Color(0xFF43A047),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatusBadge(
                                  label: 'الانصراف',
                                  done: _checkedOutToday,
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 100.ms),

                          const SizedBox(height: 14),

                          // ─ زرّا الحضور والانصراف ─────────
                          Row(
                            children: [
                              Expanded(
                                child: _AttendanceButton(
                                  label: 'تسجيل الحضور',
                                  icon: Icons.login_rounded,
                                  color: const Color(0xFF2E7D32),
                                  lightColor: const Color(0xFF43A047),
                                  isLoading: _isRecording,
                                  isDone: _checkedInToday,
                                  onTap: _checkedInToday
                                      ? null
                                      : () => _record('حضور'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _AttendanceButton(
                                  label: 'تسجيل الانصراف',
                                  icon: Icons.logout_rounded,
                                  color: const Color(0xFFC62828),
                                  lightColor: const Color(0xFFE53935),
                                  isLoading: _isRecording,
                                  isDone: _checkedOutToday,
                                  onTap: _checkedOutToday
                                      ? null
                                      : () => _record('انصراف'),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                          const SizedBox(height: 22),

                          // ─ فاصل الخدمات ──────────────────
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                                child: Text('الخدمات',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5)),
                              ),
                              Expanded(
                                  child: Divider(color: Colors.grey.shade300)),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ─ شبكة الخدمات ──────────────────
                          GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1.6,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: [
                              _FeatureCard(
                                icon: Icons.person_pin_outlined,
                                label: 'بياناتي',
                                sublabel: 'الملف الوظيفي الكامل',
                                color: const Color(0xFF0277BD),
                                bgColor: const Color(0xFFE1F5FE),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(
                                      nationalId: widget.employeeId,
                                      employeeName: widget.employeeName,
                                    ),
                                  ),
                                ),
                              ),
                              _FeatureCard(
                                icon: Icons.history_rounded,
                                label: 'سجل الحضور',
                                sublabel: 'الحضور والانصراف',
                                color: const Color(0xFF2E7D32),
                                bgColor: const Color(0xFFE8F5E9),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AttendanceHistoryScreen(
                                      employeeId: widget.employeeId,
                                      employeeName: widget.employeeName,
                                    ),
                                  ),
                                ),
                              ),
                              _FeatureCard(
                                icon: Icons.assignment_rounded,
                                label: 'تسجيل مهمة',
                                sublabel: 'رسمية أو خاصة',
                                color: const Color(0xFF1565C0),
                                bgColor: const Color(0xFFE3F2FD),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TaskScreen(
                                      employeeId: widget.employeeId,
                                      employeeName: widget.employeeName,
                                    ),
                                  ),
                                ),
                              ),
                              _FeatureCard(
                                icon: Icons.task_alt_rounded,
                                label: 'سجل المهام',
                                sublabel: 'المهام السابقة',
                                color: const Color(0xFF558B2F),
                                bgColor: const Color(0xFFF1F8E9),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TaskHistoryScreen(
                                      employeeId: widget.employeeId,
                                      employeeName: widget.employeeName,
                                    ),
                                  ),
                                ),
                              ),
                              _FeatureCard(
                                icon: Icons.mail_rounded,
                                label: 'رسائل HR',
                                sublabel: 'من إدارة الموارد البشرية',
                                color: const Color(0xFF6A1B9A),
                                bgColor: const Color(0xFFF3E5F5),
                                badge: _newMsgCount,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MessagesScreen(
                                      employeeId: widget.employeeId,
                                      employeeName: widget.employeeName,
                                    ),
                                  ),
                                ).then((_) => _loadMsgCount()),
                              ),
                              _FeatureCard(
                                icon: Icons.notifications_rounded,
                                label: 'الإشعارات',
                                sublabel: 'آخر الأخبار والتنبيهات',
                                color: const Color(0xFFE65100),
                                bgColor: const Color(0xFFFFF3E0),
                                badge: _newNotifCount,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen()),
                                ).then((_) => _loadNotifCount()),
                              ),
                              _FeatureCard(
                                icon: Icons.beach_access_rounded,
                                label: 'رصيد الإجازات',
                                sublabel: '14 يوم سنوياً',
                                color: const Color(0xFF00695C),
                                bgColor: const Color(0xFFE0F2F1),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LeaveScreen(
                                      nationalId: widget.employeeId,
                                      employeeName: widget.employeeName,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 300.ms),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _formatDateArabic(DateTime dt) {
    const days = [
      'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
      'الجمعة', 'السبت', 'الأحد'
    ];
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${days[dt.weekday - 1]}  ${dt.day}  ${months[dt.month - 1]}  ${dt.year}';
  }
}

// ══ بطاقة خدمة ══════════════════════════════════════════════
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color, bgColor;
  final int badge;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 9),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                  Text(sublabel,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
              if (badge > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 20, height: 20,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

// ══ زر Badge ════════════════════════════════════════════════
class _BadgeButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color badgeColor;
  final VoidCallback onTap;

  const _BadgeButton({
    required this.icon,
    required this.count,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            if (count > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                      color: badgeColor, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

// ══ شارة حالة الحضور ════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String label;
  final bool done;
  final Color color;

  const _StatusBadge(
      {required this.label, required this.done, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: done ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done ? color.withOpacity(0.35) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 15,
              color: done ? color : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              done ? 'تم $label' : '$label غير مسجّل',
              style: TextStyle(
                fontSize: 12,
                color: done ? color : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

// ══ زر الحضور / الانصراف ════════════════════════════════════
class _AttendanceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, lightColor;
  final bool isLoading, isDone;
  final VoidCallback? onTap;

  const _AttendanceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.lightColor,
    required this.isLoading,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 115,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDone
                  ? [color.withOpacity(0.2), lightColor.withOpacity(0.15)]
                  : [color, lightColor],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDone
                ? []
                : [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading && !isDone)
                const SizedBox(
                  width: 30, height: 30,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              else
                Icon(
                  isDone ? Icons.check_circle_rounded : icon,
                  color: isDone ? Colors.white60 : Colors.white,
                  size: 34,
                ),
              const SizedBox(height: 8),
              Text(
                isDone ? 'تم التسجيل ✓' : label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDone ? Colors.white60 : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
}
