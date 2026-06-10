import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _items = [];
  bool _loading = true;
  int _unseenOnOpen = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // اقرأ عدد غير المقروءة أولاً ثم علّم الكل كمقروء
    final unseenCount = await NotificationService.getUnseenCount();
    final items = await NotificationService.fetchAll();
    await NotificationService.markAllSeen(items.length);

    if (mounted) {
      setState(() {
        _items = items;
        _unseenOnOpen = unseenCount;
        _loading = false;
      });
    }
  }

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
                colors: [Color(0xFF0D1B4B), Color(0xFF1A237E),
                    Color(0xFF283593)],
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
                          icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const Expanded(
                          child: Text('الإشعارات',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    if (!_loading && _items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Chip(
                              label: '${_items.length}',
                              suffix: 'إشعار',
                              icon: Icons.notifications_rounded,
                              color: Colors.white,
                            ),
                            if (_unseenOnOpen > 0) ...[
                              const SizedBox(width: 12),
                              _Chip(
                                label: '$_unseenOnOpen',
                                suffix: 'جديد',
                                icon: Icons.fiber_new_rounded,
                                color: const Color(0xFF64B5F6),
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

          // ── المحتوى ─────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1A237E)))
                : _items.isEmpty
                    ? _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF1A237E),
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _items.length,
                          itemBuilder: (context, i) => _NotifCard(
                            item: _items[i],
                            isNew: i < _unseenOnOpen,
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

// ── بطاقة إشعار ────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotificationItem item;
  final bool isNew;
  final int index;

  const _NotifCard({
    required this.item,
    required this.isNew,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isNew
            ? Border.all(color: const Color(0xFF3949AB).withOpacity(0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isNew ? 0.09 : 0.05),
            blurRadius: isNew ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط جانبي للإشعارات الجديدة
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: isNew
                    ? const Color(0xFF3949AB)
                    : Colors.grey.shade200,
                borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(18)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isNew
                                ? const Color(0xFF3949AB).withOpacity(0.1)
                                : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isNew
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_rounded,
                            size: 18,
                            color: isNew
                                ? const Color(0xFF3949AB)
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.subject,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isNew
                                  ? const Color(0xFF1A237E)
                                  : const Color(0xFF333333),
                            ),
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3949AB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'جديد',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    if (item.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Text(
                          item.date,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
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
        .fadeIn(delay: Duration(milliseconds: 50 * (index % 10)))
        .slideY(begin: 0.12);
  }
}

class _Chip extends StatelessWidget {
  final String label, suffix;
  final IconData icon;
  final Color color;
  const _Chip({
    required this.label,
    required this.suffix,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            Text('$label $suffix',
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
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
            Icon(Icons.notifications_none_rounded,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('لا توجد إشعارات',
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('ستظهر الإشعارات هنا عند إضافتها',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );
}
