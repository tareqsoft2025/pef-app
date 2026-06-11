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
  bool _fetchingLocation = false;
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
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
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

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted) return;
      final newCount = await MsgService.getUnseenCount(widget.employeeId);
      if (!mounted) return;
      if (newCount > _lastKnownMsgCount) {
        _showNewMessageBanner();
        setState(() { _newMsgCount = newCount; _lastKnownMsgCount = newCount; });
      } else {
        setState(() => _newMsgCount = newCount);
      }
      final notifCount = await NotificationService.getUnseenCount();
      if (mounted) setState(() => _newNotifCount = notifCount);
    });
  }

  void _showNewMessageBanner() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MessagesScreen(
              employeeId: widget.employeeId,
              employeeName: widget.employeeName,
            ),
          )).then((_) => _loadMsgCount());
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: const Color(0xFF6A1B9A).withOpacity(0.4),
                blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle),
              child: const Icon(Icons.mail_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('رسالة جديدة من HR',
                    style: TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.bold)),
                Text('اضغط للعرض',
                    style: TextStyle(color: Colors.white.withOpacity(0.7),
                        fontSize: 12)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white54, size: 16),
          ]),
        ),
      ),
    ));
  }

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
    final c = await MsgService.getUnseenCount(widget.employeeId);
    if (!mounted) return;
    if (c > _lastKnownMsgCount) {
      _lastKnownMsgCount = c;
      _showNewMessageBanner();
    }
    setState(() => _newMsgCount = c);
  }

  Future<void> _fetchLocation() async {
    final loc = await LocationService.getLocation();
    if (mounted) setState(() { _location = loc; _locationReady = true; });
  }

  Future<void> _checkTodayStatus() async {
    setState(() => _checkingStatus = true);
    final status = await AttendanceService.getTodayStatus(widget.employeeId);
    if (mounted) setState(() {
      _checkedInToday = status.checkedIn;
      _checkedOutToday = status.checkedOut;
      _checkingStatus = false;
    });
  }

  Future<void> _loadNotifCount() async {
    final c = await NotificationService.getUnseenCount();
    if (mounted) setState(() => _newNotifCount = c);
  }

  Future<void> _loadMsgCount() async {
    final c = await MsgService.getUnseenCount(widget.employeeId);
    if (mounted) setState(() { _newMsgCount = c; _lastKnownMsgCount = c; });
  }

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

  void _showGreetingDialog() {
    final name = widget.employeeName.isNotEmpty ? widget.employeeName : 'الموظف الكريم';
    final h = _now.hour;
    final greetIcon = h >= 5 && h < 12 ? '☀️' : h < 18 ? '🌤️' : '🌙';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF040D1E), Color(0xFF0D2060)],
              ),
            ),
            child: Column(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Icon(Icons.eco_rounded,
                    color: Colors.green.shade300, size: 34),
              ),
              const SizedBox(height: 10),
              const Text('PEF',
                  style: TextStyle(color: Colors.white, fontSize: 20,
                      fontWeight: FontWeight.w900, letterSpacing: 5)),
              const SizedBox(height: 3),
              Text('جمعية أصدقاء البيئة',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
            child: Column(children: [
              Text('$_greetingText $greetIcon',
                  style: const TextStyle(fontSize: 22,
                      fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
              const SizedBox(height: 6),
              Text(name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
              const SizedBox(height: 5),
              Text(_formatDateArabic(_now),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF1565C0).withOpacity(0.15)),
                ),
                child: const Text(
                  'نتمنى لك يوماً مثمراً ومليئاً بالإنجازات',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF1565C0),
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('حسناً',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ).animate().scale(
          begin: const Offset(0.85, 0.85),
          duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  Future<void> _record(String type) async {
    if (_isRecording) return;

    // افتح sheet يجلب GPS ويعيد الموقع عند التأكيد
    final gpsLocation = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AttendanceSheet(
        type: type,
        employeeName: widget.employeeName,
        now: _now,
      ),
    );

    if (gpsLocation == null || !mounted) return;

    setState(() { _isRecording = true; _location = gpsLocation; });
    final date = _fmtDate(_now);
    final time = _fmtTime(_now);
    final sent = await AttendanceService.record(
      username: widget.employeeId, name: widget.employeeName,
      date: date, time: time, location: gpsLocation, type: type,
    );
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _locationReady = true;
      if (type == 'حضور') _checkedInToday = true;
      if (type == 'انصراف') _checkedOutToday = true;
    });
    _showResult(type, date, time, sent);
  }

  void _showResult(String type, String date, String time, bool synced) {
    final isIn = type == 'حضور';
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isIn
                    ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
                    : [const Color(0xFFB71C1C), const Color(0xFFEF5350)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: (isIn ? const Color(0xFF43A047) : const Color(0xFFEF5350))
                        .withOpacity(0.35),
                    blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Icon(
                isIn ? Icons.check_circle_rounded : Icons.exit_to_app_rounded,
                size: 38, color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text('تم تسجيل $type بنجاح',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
                    color: isIn ? const Color(0xFF2E7D32) : const Color(0xFFC62828))),
            const SizedBox(height: 14),
            _infoRow(Icons.badge_outlined, widget.employeeName),
            _infoRow(Icons.calendar_today_outlined, date),
            _infoRow(Icons.access_time_rounded, time),
            _infoRow(Icons.location_on_outlined, _location),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  size: 14, color: synced ? Colors.green : Colors.orange),
              const SizedBox(width: 6),
              Text(synced ? 'تمت المزامنة' : 'تحقق من الاتصال',
                  style: TextStyle(fontSize: 12,
                      color: synced ? Colors.green : Colors.orange)),
            ]),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity, height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isIn
                      ? [const Color(0xFF1B5E20), const Color(0xFF43A047)]
                      : [const Color(0xFFB71C1C), const Color(0xFFEF5350)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('حسناً',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF333333)),
              overflow: TextOverflow.ellipsis)),
        ]),
      );

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
        ? widget.employeeName : 'الموظف الكريم';
    final initials = displayName.trim().isNotEmpty ? displayName.trim()[0] : 'م';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(children: [
        // ══ الهيدر ══════════════════════════════════════════
        _buildHeader(displayName, initials),

        // ══ المحتوى ═════════════════════════════════════════
        Expanded(
          child: _checkingStatus
              ? const Center(child: CircularProgressIndicator(
                  color: Color(0xFF1565C0), strokeWidth: 2.5))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFF1565C0),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ─ شارات الحضور ──────────────────
                        _buildStatusRow()
                            .animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 16),

                        // ─ أزرار الحضور والانصراف ─────────
                        _buildAttendanceButtons()
                            .animate().fadeIn(delay: 180.ms).slideY(begin: 0.15),

                        const SizedBox(height: 24),

                        // ─ فاصل الخدمات ──────────────────
                        _buildSectionHeader('الخدمات'),

                        const SizedBox(height: 14),

                        // ─ شبكة الخدمات ──────────────────
                        _buildFeatureGrid()
                            .animate().fadeIn(delay: 280.ms),
                      ],
                    ),
                  ),
                ),
        ),
      ]),
    );
  }

  // ── الهيدر مع موجة سفلية ──────────────────────────────────
  Widget _buildHeader(String displayName, String initials) {
    return ClipPath(
      clipper: _BottomWaveClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF040D1E), Color(0xFF071640), Color(0xFF0D2B7A)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 42),
            child: Column(children: [
              // شريط الأعلى
              Row(children: [
                // شعار PEF
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Icon(Icons.eco_rounded,
                      color: Colors.green.shade300, size: 20),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('PEF',
                      style: TextStyle(color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w900, letterSpacing: 3)),
                  Text('جمعية أصدقاء البيئة',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55), fontSize: 10)),
                ]),
                const Spacer(),
                if (_isRefreshing)
                  const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white38, strokeWidth: 2))
                else
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white38, size: 20),
                    tooltip: 'تحديث',
                  ),
                _BadgeButton(
                  icon: Icons.mail_rounded,
                  count: _newMsgCount,
                  badgeColor: const Color(0xFF42A5F5),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MessagesScreen(
                      employeeId: widget.employeeId,
                      employeeName: widget.employeeName,
                    ),
                  )).then((_) => _loadMsgCount()),
                ),
                _BadgeButton(
                  icon: Icons.notifications_rounded,
                  count: _newNotifCount,
                  badgeColor: Colors.redAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()))
                      .then((_) => _loadNotifCount()),
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white24, size: 20),
                ),
              ]).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 20),

              // الساعة + التاريخ
              Text(_fmtTime(_now),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 3,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 4),

              Text(_formatDateArabic(_now),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12.5, letterSpacing: 0.3))
                  .animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 18),

              // بطاقة الموظف
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(children: [
                  // أفاتار الأحرف الأولى
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.5),
                          blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                      Text('هوية: ${widget.employeeId}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11.5)),
                    ],
                  )),
                  // GPS
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _locationReady
                          ? Colors.green.withOpacity(0.18)
                          : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _locationReady
                              ? Colors.green.withOpacity(0.4)
                              : Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _locationReady
                            ? Icons.gps_fixed_rounded
                            : Icons.location_searching_rounded,
                        size: 11,
                        color: _locationReady
                            ? Colors.green.shade300 : Colors.white38,
                      ),
                      const SizedBox(width: 4),
                      Text(_locationReady ? 'GPS' : '...',
                          style: TextStyle(
                              color: _locationReady
                                  ? Colors.green.shade300 : Colors.white38,
                              fontSize: 10)),
                    ]),
                  ),
                ]),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
            ]),
          ),
        ),
      ),
    );
  }

  // ── شارات حالة الحضور ─────────────────────────────────────
  Widget _buildStatusRow() => Row(children: [
        Expanded(child: _StatusPill(
            label: 'الحضور',
            done: _checkedInToday,
            color: const Color(0xFF2E7D32))),
        const SizedBox(width: 12),
        Expanded(child: _StatusPill(
            label: 'الانصراف',
            done: _checkedOutToday,
            color: const Color(0xFFB71C1C))),
      ]);

  // ── أزرار الحضور والانصراف ────────────────────────────────
  Widget _buildAttendanceButtons() => Row(children: [
        Expanded(child: _AttendanceBtn(
          label: 'تسجيل الحضور',
          icon: Icons.login_rounded,
          gradientColors: _checkedInToday
              ? [const Color(0xFF2E7D32).withOpacity(0.12),
                 const Color(0xFF2E7D32).withOpacity(0.06)]
              : [const Color(0xFF1B5E20), const Color(0xFF43A047)],
          accentColor: const Color(0xFF2E7D32),
          isLoading: _isRecording,
          isDone: _checkedInToday,
          onTap: _checkedInToday ? null : () => _record('حضور'),
        )),
        const SizedBox(width: 14),
        Expanded(child: _AttendanceBtn(
          label: 'تسجيل الانصراف',
          icon: Icons.logout_rounded,
          gradientColors: _checkedOutToday
              ? [const Color(0xFFB71C1C).withOpacity(0.12),
                 const Color(0xFFB71C1C).withOpacity(0.06)]
              : [const Color(0xFFB71C1C), const Color(0xFFEF5350)],
          accentColor: const Color(0xFFB71C1C),
          isLoading: _isRecording,
          isDone: _checkedOutToday,
          onTap: _checkedOutToday ? null : () => _record('انصراف'),
        )),
      ]);

  // ── فاصل عنوان قسم ────────────────────────────────────────
  Widget _buildSectionHeader(String title) => Row(children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500,
                  fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ]);

  // ── شبكة الخدمات (Gradient Cards) ─────────────────────────
  Widget _buildFeatureGrid() => GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.45,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        children: [
          _FeatureCard(
            icon: Icons.person_pin_outlined,
            label: 'بياناتي',
            sublabel: 'الملف الوظيفي الكامل',
            gradientColors: const [Color(0xFF0D47A1), Color(0xFF1976D2)],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProfileScreen(
                nationalId: widget.employeeId,
                employeeName: widget.employeeName,
              ),
            )),
          ),
          _FeatureCard(
            icon: Icons.history_rounded,
            label: 'سجل الحضور',
            sublabel: 'الحضور والانصراف',
            gradientColors: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AttendanceHistoryScreen(
                employeeId: widget.employeeId,
                employeeName: widget.employeeName,
              ),
            )),
          ),
          _FeatureCard(
            icon: Icons.assignment_rounded,
            label: 'تسجيل مهمة',
            sublabel: 'رسمية أو خاصة',
            gradientColors: const [Color(0xFF4527A0), Color(0xFF6A1B9A)],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => TaskScreen(
                employeeId: widget.employeeId,
                employeeName: widget.employeeName,
              ),
            )),
          ),
          _FeatureCard(
            icon: Icons.task_alt_rounded,
            label: 'سجل المهام',
            sublabel: 'المهام السابقة',
            gradientColors: const [Color(0xFF00695C), Color(0xFF00897B)],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => TaskHistoryScreen(
                employeeId: widget.employeeId,
                employeeName: widget.employeeName,
              ),
            )),
          ),
          _FeatureCard(
            icon: Icons.mail_rounded,
            label: 'رسائل HR',
            sublabel: 'من إدارة الموارد البشرية',
            gradientColors: const [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
            badge: _newMsgCount,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => MessagesScreen(
                employeeId: widget.employeeId,
                employeeName: widget.employeeName,
              ),
            )).then((_) => _loadMsgCount()),
          ),
          _FeatureCard(
            icon: Icons.notifications_rounded,
            label: 'الإشعارات',
            sublabel: 'آخر الأخبار والتنبيهات',
            gradientColors: const [Color(0xFFBF360C), Color(0xFFE64A19)],
            badge: _newNotifCount,
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const NotificationsScreen()))
                .then((_) => _loadNotifCount()),
          ),
          _FeatureCard(
            icon: Icons.beach_access_rounded,
            label: 'رصيد الإجازات',
            sublabel: '14 يوم سنوياً',
            gradientColors: const [Color(0xFF006064), Color(0xFF00838F)],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => LeaveScreen(
                nationalId: widget.employeeId,
                employeeName: widget.employeeName,
              ),
            )),
          ),
        ],
      );

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _formatDateArabic(DateTime dt) {
    const days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
        'الجمعة', 'السبت', 'الأحد'];
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${days[dt.weekday - 1]}  ${dt.day}  ${months[dt.month - 1]}  ${dt.year}';
  }
}

