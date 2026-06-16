import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/language_provider.dart';
import '../../core/user_session.dart';
import '../../core/api_client.dart';

const Color kNavy = Color(0xFF243F73);
const Color kTextNavy = Color(0xFF152A5C);
const Color kPurple = Color(0xFF777FC8);

// ── 모델 ──────────────────────────────────────────────────────
class QrProfile {
  final String name;
  final String gender;
  final int age;
  final String bloodType;
  final String nationality;
  final List<EmergencyContact> contacts;
  final List<MedicalInfo> medicalInfos;

  QrProfile({
    required this.name,
    required this.gender,
    required this.age,
    required this.bloodType,
    required this.nationality,
    required this.contacts,
    required this.medicalInfos,
  });

  factory QrProfile.fromJson(Map<String, dynamic> json) {
    return QrProfile(
      name: json['name'] ?? '',
      gender: json['gender'] ?? '',
      age: json['age'] ?? 0,
      bloodType: json['blood_type'] ?? '',
      nationality: json['nationality'] ?? '',
      contacts: (json['emergency_contacts'] as List? ?? [])
          .map((e) => EmergencyContact.fromJson(e))
          .toList(),
      medicalInfos: (json['medical_infos'] as List? ?? [])
          .map((e) => MedicalInfo.fromJson(e))
          .toList(),
    );
  }
}

class EmergencyContact {
  final int id;
  String name;
  String relationship;
  String phone;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'phone': phone,
      };
}

class MedicalInfo {
  final int id;
  String category; // 'allergy' | 'condition'
  String value;

  MedicalInfo({required this.id, required this.category, required this.value});

  factory MedicalInfo.fromJson(Map<String, dynamic> json) {
    return MedicalInfo(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'category': category, 'value': value};
}

// ── QrResultScreen ────────────────────────────────────────────
class QrResultScreen extends StatefulWidget {
  const QrResultScreen({super.key});

