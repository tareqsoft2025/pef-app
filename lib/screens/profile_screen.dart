import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/profile_service.dart';
import 'contracts_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String nationalId;
  final String employeeName;

  const ProfileScreen({
    super.key,
    required this.nationalId,
    required this.employeeName,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  EmployeeProfile? _profile;
  bool _loading = true;
  bool _error = false;
  bool _editMode = false;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  // ── وحدات التحكم بالحقول القابلة للتعديل ─────────────
  final Map<String, TextEditingController> _c = {
    'employeeNumber': TextEditingController(),
    'name':           TextEditingController(),
    'birthDate':      TextEditingController(),
    'nameEn':         TextEditingController(),
    'birthPlace':     TextEditingController(),
    'gender':         TextEditingController(),
    'city':           TextEditingController(),
    'street':         TextEditingController(),
    'phone':          TextEditingController(),
    'mobile':         TextEditingController(),
    'maritalStatus':  TextEditingController(),
    'specialization': TextEditingController(),
    'degree':         TextEditingController(),
    'workNature1':    TextEditingController(),
    'familyCount':    TextEditingController(),
    'userId':         TextEditingController(),
    'skills':         TextEditingController(),
    'responsibilities': TextEditingController(),
    'workNature':     TextEditingController(),
    'riskLevel':      TextEditingController(),
    'effortFactor':   TextEditingController(),
    'workExperience': TextEditingController(),
    'otherExperience': TextEditingController(),
    'jobNumber':      TextEditingController(),
    'startDate':      TextEditingController(),
    'allowance':      TextEditingController(),
    'qualifications': TextEditingController(),
    'msgStatus':      TextEditingController(),
    'bankAccount':    TextEditingController(),
    'ePriv':          TextEditingController(),
    'jobPos':         TextEditingController(),
    'repprsn':        TextEditingController(),
    'riskprs':        TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final ctrl in _c.values) ctrl.dispose();
    super.dispose();
  }

  void _populate(EmployeeProfile p) {
    _c['employeeNumber']!.text   = p.employeeNumber;
    _c['name']!.text             = p.name;
    _c['birthDate']!.text        = p.birthDate;
    _c['nameEn']!.text           = p.nameEn;
    _c['birthPlace']!.text       = p.birthPlace;
    _c['gender']!.text           = p.gender;
    _c['city']!.text             = p.city;
    _c['street']!.text           = p.street;
    _c['phone']!.text            = p.phone;
    _c['mobile']!.text           = p.mobile;
    _c['maritalStatus']!.text    = p.maritalStatus;
    _c['specialization']!.text   = p.specialization;
    _c['degree']!.text           = p.degree;
    _c['workNature1']!.text      = p.workNature1;
    _c['familyCount']!.text      = p.familyCount;
    _c['userId']!.text           = p.userId;
    _c['skills']!.text           = p.skills;
    _c['responsibilities']!.text = p.responsibilities;
    _c['workNature']!.text       = p.workNature;
    _c['riskLevel']!.text        = p.riskLevel;
    _c['effortFactor']!.text     = p.effortFactor;
    _c['workExperience']!.text   = p.workExperience;
    _c['otherExperience']!.text  = p.otherExperience;
    _c['jobNumber']!.text        = p.jobNumber;
    _c['startDate']!.text        = p.startDate;
    _c['allowance']!.text        = p.allowance;
    _c['qualifications']!.text   = p.qualifications;
    _c['msgStatus']!.text        = p.msgStatus;
    _c['bankAccount']!.text      = p.bankAccount;
    _c['ePriv']!.text            = p.ePriv;
    _c['jobPos']!.text           = p.jobPos;
    _c['repprsn']!.text          = p.repprsn;
    _c['riskprs']!.text          = p.riskprs;
  }

  EmployeeProfile _buildFromCtrl() => EmployeeProfile(
    employeeNumber:   _c['employeeNumber']!.text.trim(),
    name:             _c['name']!.text.trim(),
    nationalId:       widget.nationalId,
    birthDate:        _c['birthDate']!.text.trim(),
    nameEn:           _c['nameEn']!.text.trim(),
    birthPlace:       _c['birthPlace']!.text.trim(),
    gender:           _c['gender']!.text.trim(),
    city:             _c['city']!.text.trim(),
    street:           _c['street']!.text.trim(),
    phone:            _c['phone']!.text.trim(),
    mobile:           _c['mobile']!.text.trim(),
    maritalStatus:    _c['maritalStatus']!.text.trim(),
    specialization:   _c['specialization']!.text.trim(),
    degree:           _c['degree']!.text.trim(),
    workNature1:      _c['workNature1']!.text.trim(),
    familyCount:      _c['familyCount']!.text.trim(),
    userId:           _c['userId']!.text.trim(),
    skills:           _c['skills']!.text.trim(),
    responsibilities: _c['responsibilities']!.text.trim(),
    workNature:       _c['workNature']!.text.trim(),
    riskLevel:        _c['riskLevel']!.text.trim(),
    effortFactor:     _c['effortFactor']!.text.trim(),
    workExperience:   _c['workExperience']!.text.trim(),
    otherExperience:  _c['otherExperience']!.text.trim(),
    jobNumber:        _c['jobNumber']!.text.trim(),
    startDate:        _c['startDate']!.text.trim(),
    allowance:        _c['allowance']!.text.trim(),
    qualifications:   _c['qualifications']!.text.trim(),
    msgStatus:        _c['msgStatus']!.text.trim(),
    bankAccount:      _c['bankAccount']!.text.trim(),
    ePriv:            _c['ePriv']!.text.trim(),
    jobPos:           _c['jobPos']!.text.trim(),
    repprsn:          _c['repprsn']!.text.trim(),
    riskprs:          _c['riskprs']!.text.trim(),
  );

  // ── تحميل البيانات ─────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    final p = await ProfileService.fetchProfile(widget.nationalId);
    if (mounted) {
      setState(() {
        _profile = p;
        _loading = false;
        _error = p == null;
      });
      if (p != null) _populate(p);
    }
  }

  // ── دخول وضع التعديل ──────────────────────────────────
  void _enterEdit() {
    if (_profile != null) _populate(_profile!);
    setState(() => _editMode = true);
  }

  // ── إلغاء التعديل ─────────────────────────────────────
  void _cancelEdit() {
    if (_profile != null) _populate(_profile!);
    setState(() => _editMode = false);
  }

  // ── حفظ التعديلات ─────────────────────────────────────
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final updated = _buildFromCtrl();
    final ok = await ProfileService.updateProfile(widget.nationalId, updated);

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) {
        _profile = updated;
        _editMode = false;
      }
    });
    _showSaveResult(ok);
  }

  void _showSaveResult(bool ok) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: (ok ? const Color(0xFF43A047) : Colors.orange)
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ok ? Icons.check_circle_rounded : Icons.cloud_off_rounded,
                  size: 38,
                  color: ok ? const Color(0xFF43A047) : Colors.orange,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ok ? 'تم حفظ التعديلات بنجاح' : 'تعذّر الحفظ — تحقق من الاتصال',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ok ? const Color(0xFF2E7D32) : Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ok
                        ? const Color(0xFF43A047)
                        : const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('حسناً',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Column(
        children: [
          // ── الهيدر ───────────────────────────────────────
          _buildHeader(),

          // ── المحتوى ──────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0D47A1), strokeWidth: 2.5))
                : _error
                    ? _ErrorState(onRetry: _load)
                    : _editMode
                        ? _buildEditForm()
                        : _buildViewList(),
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
          colors: [Color(0xFF071235), Color(0xFF0D2B6B), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Column(
            children: [
              // شريط الأزرار
              Row(
                children: [
                  IconButton(
                    onPressed: _editMode ? _cancelEdit : () => Navigator.pop(context),
                    icon: Icon(
                      _editMode ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                      color: _editMode ? Colors.red.shade300 : Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _editMode ? 'تعديل البيانات' : 'بياناتي',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_editMode)
                    _saving
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            onPressed: _save,
                            icon: const Icon(Icons.check_rounded,
                                color: Colors.greenAccent, size: 26),
                            tooltip: 'حفظ',
                          )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_loading && !_error) ...[
                          // زر العقود
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ContractsScreen(
                                  nationalId: widget.nationalId,
                                  employeeName: widget.employeeName,
                                ),
                              ),
                            ),
                            icon: const Icon(
                                Icons.description_rounded,
                                color: Colors.greenAccent,
                                size: 22),
                            tooltip: 'عقودي',
                          ),
                          // زر التعديل
                          IconButton(
                            onPressed: _enterEdit,
                            icon: const Icon(Icons.edit_rounded,
                                color: Colors.white70, size: 20),
                            tooltip: 'تعديل',
                          ),
                        ],
                        IconButton(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white38, size: 20),
                          tooltip: 'تحديث',
                        ),
                      ],
                    ),
                ],
              ),

              // بطاقة الموظف (تظهر بعد التحميل)
              if (!_loading && _profile != null) ...[
                const SizedBox(height: 10),
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
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _editMode
                                  ? (_c['name']!.text.isNotEmpty
                                      ? _c['name']!.text
                                      : widget.employeeName)
                                  : (_profile!.name.isNotEmpty
                                      ? _profile!.name
                                      : widget.employeeName),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (_profile!.nameEn.isNotEmpty)
                              Text(_profile!.nameEn,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 11)),
                          ],
                        ),
                      ),
                      // رقم الهوية محمي دائماً
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(widget.nationalId,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded,
                                    size: 10,
                                    color: Colors.white.withOpacity(0.5)),
                                const SizedBox(width: 3),
                                Text('رقم الهوية',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 9)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                // شريط التعديل
                if (_editMode) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded,
                            color: Colors.amber.shade200, size: 16),
                        const SizedBox(width: 6),
                        Text('وضع التعديل — رقم الهوية محمي',
                            style: TextStyle(
                                color: Colors.amber.shade200,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ══ قائمة العرض ══════════════════════════════════════════
  Widget _buildViewList() => RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF0D47A1),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _ViewSection(
              title: 'البيانات الشخصية',
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF1565C0),
              fields: [
                _F('رقم الموظف',       _profile!.employeeNumber,  Icons.numbers_rounded),
                _F('رقم الهوية',       _profile!.nationalId,      Icons.badge_outlined),
                _F('تاريخ الميلاد',    _profile!.birthDate,       Icons.cake_outlined),
                _F('مكان الميلاد',     _profile!.birthPlace,      Icons.location_city_outlined),
                _F('الجنس',            _profile!.gender,          Icons.wc_rounded),
                _F('الحالة الاجتماعية', _profile!.maritalStatus,  Icons.favorite_border_rounded),
                _F('عدد أفراد الأسرة', _profile!.familyCount,    Icons.group_outlined),
              ],
            ),
            _ViewSection(
              title: 'معلومات الاتصال',
              icon: Icons.contact_phone_outlined,
              color: const Color(0xFF2E7D32),
              fields: [
                _F('المدينة',  _profile!.city,   Icons.location_on_outlined),
                _F('الشارع',   _profile!.street, Icons.signpost_outlined),
                _F('التلفون',  _profile!.phone,  Icons.phone_outlined),
                _F('الجوال',   _profile!.mobile, Icons.smartphone_rounded),
              ],
            ),
            _ViewSection(
              title: 'المؤهلات والخبرة',
              icon: Icons.school_outlined,
              color: const Color(0xFF6A1B9A),
              fields: [
                _F('التخصص',       _profile!.specialization, Icons.auto_stories_outlined),
                _F('الدرجة العلمية', _profile!.degree,       Icons.military_tech_outlined),
                _F('المؤهلات',     _profile!.qualifications, Icons.workspace_premium_outlined),
                _F('الخبرة العملية', _profile!.workExperience.isNotEmpty ? '${_profile!.workExperience} سنوات' : '', Icons.work_history_outlined),
                _F('خبرات أخرى',   _profile!.otherExperience.isNotEmpty ? '${_profile!.otherExperience} سنوات' : '', Icons.timeline_rounded),
                _F('المهارات',     _profile!.skills,         Icons.psychology_outlined),
              ],
            ),
            _ViewSection(
              title: 'البيانات الوظيفية',
              icon: Icons.work_outline_rounded,
              color: const Color(0xFFE65100),
              fields: [
                _F('رقم الوظيفة',   _profile!.jobNumber,       Icons.tag_rounded),
                _F('طبيعة العمل',   _profile!.workNature,      Icons.business_center_outlined),
                _F('طبيعة العمل 1', _profile!.workNature1,     Icons.business_outlined),
                _F('المسؤوليات',    _profile!.responsibilities, Icons.assignment_outlined),
                _F('تاريخ البدء',   _profile!.startDate,       Icons.calendar_today_outlined),
                _F('العلاوة',       _profile!.allowance,       Icons.payments_outlined),
                _F('رقم المستخدم',  _profile!.userId,          Icons.manage_accounts_outlined),
              ],
            ),
            _ViewSection(
              title: 'التقييم والمخاطر',
              icon: Icons.analytics_outlined,
              color: const Color(0xFF00838F),
              fields: [
                _F('مستوى المخاطر',     _profile!.riskLevel,    Icons.warning_amber_rounded),
                _F('معامل تقييم الجهد', _profile!.effortFactor, Icons.speed_rounded),
                _F('Riskprs',           _profile!.riskprs,      Icons.shield_outlined),
                _F('Repprsn',           _profile!.repprsn,      Icons.supervisor_account_outlined),
              ],
            ),
            _ViewSection(
              title: 'بيانات إضافية',
              icon: Icons.info_outline_rounded,
              color: const Color(0xFF546E7A),
              fields: [
                _F('رقم الحساب البنكي', _profile!.bankAccount, Icons.account_balance_outlined),
                _F('حالة الرسالة',      _profile!.msgStatus,   Icons.mark_email_read_outlined),
                _F('EPriv',             _profile!.ePriv,       Icons.lock_outline_rounded),
                _F('JobPos',            _profile!.jobPos,      Icons.work_outlined),
              ],
            ),

            // ── بطاقة العقود ──────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContractsScreen(
                    nationalId: widget.nationalId,
                    employeeName: widget.employeeName,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B5E20).withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('عقودي',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          Text('عرض وتفاصيل العقود الوظيفية',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white54, size: 16),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          ],
        ),
      );

  // ══ نموذج التعديل ════════════════════════════════════════
  Widget _buildEditForm() => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // حقل رقم الهوية — محمي (غير قابل للتعديل)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 10),
                  Text('رقم الهوية',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500)),
                  const Spacer(),
                  Text(widget.nationalId,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF555555),
                          letterSpacing: 1)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('محمي',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600)),
                  ),
                ],
              ),
            ),

            _EditSection(
              title: 'البيانات الشخصية',
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF1565C0),
              fields: [
                _EF('رقم الموظف',       _c['employeeNumber']!, Icons.numbers_rounded),
                _EF('الاسم',            _c['name']!,           Icons.person_outlined),
                _EF('الاسم بالإنجليزية', _c['nameEn']!,        Icons.translate_rounded, ltr: true),
                _EF('تاريخ الميلاد',    _c['birthDate']!,      Icons.cake_outlined),
                _EF('مكان الميلاد',     _c['birthPlace']!,     Icons.location_city_outlined),
                _EF('الجنس',            _c['gender']!,         Icons.wc_rounded),
                _EF('الحالة الاجتماعية', _c['maritalStatus']!, Icons.favorite_border_rounded),
                _EF('عدد أفراد الأسرة', _c['familyCount']!,    Icons.group_outlined, num: true),
              ],
            ),
            _EditSection(
              title: 'معلومات الاتصال',
              icon: Icons.contact_phone_outlined,
              color: const Color(0xFF2E7D32),
              fields: [
                _EF('المدينة', _c['city']!,   Icons.location_on_outlined),
                _EF('الشارع',  _c['street']!, Icons.signpost_outlined),
                _EF('التلفون', _c['phone']!,  Icons.phone_outlined, num: true, ltr: true),
                _EF('الجوال',  _c['mobile']!, Icons.smartphone_rounded, num: true, ltr: true),
              ],
            ),
            _EditSection(
              title: 'المؤهلات والخبرة',
              icon: Icons.school_outlined,
              color: const Color(0xFF6A1B9A),
              fields: [
                _EF('التخصص',         _c['specialization']!, Icons.auto_stories_outlined),
                _EF('الدرجة العلمية', _c['degree']!,         Icons.military_tech_outlined),
                _EF('المؤهلات',       _c['qualifications']!, Icons.workspace_premium_outlined, multi: true),
                _EF('الخبرة العملية (سنوات)', _c['workExperience']!, Icons.work_history_outlined, num: true),
                _EF('خبرات أخرى (سنوات)',     _c['otherExperience']!, Icons.timeline_rounded, num: true),
                _EF('المهارات',       _c['skills']!,         Icons.psychology_outlined, multi: true),
              ],
            ),
            _EditSection(
              title: 'البيانات الوظيفية',
              icon: Icons.work_outline_rounded,
              color: const Color(0xFFE65100),
              fields: [
                _EF('رقم الوظيفة',   _c['jobNumber']!,       Icons.tag_rounded, num: true),
                _EF('طبيعة العمل',   _c['workNature']!,      Icons.business_center_outlined),
                _EF('طبيعة العمل 1', _c['workNature1']!,     Icons.business_outlined),
                _EF('المسؤوليات',    _c['responsibilities']!, Icons.assignment_outlined, multi: true),
                _EF('تاريخ البدء',   _c['startDate']!,       Icons.calendar_today_outlined),
                _EF('العلاوة',       _c['allowance']!,       Icons.payments_outlined),
                _EF('رقم المستخدم',  _c['userId']!,          Icons.manage_accounts_outlined),
              ],
            ),
            _EditSection(
              title: 'التقييم والمخاطر',
              icon: Icons.analytics_outlined,
              color: const Color(0xFF00838F),
              fields: [
                _EF('مستوى المخاطر',     _c['riskLevel']!,    Icons.warning_amber_rounded),
                _EF('معامل تقييم الجهد', _c['effortFactor']!, Icons.speed_rounded),
                _EF('Riskprs', _c['riskprs']!, Icons.shield_outlined),
                _EF('Repprsn', _c['repprsn']!, Icons.supervisor_account_outlined),
              ],
            ),
            _EditSection(
              title: 'بيانات إضافية',
              icon: Icons.info_outline_rounded,
              color: const Color(0xFF546E7A),
              fields: [
                _EF('رقم الحساب البنكي', _c['bankAccount']!, Icons.account_balance_outlined, ltr: true),
                _EF('حالة الرسالة',      _c['msgStatus']!,   Icons.mark_email_read_outlined),
                _EF('EPriv',  _c['ePriv']!,  Icons.lock_outline_rounded, ltr: true),
                _EF('JobPos', _c['jobPos']!, Icons.work_outlined, ltr: true),
              ],
            ),

            // زر الحفظ في أسفل القائمة
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(_saving ? 'جاري الحفظ...' : 'حفظ التعديلات',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF0D47A1).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
}

