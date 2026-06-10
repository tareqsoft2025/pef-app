import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/task_service.dart';
import '../services/location_service.dart';
import 'task_history_screen.dart';

class TaskScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const TaskScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _authorityCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();

  String _taskType = 'رسمية';
  TimeOfDay _departure = TimeOfDay.now();
  TimeOfDay _return = TimeOfDay.now();
  bool _submitting = false;

  // GPS تلقائي للمهام الرسمية
  String _gpsCoords = 'جاري تحديد الموقع...';
  bool _gpsLoading = false;
  bool _gpsReady = false;

  @override
  void initState() {
    super.initState();
    // المهمة الرسمية هي الافتراضية — ابدأ جلب GPS فوراً
    _fetchGps();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _authorityCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGps() async {
    if (_gpsLoading) return;
    setState(() {
      _gpsLoading = true;
      _gpsReady = false;
      _gpsCoords = 'جاري تحديد الموقع...';
    });
    final loc = await LocationService.getLocation();
    if (mounted) {
      setState(() {
        _gpsCoords = loc;
        _gpsLoading = false;
        _gpsReady = !loc.contains('غير') &&
            !loc.contains('رفض') &&
            !loc.contains('معطل') &&
            !loc.contains('محظور');
      });
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _today() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}/'
        '${n.month.toString().padLeft(2, '0')}/${n.year}';
  }

  Future<void> _pickTime(bool isDeparture) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isDeparture ? _departure : _return,
      builder: (ctx, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
    if (picked == null) return;
    setState(() {
      if (isDeparture) _departure = picked;
      else _return = picked;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final depMin = _departure.hour * 60 + _departure.minute;
    final retMin = _return.hour * 60 + _return.minute;
    if (retMin <= depMin) {
      _showSnack('وقت العودة يجب أن يكون بعد وقت الخروج', Colors.redAccent);
      return;
    }

    // إذا رسمية ولم يُحدَّد الموقع بعد
    if (_taskType == 'رسمية' && !_gpsReady) {
      _showSnack('يرجى الانتظار حتى يتم تحديد موقعك', const Color(0xFF1565C0));
      return;
    }

    setState(() => _submitting = true);

    final ok = await TaskService.submit(
      username: widget.employeeId,
      name: widget.employeeName,
      date: _today(),
      taskType: _taskType,
      departureTime: _formatTime(_departure),
      returnTime: _formatTime(_return),
      reason: _reasonCtrl.text.trim(),
      authority: _taskType == 'رسمية' ? _authorityCtrl.text.trim() : '',
      destination: _taskType == 'رسمية' ? _destinationCtrl.text.trim() : '',
      gps: _taskType == 'رسمية' ? _gpsCoords : '',
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    ok ? _showSuccessDialog() : _showSnack('تعذّر الإرسال، تحقق من الاتصال', Colors.orange);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.task_alt_rounded,
                    size: 40, color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 16),
              const Text('تم تسجيل المهمة بنجاح',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1))),
              const SizedBox(height: 12),
              _row('النوع', _taskType),
              _row('الخروج', _formatTime(_departure)),
              _row('العودة', _formatTime(_return)),
              if (_taskType == 'رسمية') ...[
                if (_authorityCtrl.text.isNotEmpty)
                  _row('الجهة', _authorityCtrl.text),
                if (_destinationCtrl.text.isNotEmpty)
                  _row('المكان', _destinationCtrl.text),
                _row('GPS', _gpsCoords),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('حسناً',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 13, color: Color(0xFF333333)),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B4B), Color(0xFF0D47A1)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const Expanded(
                          child: Text('تسجيل مهمة',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white,
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskHistoryScreen(
                                employeeId: widget.employeeId,
                                employeeName: widget.employeeName,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.history_rounded,
                              color: Colors.white70, size: 24),
                          tooltip: 'سجل المهام',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.employeeName,
                                style: const TextStyle(color: Colors.white,
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(_today(),
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // ── النموذج ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // نوع المهمة
                    _label('نوع المهمة'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _TypeCard(
                          label: 'رسمية',
                          icon: Icons.business_center_rounded,
                          selected: _taskType == 'رسمية',
                          color: const Color(0xFF1565C0),
                          onTap: () {
                            setState(() => _taskType = 'رسمية');
                            _fetchGps();
                          },
                        ),
                        const SizedBox(width: 12),
                        _TypeCard(
                          label: 'خاص',
                          icon: Icons.person_outline_rounded,
                          selected: _taskType == 'خاص',
                          color: const Color(0xFF6A1B9A),
                          onTap: () => setState(() => _taskType = 'خاص'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 22),

                    // الأوقات
                    _label('الأوقات'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeCard(
                            label: 'وقت الخروج',
                            icon: Icons.logout_rounded,
                            time: _departure,
                            color: const Color(0xFFE53935),
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeCard(
                            label: 'وقت العودة',
                            icon: Icons.login_rounded,
                            time: _return,
                            color: const Color(0xFF43A047),
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 22),

                    // السبب
                    _label('السبب'),
                    const SizedBox(height: 10),
                    _field(
                      ctrl: _reasonCtrl,
                      hint: 'اكتب سبب الخروج...',
                      maxLines: 3,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'يرجى كتابة السبب' : null,
                    ).animate().fadeIn(delay: 200.ms),

                    // ── تفاصيل المهمة الرسمية ─────────────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      child: _taskType == 'رسمية'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 22),
                                _label('تفاصيل المهمة الرسمية'),
                                const SizedBox(height: 10),

                                // الجهة المكلفة
                                _field(
                                  ctrl: _authorityCtrl,
                                  hint: 'مثال: تكليف المدير التنفيذي',
                                  icon: Icons.account_balance_outlined,
                                  validator: (v) =>
                                      (_taskType == 'رسمية' &&
                                              (v == null || v.trim().isEmpty))
                                          ? 'يرجى ذكر الجهة المكلفة'
                                          : null,
                                ),
                                const SizedBox(height: 14),

                                // مكان التواجد (نص)
                                _field(
                                  ctrl: _destinationCtrl,
                                  hint: 'مثال: مشروع ميكا',
                                  icon: Icons.place_outlined,
                                  validator: (v) =>
                                      (_taskType == 'رسمية' &&
                                              (v == null || v.trim().isEmpty))
                                          ? 'يرجى ذكر مكان التواجد'
                                          : null,
                                ),
                                const SizedBox(height: 14),

                                // موقع GPS تلقائي
                                _GpsCard(
                                  coords: _gpsCoords,
                                  loading: _gpsLoading,
                                  ready: _gpsReady,
                                  onRetry: _fetchGps,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 32),

                    // زر الإرسال
                    SizedBox(
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF0D47A1).withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        icon: _submitting
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Icon(Icons.send_rounded, size: 22),
                        label: Text(
                          _submitting ? 'جاري الإرسال...' : 'تسجيل المهمة',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
          color: Color(0xFF0D47A1)));

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    int maxLines = 1,
    IconData? icon,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xFF0D47A1), size: 20)
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF0D47A1), width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent)),
        ),
        validator: validator,
      );
}

// ── بطاقة GPS ─────────────────────────────────────────────
class _GpsCard extends StatelessWidget {
  final String coords;
  final bool loading;
  final bool ready;
  final VoidCallback onRetry;

  const _GpsCard({
    required this.coords,
    required this.loading,
    required this.ready,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ready
            ? const Color(0xFF43A047).withOpacity(0.08)
            : loading
                ? const Color(0xFF1565C0).withOpacity(0.06)
                : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ready
              ? const Color(0xFF43A047).withOpacity(0.4)
              : loading
                  ? const Color(0xFF1565C0).withOpacity(0.3)
                  : Colors.orange.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          // أيقونة
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: ready
                  ? const Color(0xFF43A047).withOpacity(0.12)
                  : const Color(0xFF1565C0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Color(0xFF1565C0)),
                  )
                : Icon(
                    ready
                        ? Icons.gps_fixed_rounded
                        : Icons.gps_not_fixed_rounded,
                    size: 20,
                    color: ready
                        ? const Color(0xFF43A047)
                        : Colors.orange,
                  ),
          ),
          const SizedBox(width: 12),

          // نص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موقع GPS التلقائي',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  coords,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ready
                        ? const Color(0xFF2E7D32)
                        : loading
                            ? const Color(0xFF1565C0)
                            : Colors.orange.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // زر إعادة المحاولة
          if (!loading && !ready)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.orange, size: 22),
              tooltip: 'إعادة المحاولة',
            ),
        ],
      ),
    );
  }
}

// ── بطاقة اختيار نوع المهمة ────────────────────────────────
class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label, required this.icon, required this.selected,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: selected ? color : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: selected ? color : Colors.grey.shade200,
                  width: selected ? 0 : 1),
              boxShadow: selected
                  ? [BoxShadow(color: color.withOpacity(0.3),
                        blurRadius: 16, offset: const Offset(0, 6))]
                  : [],
            ),
            child: Column(
              children: [
                Icon(icon, size: 32,
                    color: selected ? Colors.white : Colors.grey.shade500),
                const SizedBox(height: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      );
}

// ── بطاقة اختيار الوقت ────────────────────────────────────
class _TimeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay time;
  final Color color;
  final VoidCallback onTap;

  const _TimeCard({
    required this.label, required this.icon, required this.time,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(color: Colors.grey.shade600,
                      fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                '${time.hour.toString().padLeft(2, '0')}:'
                '${time.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: color),
              ),
            ],
          ),
        ),
      );
}