  @override
  State<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends State<QrResultScreen> {
  QrProfile? _profile;
  bool _isLoading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    // 삭제한 적 있으면 서버 호출 안 함
    final isDeleted = prefs.getBool('qr_deleted') ?? false;
    if (isDeleted) {
      setState(() { _hasProfile = false; _isLoading = false; });
      return;
    }

    // 1. 로컬 캐시 먼저
    final localData = prefs.getString('qr_profile');
    if (localData != null) {
      try {
        final profile = QrProfile.fromJson(jsonDecode(localData));
        if (profile.name.isNotEmpty) {
          setState(() {
            _profile = profile;
            _hasProfile = true;
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }

    // 2. API 시도
    final userId = UserSession.userId;
    if (userId == null) {
      setState(() { _hasProfile = false; _isLoading = false; });
      return;
    }

    try {
      final data = await ApiClient.get('/users/$userId/qr-profile');
      final profile = QrProfile.fromJson(data);
      await prefs.setString('qr_profile', jsonEncode(data));
      setState(() {
        _profile = profile;
        _hasProfile = profile.name.isNotEmpty;
        _isLoading = false;
      });
    } catch (_) {
      setState(() { _hasProfile = false; _isLoading = false; });
    }
  }

  Future<void> _deleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text('All emergency info will be deleted. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFC94A4A))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 로컬 캐시 삭제 + deleted 플래그 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('qr_profile');
    await prefs.setBool('qr_deleted', true);

    // 서버에 빈 프로필 저장 (삭제 대신)
    final userId = UserSession.userId;
    if (userId != null) {
      try {
        await ApiClient.post('/users/$userId/qr-profile', {
          'name': '', 'gender': '', 'age': 0, 'blood_type': '',
          'nationality': '', 'emergency_contacts': [], 'medical_infos': [],
        });
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _profile = null;
        _hasProfile = false;
      });
    }
  }

  void _openEditSheet(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: lang,
        child: _EditSheet(
          profile: _profile,
          onSaved: (updatedProfile) {
            Navigator.pop(context);
            setState(() {
              _profile = updatedProfile;
              _hasProfile = true;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: SafeArea(
        child: Column(
          children: [
            _Header(lang: lang),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kNavy))
                  : _hasProfile && _profile != null
                      ? _ProfileView(
                          profile: _profile!,
                          lang: lang,
                          onEdit: () => _openEditSheet(context),
                          onDelete: _deleteProfile,
                        )
                      : _EmptyView(
                          lang: lang,
                          onSetup: () => _openEditSheet(context),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final LanguageProvider lang;
  const _Header({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: kNavy,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lang.t('emergency_info'),
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(lang.t('scanned_from'),
                  style: const TextStyle(color: Color(0xFFC9D3F1), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 미등록 화면 ───────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final LanguageProvider lang;
  final VoidCallback onSetup;
  const _EmptyView({required this.lang, required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFEEF0FB), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.qr_code_2, color: kNavy, size: 44),
          ),
          const SizedBox(height: 24),
          Text(lang.t('qr_not_setup'),
              style: const TextStyle(color: kTextNavy, fontSize: 20, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(lang.t('qr_not_setup_sub'),
              style: const TextStyle(color: kPurple, fontSize: 14, height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: kNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(lang.t('setup_my_info'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 프로필 화면 ───────────────────────────────────────────────
class _ProfileView extends StatelessWidget {
  final QrProfile profile;
  final LanguageProvider lang;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileView({required this.profile, required this.lang, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final allergies = profile.medicalInfos.where((m) => m.category == 'allergy').toList();
    final conditions = profile.medicalInfos.where((m) => m.category == 'condition').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        children: [
          // 기본 정보
          _card(child: Column(children: [
            Row(children: [
              CircleAvatar(
                radius: 30, backgroundColor: kNavy,
                child: const Icon(Icons.person_outline, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 18),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile.name, style: const TextStyle(color: kTextNavy, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${profile.nationality} · ${profile.gender} · ${profile.age}',
                    style: const TextStyle(color: kPurple, fontSize: 13, fontWeight: FontWeight.w700)),
              ])),
            ]),
            const SizedBox(height: 18),
            const Divider(color: Color(0xFFE5E7F2)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _infoBox(title: lang.t('blood_type'),
                  value: profile.bloodType.isEmpty ? '-' : profile.bloodType,
                  valueColor: const Color(0xFFC0392B))),
              const SizedBox(width: 12),
              Expanded(child: _infoBox(title: lang.t('nationality'),
                  value: profile.nationality.isEmpty ? '-' : profile.nationality,
                  valueColor: kTextNavy)),
            ]),
          ])),

          // 긴급 연락처
          if (profile.contacts.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cardTitle(lang.t('emergency_contacts')),
              const SizedBox(height: 12),
              ...profile.contacts.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _contactRow(c),
              )),
            ])),
          ],

          // 의료 정보
          if (allergies.isNotEmpty || conditions.isNotEmpty) ...[
            const SizedBox(height: 14),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _cardTitle(lang.t('medical_info')),
              if (allergies.isNotEmpty) ...[
                const SizedBox(height: 14),
                _subTitle(lang.t('allergies')),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8,
                    children: allergies.map((m) => _chip(m.value, const Color(0xFFFFE5E5), const Color(0xFFC94A4A))).toList()),
              ],
              if (conditions.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFE5E7F2)),
                const SizedBox(height: 12),
                _subTitle(lang.t('conditions')),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8,
                    children: conditions.map((m) => _chip(m.value, const Color(0xFFE9E9FB), const Color(0xFF5D65B3))).toList()),
              ],
            ])),
          ],

          const SizedBox(height: 14),
          // 경고
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD89C)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD36B2C), size: 23),
              const SizedBox(width: 12),
              Expanded(child: Text(lang.t('qr_warning'),
                  style: const TextStyle(color: Color(0xFFC1632A), fontSize: 14, fontWeight: FontWeight.w700, height: 1.35))),
            ]),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
              label: Text(lang.t('edit_my_info'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Color(0xFFC94A4A), size: 18),
              label: const Text('Delete Profile',
                  style: TextStyle(color: Color(0xFFC94A4A), fontSize: 16, fontWeight: FontWeight.w900)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFC94A4A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(EmergencyContact c) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.name, style: const TextStyle(color: kTextNavy, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text('${c.relationship} · ${c.phone}',
            style: const TextStyle(color: Color(0xFF8B92CF), fontSize: 12, fontWeight: FontWeight.w700)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(9)),
        child: const Row(children: [
          Icon(Icons.call, color: Colors.white, size: 15),
          SizedBox(width: 5),
          Text('Call', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
        ]),
      ),
    ]);
  }

  Widget _infoBox({required String title, required String value, required Color valueColor}) {
    return Container(
      height: 82, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF6F7FC), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xFFB2B6DA), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, height: 1.15)),
        const Spacer(),
        Text(value, style: TextStyle(color: valueColor, fontSize: 17, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE1E4EF))),
    child: child,
  );

  Widget _cardTitle(String text) => Text(text,
      style: const TextStyle(color: Color(0xFF8A91CD), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2));

  Widget _subTitle(String text) => Text(text,
      style: const TextStyle(color: Color(0xFFB2B6DA), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.1));

  Widget _chip(String text, Color bgColor, Color textColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
    child: Text(text, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w900)),
  );
}

