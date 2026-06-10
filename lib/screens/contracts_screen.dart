import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/contract_service.dart';

class ContractsScreen extends StatefulWidget {
  final String nationalId;
  final String employeeName;

  const ContractsScreen({
    super.key,
    required this.nationalId,
    required this.employeeName,
  });

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  List<Contract> _contracts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ContractService.fetchContracts(widget.nationalId);
    if (mounted) setState(() { _contracts = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── الهيدر ───────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF071235),
                  Color(0xFF0D2B6B),
                  Color(0xFF1B5E20),
                ],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(30)),
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
                          icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20),
                        ),
                        const Expanded(
                          child: Text('عقودي',
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
                    // بطاقة الموظف + إحصائيات
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.description_rounded,
                                color: Colors.white,
                                size: 26),
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
                          if (!_loading) ...[
                            _StatChip('الكل', '${_contracts.length}',
                                Colors.white),
                            const SizedBox(width: 8),
                            _StatChip(
                              'نشط',
                              '${_contracts.where((c) => c.status == ContractStatus.active || c.status == ContractStatus.expiringSoon).length}',
                              Colors.greenAccent,
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // ── المحتوى ──────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1B5E20), strokeWidth: 2.5))
                : _contracts.isEmpty
                    ? _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF1B5E20),
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          itemCount: _contracts.length,
                          itemBuilder: (_, i) => _ContractCard(
                              contract: _contracts[i], index: i),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── شريحة إحصائية ────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.7), fontSize: 10)),
        ],
      );
}

// ── بطاقة عقد ────────────────────────────────────────────────
class _ContractCard extends StatelessWidget {
  final Contract contract;
  final int index;
  const _ContractCard({required this.contract, required this.index});

  @override
  Widget build(BuildContext context) {
    final st = contract.status;
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (st) {
      case ContractStatus.active:
        statusColor = const Color(0xFF2E7D32);
        statusLabel = 'ساري';
        statusIcon = Icons.check_circle_rounded;
      case ContractStatus.expiringSoon:
        statusColor = const Color(0xFFE65100);
        statusLabel = 'ينتهي قريباً';
        statusIcon = Icons.warning_amber_rounded;
      case ContractStatus.expired:
        statusColor = const Color(0xFFC62828);
        statusLabel = 'منتهي';
        statusIcon = Icons.cancel_rounded;
      case ContractStatus.unknown:
        statusColor = Colors.grey;
        statusLabel = 'غير محدد';
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // رأس البطاقة
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_rounded,
                      color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.position.isNotEmpty
                            ? contract.position
                            : 'عقد رقم ${index + 1}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                      if (contract.department.isNotEmpty)
                        Text(contract.department,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                // شارة الحالة
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // تفاصيل العقد
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // قيمة العقد — بارزة
                if (contract.value.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.monetization_on_outlined,
                            size: 18, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text('قيمة العقد',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                        const Spacer(),
                        Text(
                          contract.value,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // التواريخ
                Row(
                  children: [
                    Expanded(
                      child: _DateBox(
                        label: 'بداية العقد',
                        date: contract.startDate,
                        icon: Icons.play_circle_outline_rounded,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateBox(
                        label: 'نهاية العقد',
                        date: contract.endDate,
                        icon: Icons.stop_circle_outlined,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),

                // اسم الموظف إن وُجد
                if (contract.employeeName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 15, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text('الموظف',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500)),
                      const Spacer(),
                      Text(contract.employeeName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 80 * (index % 6)))
        .slideY(begin: 0.1);
  }
}

// ── صندوق تاريخ ──────────────────────────────────────────────
class _DateBox extends StatelessWidget {
  final String label, date;
  final IconData icon;
  final Color color;

  const _DateBox({
    required this.label,
    required this.date,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date.isNotEmpty ? date : '—',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: date.isNotEmpty ? color : Colors.grey),
            ),
          ],
        ),
      );
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
                color: const Color(0xFF1B5E20).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined,
                  size: 44, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 20),
            const Text('لا توجد عقود',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text('لم يتم تسجيل عقود لهذا الموظف بعد',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      );
}
