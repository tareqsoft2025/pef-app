import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/leave_service.dart';

class LeaveScreen extends StatefulWidget {
  final String nationalId;
  final String employeeName;

  const LeaveScreen({
    super.key,
    required this.nationalId,
    required this.employeeName,
  });

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  LeaveBalance? _balance;
  bool _loading = true;
  bool _notFound = false;

  static const List<String> _monthNames = [
    'يناير', 'فبراير', 'مارس', 'أبريل',
    'مايو', 'يونيو', 'يوليو', 'أغسطس',
    'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _notFound = false; });
    final data = await LeaveService.fetchBalance(widget.nationalId);
    if (mounted) {
      setState(() {
        _balance = data;
        _notFound = data == null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0D47A1), strokeWidth: 2.5))
                : _notFound
                    ? _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF0D47A1),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          child: Column(
                            children: [
                              _BalanceGauge(balance: _balance!),
                              const SizedBox(height: 20),
                              _SummaryRow(balance: _balance!),
                              const SizedBox(height: 20),
                              _MonthlyGrid(
                                balance: _balance!,
                                monthNames: _monthNames,
                              ),
                              const SizedBox(height: 16),
                              _LegalNote(),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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
                    child: Text('رصيد الإجازات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white54, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.beach_access_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.employeeName.isNotEmpty
                                ? widget.employeeName
                                : 'الموظف الكريم',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(widget.nationalId,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_balance != null) ...[
                      _HeaderChip(
                          label: 'المستحق',
                          value: _balance!.total.toStringAsFixed(2),
                          color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      _HeaderChip(
                          label: 'الحد الأقصى',
                          value: '14',
                          color: Colors.white70),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── شريحة رقمية في الهيدر ────────────────────────────────────
class _HeaderChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HeaderChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10)),
        ],
      );
}

// ── مقياس الرصيد الدائري ─────────────────────────────────────
class _BalanceGauge extends StatelessWidget {
  final LeaveBalance balance;
  const _BalanceGauge({required this.balance});

  @override
  Widget build(BuildContext context) {
    final pct = (balance.total / LeaveBalance.annualEntitlement).clamp(0.0, 1.0);
    final Color gaugeColor = pct >= 0.7
        ? const Color(0xFF2E7D32)
        : pct >= 0.4
            ? const Color(0xFFF57F17)
            : const Color(0xFF0D47A1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gaugeColor.withOpacity(0.08),
            const Color(0xFF0D47A1).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gaugeColor.withOpacity(0.2)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // الدائرة
          SizedBox(
            width: 130, height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(130, 130),
                  painter: _ArcPainter(
                    progress: pct,
                    color: gaugeColor,
                    trackColor: gaugeColor.withOpacity(0.12),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      balance.total.toStringAsFixed(2),
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: gaugeColor),
                    ),
                    Text('يوم',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    Text(
                      '${balance.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 11,
                          color: gaugeColor.withOpacity(0.7),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // ملخص نصي
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رصيد الإجازات السنوي',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700)),
                const SizedBox(height: 14),
                _GaugeRow(
                    label: 'المستحق',
                    value: '${balance.total.toStringAsFixed(2)} يوم',
                    color: gaugeColor),
                const SizedBox(height: 8),
                _GaugeRow(
                    label: 'الحد القانوني',
                    value: '${LeaveBalance.annualEntitlement.toStringAsFixed(0)} يوم',
                    color: Colors.grey.shade500),
                const SizedBox(height: 8),
                _GaugeRow(
                    label: 'المستحق شهرياً',
                    value: '${LeaveBalance.monthlyMax.toStringAsFixed(2)} يوم',
                    color: const Color(0xFF0D47A1)),
                const SizedBox(height: 12),
                // شريط تقدم
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: gaugeColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(gaugeColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }
}

class _GaugeRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _GaugeRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500))),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      );
}