// ══ نماذج بيانات ════════════════════════════════════════════
class _F {
  final String label, value;
  final IconData icon;
  const _F(this.label, this.value, this.icon);
}

class _EF {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final bool num, ltr, multi;
  const _EF(this.label, this.ctrl, this.icon,
      {this.num = false, this.ltr = false, this.multi = false});
}

// ══ قسم العرض ════════════════════════════════════════════════
class _ViewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_F> fields;

  const _ViewSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final visible = fields.where((f) => f.value.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, icon: icon, color: color,
              count: visible.length),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Column(
                children: visible.map((f) => _ViewRow(f: f)).toList()),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

// ══ قسم التعديل ══════════════════════════════════════════════
class _EditSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_EF> fields;

  const _EditSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            _SectionHeader(
                title: title, icon: icon, color: color,
                count: fields.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: Column(
                  children: fields
                      .map((f) => _EditRow(ef: f, color: color))
                      .toList()),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms);
}

// ══ رأس القسم ════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}

// ══ صف عرض ═══════════════════════════════════════════════════
class _ViewRow extends StatelessWidget {
  final _F f;
  const _ViewRow({super.key, required this.f});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(f.icon, size: 15, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            SizedBox(
              width: 115,
              child: Text(f.label,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(f.value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
            ),
          ],
        ),
      );
}

// ══ صف تعديل ═════════════════════════════════════════════════
class _EditRow extends StatelessWidget {
  final _EF ef;
  final Color color;
  const _EditRow({super.key, required this.ef, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextFormField(
          controller: ef.ctrl,
          textDirection:
              ef.ltr ? TextDirection.ltr : TextDirection.rtl,
          textAlign: TextAlign.right,
          keyboardType: ef.num
              ? TextInputType.number
              : ef.multi
                  ? TextInputType.multiline
                  : TextInputType.text,
          maxLines: ef.multi ? 3 : 1,
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF1A1A2E)),
          decoration: InputDecoration(
            labelText: ef.label,
            labelStyle: TextStyle(
                fontSize: 12, color: Colors.grey.shade500),
            prefixIcon: Icon(ef.icon,
                size: 17, color: color.withOpacity(0.6)),
            filled: true,
            fillColor: color.withOpacity(0.04),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
      );
}

// ══ حالة الخطأ ═══════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1).withOpacity(0.08),
                    shape: BoxShape.circle),
                child: const Icon(Icons.person_search_rounded,
                    size: 40, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 20),
              const Text('لم يتم العثور على بياناتك',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 10),
              Text('تأكد من وجود بياناتك في نظام الموارد البشرية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
}