// ── 편집 바텀시트 ──────────────────────────────────────────────
class _EditSheet extends StatefulWidget {
  final QrProfile? profile;
  final void Function(QrProfile) onSaved;
  const _EditSheet({this.profile, required this.onSaved});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  // 기본 정보
  final _nameCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'male';
  String _bloodType = 'A+';

  // 긴급 연락처 (최대 3개)
  final List<Map<String, TextEditingController>> _contacts = [];

  // 의료 정보
  final List<Map<String, TextEditingController>> _allergies = [];
  final List<Map<String, TextEditingController>> _conditions = [];

  bool _isSaving = false;

  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    if (p != null) {
      _nameCtrl.text = p.name;
      _nationalityCtrl.text = p.nationality;
      _ageCtrl.text = p.age > 0 ? p.age.toString() : '';
      _gender = p.gender.isNotEmpty ? p.gender : 'male';
      _bloodType = p.bloodType.isNotEmpty ? p.bloodType : 'A+';

      // 기존 연락처 로드
      for (final c in p.contacts) {
        _contacts.add({
          'name': TextEditingController(text: c.name),
          'relationship': TextEditingController(text: c.relationship),
          'phone': TextEditingController(text: c.phone),
        });
      }

      // 기존 의료 정보 로드
      for (final m in p.medicalInfos) {
        final ctrl = {'value': TextEditingController(text: m.value)};
        if (m.category == 'allergy') {
          _allergies.add(ctrl);
        } else {
          _conditions.add(ctrl);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalityCtrl.dispose();
    _ageCtrl.dispose();
    for (final c in _contacts) {
      c.values.forEach((ctrl) => ctrl.dispose());
    }
    for (final a in _allergies) {
      a.values.forEach((ctrl) => ctrl.dispose());
    }
    for (final c in _conditions) {
      c.values.forEach((ctrl) => ctrl.dispose());
    }
    super.dispose();
  }

  void _addContact() {
    if (_contacts.length >= 3) return;
    setState(() {
      _contacts.add({
        'name': TextEditingController(),
        'relationship': TextEditingController(),
        'phone': TextEditingController(),
      });
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts[index].values.forEach((ctrl) => ctrl.dispose());
      _contacts.removeAt(index);
    });
  }

  void _addAllergy() {
    setState(() => _allergies.add({'value': TextEditingController()}));
  }

  void _removeAllergy(int index) {
    setState(() {
      _allergies[index]['value']!.dispose();
      _allergies.removeAt(index);
    });
  }

  void _addCondition() {
    setState(() => _conditions.add({'value': TextEditingController()}));
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions[index]['value']!.dispose();
      _conditions.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    // 연락처 데이터
    final contactsData = _contacts
        .where((c) => c['name']!.text.trim().isNotEmpty)
        .map((c) => {
              'id': 0,
              'name': c['name']!.text.trim(),
              'relationship': c['relationship']!.text.trim(),
              'phone': c['phone']!.text.trim(),
            })
        .toList();

    // 의료 정보 데이터
    final medicalData = [
      ..._allergies
          .where((a) => a['value']!.text.trim().isNotEmpty)
          .map((a) => {'id': 0, 'category': 'allergy', 'value': a['value']!.text.trim()}),
      ..._conditions
          .where((c) => c['value']!.text.trim().isNotEmpty)
          .map((c) => {'id': 0, 'category': 'condition', 'value': c['value']!.text.trim()}),
    ];

    final profileData = {
      'name': _nameCtrl.text.trim(),
      'gender': _gender,
      'age': int.tryParse(_ageCtrl.text) ?? 0,
      'blood_type': _bloodType,
      'nationality': _nationalityCtrl.text.trim(),
      'emergency_contacts': contactsData,
      'medical_infos': medicalData,
    };

    // 로컬 저장 (항상) + deleted 플래그 제거
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('qr_deleted');
    await prefs.setString('qr_profile', jsonEncode(profileData));

    // 서버 저장 시도
    final userId = UserSession.userId;
    if (userId != null) {
      try {
        await ApiClient.post('/users/$userId/qr-profile', profileData);
      } catch (_) {}
    }

    setState(() => _isSaving = false);
    widget.onSaved(QrProfile.fromJson(profileData));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Text(lang.t('edit_my_info'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kTextNavy)),
            const SizedBox(height: 20),

            // ── 기본 정보 ──────────────────────────────────────
            _sectionHeader(lang.t('basic_info')),
            const SizedBox(height: 12),
            _label(lang.t('name')),
            _textField(_nameCtrl, lang.t('name_hint')),
            const SizedBox(height: 14),
            _label(lang.t('nationality')),
            _textField(_nationalityCtrl, lang.t('nationality_hint')),
            const SizedBox(height: 14),
            _label(lang.t('age')),
            _textField(_ageCtrl, lang.t('age_hint'), keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            _label(lang.t('gender')),
            Row(children: [
              _genderChip(lang.t('male'), 'male'),
              const SizedBox(width: 10),
              _genderChip(lang.t('female'), 'female'),
            ]),
            const SizedBox(height: 14),
            _label(lang.t('blood_type')),
            Wrap(spacing: 8, runSpacing: 8, children: _bloodTypes.map(_bloodChip).toList()),

            const SizedBox(height: 24),

            // ── 긴급 연락처 ────────────────────────────────────
            _sectionHeader(lang.t('emergency_contacts')),
            const SizedBox(height: 12),
            ..._contacts.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${lang.t('contact')} ${i + 1}',
                        style: const TextStyle(color: kPurple, fontSize: 12, fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => _removeContact(i),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFF9AA5B4)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _label(lang.t('name')),
                  _textField(c['name']!, lang.t('name_hint')),
                  const SizedBox(height: 10),
                  _label(lang.t('relationship')),
                  _textField(c['relationship']!, lang.t('relationship_hint')),
                  const SizedBox(height: 10),
                  _label(lang.t('phone')),
                  _textField(c['phone']!, lang.t('phone_hint'), keyboardType: TextInputType.phone),
                ]),
              );
            }),
            if (_contacts.length < 3)
              _addButton(lang.t('add_contact'), _addContact),

            const SizedBox(height: 24),

            // ── 알레르기 ────────────────────────────────────────
            _sectionHeader(lang.t('allergies')),
            const SizedBox(height: 12),
            ..._allergies.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(child: _textField(_allergies[i]['value']!, lang.t('allergy_hint'))),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeAllergy(i),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE5E5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFFC94A4A)),
                    ),
                  ),
                ]),
              );
            }),
            _addButton(lang.t('add_allergy'), _addAllergy),

            const SizedBox(height: 24),

            // ── 특이사항/질환 ────────────────────────────────────
            _sectionHeader(lang.t('conditions')),
            const SizedBox(height: 12),
            ..._conditions.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(child: _textField(_conditions[i]['value']!, lang.t('condition_hint'))),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeCondition(i),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E9FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFF5D65B3)),
                    ),
                  ),
                ]),
              );
            }),
            _addButton(lang.t('add_condition'), _addCondition),

            const SizedBox(height: 28),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(lang.t('save'),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kNavy.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.circle, size: 6, color: kNavy),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: kNavy, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ]),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add, size: 18, color: kPurple),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: kPurple, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: kPurple, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );

  Widget _textField(TextEditingController ctrl, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB2B6DA)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kNavy, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _genderChip(String label, String value) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kNavy : const Color(0xFFF6F7FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? kNavy : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(
            color: isSelected ? Colors.white : kPurple, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }

  Widget _bloodChip(String value) {
    final isSelected = _bloodType == value;
    return GestureDetector(
      onTap: () => setState(() => _bloodType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kNavy : const Color(0xFFF6F7FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? kNavy : const Color(0xFFE2E8F0)),
        ),
        child: Text(value, style: TextStyle(
            color: isSelected ? Colors.white : kPurple, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}