// ── Clipper موجة سفلية ────────────────────────────────────────
class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(
          size.width * 0.25, size.height + 6,
          size.width * 0.5, size.height - 18)
      ..quadraticBezierTo(
          size.width * 0.75, size.height - 44,
          size.width, size.height - 18)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }
  @override
  bool shouldReclip(_) => false;
}

// ══ بطاقة خدمة — Gradient ════════════════════════════════════
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final List<Color> gradientColors;
  final int badge;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradientColors,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(
                color: gradientColors[0].withOpacity(0.4),
                blurRadius: 16, offset: const Offset(0, 7))],
          ),
          child: Stack(children: [
            // دائرة زخرفية خلفية
            Positioned(
              right: -18, bottom: -18,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07)),
              ),
            ),
            Positioned(
              right: 14, top: -24,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05)),
              ),
            ),
            // المحتوى
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Text(label,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Badge
            if (badge > 0)
              Positioned(
                top: 10, left: 10,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4)]),
                  child: Center(child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: TextStyle(
                        color: gradientColors[0], fontSize: 10,
                        fontWeight: FontWeight.bold),
                  )),
                ),
              ),
          ]),
        ),
      );
}

// ══ زر Badge ═════════════════════════════════════════════════
class _BadgeButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color badgeColor;
  final VoidCallback onTap;

  const _BadgeButton({
    required this.icon, required this.count,
    required this.badgeColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        icon: Stack(clipBehavior: Clip.none, children: [
          Icon(icon, color: Colors.white60, size: 22),
          if (count > 0)
            Positioned(
              right: -4, top: -4,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                    color: badgeColor, shape: BoxShape.circle),
                child: Center(child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 9, fontWeight: FontWeight.bold),
                )),
              ),
            ),
        ]),
      );
}

