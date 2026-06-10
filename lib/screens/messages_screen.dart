import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/msg_service.dart';

class MessagesScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const MessagesScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<HrMessage> _messages = [];
  bool _loading = true;
  int _unseenOnOpen = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final unseenCount =
        await MsgService.getUnseenCount(widget.employeeId);
    final msgs = await MsgService.fetchMessages(widget.employeeId);
    await MsgService.markAllSeen(widget.employeeId, msgs.length);

    if (mounted) {
      setState(() {
        _messages = msgs;
        _unseenOnOpen = unseenCount;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1B4B),
                  Color(0xFF1565C0),
                  Color(0xFF1976D2),
                ],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 24),
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
                          child: Text('رسائل HR',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // بطاقة معلومات الموظف
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'رقم الهوية: ${widget.employeeId}',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (!_loading) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_messages.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'رسالة',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 11),
                                ),
                              ],
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
                        color: Color(0xFF1565C0)))
                : _messages.isEmpty
                    ? _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF1565C0),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) => _MessageBubble(
                            message: _messages[i],
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

// ── فقاعة رسالة ────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final HrMessage message;
  final bool isNew;
  final int index;

  const _MessageBubble({
    required this.message,
    required this.isNew,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // أفاتار HR
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'HR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // محتوى الرسالة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'إدارة الموارد البشرية',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const Spacer(),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
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
                const SizedBox(height: 6),

                // بالون الرسالة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isNew
                        ? const Color(0xFFE3F2FD)
                        : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                    border: isNew
                        ? Border.all(
                            color: const Color(0xFF1565C0).withOpacity(0.3))
                        : Border.all(color: Colors.grey.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isNew ? 0.08 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isNew
                          ? const Color(0xFF0D47A1)
                          : const Color(0xFF333333),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 * (index % 8)))
        .slideX(begin: -0.1);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mail_outline_rounded,
                  size: 44, color: Color(0xFF1565C0)),
            ),
            const SizedBox(height: 20),
            const Text('لا توجد رسائل',
                style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'ستظهر رسائل إدارة الموارد البشرية هنا',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
}