// ── رسم القوس ────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color, trackColor;
  const _ArcPainter(
      {required this.progress,
      required this.color,
      required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const strokeW = 12.0;
    final radius = (size.width / 2) - strokeW / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    const startAngle = -math.pi * 0.75;
    const sweepFull = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepFull, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
          rect, startAngle, sweepFull * progress, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ── صف الملخص (3 بطاقات) ─────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final LeaveBalance balance;
  const _SummaryRow({required this.balance});

  @override
  Widget build(BuildContext context) {
    final monthsLeft = 12 - balance.monthsWithData;
    final projected = balance.total + monthsLeft * LeaveBalance.monthlyMax;

    return Row(
      children: [
        Expanded(
            child: _SummaryCard(
                icon: Icons.done_all_rounded,
                label: 'أشهر مسجلة',
                value: '${balance.monthsWithData}',
                unit: '/ 12',
                color: const Color(0xFF1565C0))),
        const SizedBox(width: 10),
        Expanded(
            child: _SummaryCard(
                icon: Icons.trending_up_rounded,
                label: 'متوقع بنهاية العام',
                value: projected.toStringAsFixed(1),
                unit: 'يوم',
                color: const Color(0xFF2E7D32))),
        const SizedBox(width: 10),
        Expanded(
            child: _SummaryCard(
                icon: Icons.calendar_month_rounded,
                label: 'المتوسط الشهري',
                value: balance.monthsWithData > 0
                    ? (balance.total / balance.monthsWithData)
                        .toStringAsFixed(2)
                    : '0.00',
                unit: 'يوم',
                color: const Color(0xFF6A1B9A))),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final Color color;
  const _SummaryCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 9.5, color: Colors.grey.shade500)),
          ],
        ),
      );
}

// ── شبكة الأشهر ──────────────────────────────────────────────
class _MonthlyGrid extends StatelessWidget {
  final LeaveBalance balance;
  final List<String> monthNames;
  const _MonthlyGrid(
      {required this.balance, required this.monthNames});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 12),
          child: Text('الرصيد الشهري التفصيلي',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700)),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: 12,
          itemBuilder: (_, i) => _MonthCard(
            monthName: monthNames[i],
            year: 2026,
            month: i + 1,
            value: balance.monthly[i],
            index: i,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _MonthCard extends StatelessWidget {
  final String monthName;
  final int year, month, index;
  final double value;
  const _MonthCard({
    required this.monthName,
    required this.year,
    required this.month,
    required this.index,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / LeaveBalance.monthlyMax).clamp(0.0, 1.0);
    final bool hasData = value > 0;
    final bool isFuture = month > DateTime.now().month || year > DateTime.now().year;

    final Color cardColor = !hasData
        ? Colors.grey.shade400
        : pct >= 0.95
            ? const Color(0xFF2E7D32)
            : pct >= 0.6
                ? const Color(0xFF1565C0)
                : const Color(0xFFF57F17);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: cardColor.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
        border: Border.all(color: cardColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // اسم الشهر + رقمه
          Column(
            children: [
              Text(monthName,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: hasData
                          ? const Color(0xFF1A1A2E)
                          : Colors.grey.shade400)),
              Text('$month/$year',
                  style: TextStyle(
                      fontSize: 9, color: Colors.grey.shade400)),
            ],
          ),

          // القيمة
          Text(
            isFuture && !hasData
                ? '—'
                : value > 0
                    ? value.toStringAsFixed(2)
                    : '0.00',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: hasData ? cardColor : Colors.grey.shade300),
          ),

          // شريط التقدم
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: cardColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(cardColor),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                hasData
                    ? '${(pct * 100).toStringAsFixed(0)}%'
                    : isFuture
                        ? 'لم يُسجَّل'
                        : 'غير متاح',
                style: TextStyle(
                    fontSize: 8.5,
                    color: hasData
                        ? cardColor.withOpacity(0.8)
                        : Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * (index % 6) + 350))
        .scale(begin: const Offset(0.9, 0.9));
  }
}

// ── ملاحظة قانونية ────────────────────────────────────────────
class _LegalNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1).withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF0D47A1).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 18, color: Color(0xFF0D47A1)),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF37474F)),
                  children: [
                    TextSpan(
                        text: 'وفق قانون العمل: ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: '14 يوم إجازة سنوية · '
                            'المعدل الشهري: 1.17 يوم · '
                            'يُحسب الرصيد بناءً على نسبة الحضور الشهري'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 600.ms);
}

// ── حالة فارغة ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.beach_access_outlined,
                  size: 44, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 20),
            const Text('لا توجد بيانات إجازات',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text('لم يتم تسجيل رصيد إجازات لهذا الموظف بعد',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      );
}