// ══ شارة حالة الحضور ══════════════════════════════════════════
class _StatusPill extends StatelessWidget {
  final String label;
  final bool done;
  final Color color;

  const _StatusPill({required this.label, required this.done, required this.color});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: done ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: done ? color.withOpacity(0.4) : Colors.grey.shade200,
              width: 1.5),
          boxShadow: [BoxShadow(
              color: done ? color.withOpacity(0.1) : Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: done ? color : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Text(
            done ? 'تم $label ✓' : '$label غير مسجّل',
            style: TextStyle(
              fontSize: 12,
              color: done ? color : Colors.grey.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      );
}

// ══ زر الحضور/الانصراف ════════════════════════════════════════
class _AttendanceBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;
  final bool isLoading, isDone;
  final VoidCallback? onTap;

  const _AttendanceBtn({
    required this.label, required this.icon,
    required this.gradientColors, required this.accentColor,
    required this.isLoading, required this.isDone, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 105,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(22),
            border: isDone
                ? Border.all(color: accentColor.withOpacity(0.35), width: 1.5)
                : null,
            boxShadow: isDone
                ? [BoxShadow(color: accentColor.withOpacity(0.08),
                    blurRadius: 10, offset: const Offset(0, 4))]
                : [BoxShadow(color: gradientColors[0].withOpacity(0.45),
                    blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading && !isDone) ...[
                const SizedBox(width: 28, height: 28,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5)),
                const SizedBox(height: 7),
                const Text('جاري التسجيل...',
                    style: TextStyle(color: Colors.white70,
                        fontSize: 11, fontWeight: FontWeight.w500)),
              ] else ...[
                Icon(isDone ? Icons.check_circle_rounded : icon,
                    color: isDone ? accentColor : Colors.white, size: 30),
                const SizedBox(height: 7),
                Text(isDone ? 'تم التسجيل ✓' : label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDone ? accentColor : Colors.white,
                        fontSize: 12.5, fontWeight: FontWeight.bold)),
                if (!isDone) ...[
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.gps_fixed_rounded, size: 10,
                        color: Colors.white.withOpacity(0.55)),
                    const SizedBox(width: 3),
                    Text('يتطلب GPS',
                        style: TextStyle(color: Colors.white.withOpacity(0.55),
                            fontSize: 9.5)),
                  ]),
                ],
              ],
            ],
          ),
        ),
      );
}

