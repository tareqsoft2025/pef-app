import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/task_service.dart';

class TaskHistoryScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const TaskHistoryScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<TaskHistoryScreen> createState() => _TaskHistoryScreenState();
}

class _TaskHistoryScreenState extends State<TaskHistoryScreen> {
  List<TaskRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await TaskService.fetchHistory(widget.employeeId);
      if (mounted) setState(() { _records = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'تعذّر تحميل البيانات'; });
    }
  }

  int get _officialCount => _records.where((r) => r.isOfficial).length;
  int get _personalCount => _records.where((r) => !r.isOfficial).length;

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
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
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
                          child: Text(
                            'سجل المهام',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // إحصائيات سريعة
                    if (!_loading && _records.isNotEmpty)
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'الإجمالي',
                            value: _records.length,
                            icon: Icons.list_alt_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            label: 'رسمية',
                            value: _officialCount,
                            icon: Icons.business_center_rounded,
                            color: const Color(0xFF64B5F6),
                          ),
                          const SizedBox(width: 10),
                          _StatChip(
                            label: 'خاصة',
                            value: _personalCount,
                            icon: Icons.person_outline_rounded,
                            color: const Color(0xFFCE93D8),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // ── المحتوى ─────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0D47A1)))
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _load)
                    : _records.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            onRefresh: _load,
                            color: const Color(0xFF0D47A1),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                              itemCount: _records.length,
                              itemBuilder: (context, i) => _TaskCard(
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
}

// ── بطاقة مهمة ────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final TaskRecord record;
  final int index;

  const _TaskCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final isOfficial = record.isOfficial;
    final typeColor =
        isOfficial ? const Color(0xFF1565C0) : const Color(0xFF6A1B9A);
    final typeLightColor =
        isOfficial ? const Color(0xFFE3F2FD) : const Color(0xFFF3E5F5);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── شريط العنوان ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: typeLightColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOfficial
                            ? Icons.business_center_rounded
                            : Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        record.taskType,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 5),
                    Text(
                      record.date,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── التفاصيل ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // أوقات الخروج والعودة
                Row(
                  children: [
                    Expanded(
                      child: _TimeInfo(
                        label: 'وقت الخروج',
                        value: record.departureTime,
                        icon: Icons.logout_rounded,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _TimeInfo(
                        label: 'وقت العودة',
                        value: record.returnTime,
                        icon: Icons.login_rounded,
                        color: const Color(0xFF43A047),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // السبب
                _DetailRow(
                  icon: Icons.notes_rounded,
                  label: 'السبب',
                  value: record.reason,
                  color: Colors.grey.shade700,
                ),

                // تفاصيل المهام الرسمية
                if (isOfficial) ...[
                  if (record.authority.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.account_balance_outlined,
                      label: 'الجهة',
                      value: record.authority,
                      color: typeColor,
                    ),
                  ],
                  if (record.destination.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.place_outlined,
                      label: 'المكان',
                      value: record.destination,
                      color: typeColor,
                    ),
                  ],
                  if (record.gps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.gps_fixed_rounded,
                      label: 'GPS',
                      value: record.gps,
                      color: const Color(0xFF43A047),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 50 * (index % 10)))
        .slideY(begin: 0.15);
  }
}

class _TimeInfo extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _TimeInfo(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label: ',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333))),
          ),
        ],
      );
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              '$value $label',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا توجد مهام مسجّلة',
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('ستظهر مهامك هنا بعد تسجيلها',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
}
