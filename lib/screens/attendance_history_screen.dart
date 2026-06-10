import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/attendance_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const AttendanceHistoryScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await AttendanceService.fetchHistory(widget.employeeId);
    if (mounted) {
      setState(() {
        _records = data;
        _loading = false;
      });
    }
  }

  // إحصائيات الشهر الحالي
  int get _monthCheckIns {
    final now = DateTime.now();
    final prefix = '/${now.month.toString().padLeft(2, '0')}/${now.year}';
    return _records
        .where((r) => r.date.endsWith(prefix) && r.type == 'حضور')
        .length;
  }

  int get _monthCheckOuts {
    final now = DateTime.now();
    final prefix = '/${now.month.toString().padLeft(2, '0')}/${now.year}';
    return _records
        .where((r) => r.date.endsWith(prefix) && r.type == 'انصراف')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                          child: Text(
                            'سجل الحضور والانصراف',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white70, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // بطاقة الموظف
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employeeName.isNotEmpty
                                  ? widget.employeeName
                                  : 'الموظف الكريم',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.employeeId,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // إحصائيات الشهر
                    if (!_loading)
                      Row(
                        children: [
                          _StatCard(
                            label: 'حضور هذا الشهر',
                            count: _monthCheckIns,
                            icon: Icons.login_rounded,
                            color: const Color(0xFF43A047),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'انصراف هذا الشهر',
                            count: _monthCheckOuts,
                            icon: Icons.logout_rounded,
                            color: const Color(0xFFE53935),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),

          // ── القائمة ───────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0D47A1),
                    ),
                  )
                : _records.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF0D47A1),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: _records.length,
                          itemBuilder: (_, i) => _RecordCard(
                            record: _records[i],
                            index: i,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'لا توجد سجلات بعد',
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر هنا سجلات حضورك وانصرافك',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
}

// ── بطاقة إحصائية ──────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── بطاقة سجل واحد ─────────────────────────────────────────
class _RecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final int index;

  const _RecordCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final isIn = record.type == 'حضور';
    final color = isIn ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final lightColor =
        isIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // أيقونة النوع
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isIn ? Icons.login_rounded : Icons.logout_rounded,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // التفاصيل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: lightColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            record.type,
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          record.date,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 15, color: Color(0xFF0D47A1)),
                        const SizedBox(width: 5),
                        Text(
                          record.time,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            record.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 60).ms, duration: 400.ms)
        .slideY(begin: 0.15);
  }
}