// ══ Sheet تأكيد الحضور مع GPS ════════════════════════════════
class _AttendanceSheet extends StatefulWidget {
  final String type, employeeName;
  final DateTime now;
  const _AttendanceSheet({
    required this.type, required this.employeeName, required this.now,
  });
  @override
  State<_AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<_AttendanceSheet> {
  String _gps = 'جاري تحديد الموقع...';
  bool _gpsLoading = true;
  bool _gpsReady = false;

  @override
  void initState() {
    super.initState();
    _fetchGps();
  }

  Future<void> _fetchGps() async {
    setState(() { _gpsLoading = true; _gpsReady = false; _gps = 'جاري تحديد الموقع...'; });
    final loc = await LocationService.getLocation();
    if (!mounted) return;
    final ok = !loc.contains('غير') && !loc.contains('رفض') &&
               !loc.contains('معطل') && !loc.contains('محظور');
    setState(() { _gps = loc; _gpsLoading = false; _gpsReady = ok; });
  }

  @override
  Widget build(BuildContext context) {
    final isIn = widget.type == 'حضور';
    final color = isIn ? const Color(0xFF2E7D32) : const Color(0xFFB71C1C);
    final lightColor = isIn ? const Color(0xFF43A047) : const Color(0xFFEF5350);
    final time = '${widget.now.hour.toString().padLeft(2,'0')}:'
                 '${widget.now.minute.toString().padLeft(2,'0')}';
    final date = '${widget.now.day.toString().padLeft(2,'0')}/'
                 '${widget.now.month.toString().padLeft(2,'0')}/${widget.now.year}';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18),
            blurRadius: 40, offset: const Offset(0, -8))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // مقبض السحب
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
        ),

        // رأس الـ sheet
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color, lightColor],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.35),
                blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle),
              child: Icon(
                isIn ? Icons.login_rounded : Icons.logout_rounded,
                color: Colors.white, size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تسجيل ${widget.type}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(widget.employeeName,
                    style: TextStyle(color: Colors.white.withOpacity(0.75),
                        fontSize: 12.5),
                    overflow: TextOverflow.ellipsis),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(time, style: const TextStyle(color: Colors.white,
                  fontSize: 22, fontWeight: FontWeight.w300,
                  letterSpacing: 1)),
              Text(date, style: TextStyle(color: Colors.white.withOpacity(0.65),
                  fontSize: 11)),
            ]),
          ]),
        ),

        // بطاقة GPS
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _GpsStatusCard(
            coords: _gps,
            loading: _gpsLoading,
            ready: _gpsReady,
            onRetry: _fetchGps,
          ),
        ),

        // رسالة تحذير إن لم يكن GPS جاهزاً
        if (!_gpsLoading && !_gpsReady)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'لم يتم تحديد الموقع. تأكد من تفعيل GPS ثم أعد المحاولة.',
                  style: TextStyle(color: Colors.orange.shade800,
                      fontSize: 12, height: 1.4),
                )),
              ]),
            ),
          ),

        // أزرار
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(children: [
            // إلغاء
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(child: Text('إلغاء',
                      style: TextStyle(color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold, fontSize: 15))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // تأكيد
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _gpsReady ? () => Navigator.pop(context, _gps) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _gpsReady
                        ? LinearGradient(colors: [color, lightColor],
                            begin: Alignment.topLeft, end: Alignment.bottomRight)
                        : null,
                    color: _gpsReady ? null : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _gpsReady
                        ? [BoxShadow(color: color.withOpacity(0.4),
                              blurRadius: 14, offset: const Offset(0, 6))]
                        : [],
                  ),
                  child: Center(child: _gpsLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(
                            _gpsReady ? Icons.check_rounded : Icons.gps_not_fixed_rounded,
                            color: _gpsReady ? Colors.white : Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _gpsReady ? 'تأكيد التسجيل' : 'في انتظار GPS...',
                            style: TextStyle(
                              color: _gpsReady ? Colors.white : Colors.grey.shade400,
                              fontWeight: FontWeight.bold, fontSize: 15,
                            ),
                          ),
                        ])),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ══ بطاقة حالة GPS ══════════════════════════════════════════
class _GpsStatusCard extends StatelessWidget {
  final String coords;
  final bool loading, ready;
  final VoidCallback onRetry;
  const _GpsStatusCard({
    required this.coords, required this.loading,
    required this.ready, required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: ready
              ? const Color(0xFF2E7D32).withOpacity(0.07)
              : loading
                  ? const Color(0xFF1565C0).withOpacity(0.06)
                  : Colors.orange.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ready
                ? const Color(0xFF2E7D32).withOpacity(0.35)
                : loading
                    ? const Color(0xFF1565C0).withOpacity(0.25)
                    : Colors.orange.withOpacity(0.35),
          ),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: ready
                  ? const Color(0xFF2E7D32).withOpacity(0.1)
                  : const Color(0xFF1565C0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: loading
                ? const Padding(padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Color(0xFF1565C0)))
                : Icon(
                    ready ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                    size: 22,
                    color: ready ? const Color(0xFF2E7D32) : Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('موقع GPS الحالي',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(coords,
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: ready
                        ? const Color(0xFF2E7D32)
                        : loading ? const Color(0xFF1565C0) : Colors.orange.shade800,
                  ),
                  overflow: TextOverflow.ellipsis),
            ],
          )),
          if (!loading && !ready)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.orange, size: 22),
              tooltip: 'إعادة المحاولة',
            ),
        ]),
      );
}
