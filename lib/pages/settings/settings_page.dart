import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_strings.dart';
import '../../core/api_client.dart';
import '../../core/user_session.dart';

const Color kNavy = Color(0xFF1B2F6E);

// ── 지역 모델 ─────────────────────────────────────────────────
class RegionInfo {
  final String code;
  final String nameEn;
  final String nameKey;
  final double? lat;
  final double? lng;

  const RegionInfo({
    required this.code,
    required this.nameEn,
    required this.nameKey,
    this.lat,
    this.lng,
  });
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _emergencyAlerts = true;
  bool _alertSound = true;
  String _selectedRegionCode = 'ALL';
  String _selectedRegionName = 'All Regions';
  double? _selectedLat;
  double? _selectedLng;
  bool _isLoadingSettings = true;
  List<RegionInfo> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // 로컬 캐시 먼저 표시
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyAlerts    = prefs.getBool('setting_alert')   ?? true;
      _alertSound         = prefs.getBool('setting_sound')   ?? true;
      _selectedRegionCode = prefs.getString('setting_region') ?? 'ALL';
      _selectedRegionName = prefs.getString('setting_region_name') ?? 'All Regions';
      _selectedLat        = prefs.getDouble('setting_lat');
      _selectedLng        = prefs.getDouble('setting_lng');
      _isLoadingSettings  = false;
    });

    // 서버에서 지역 목록 + 설정 불러오기
    await Future.wait([
      _loadRegions(),
      _loadServerSettings(),
    ]);
  }

  Future<void> _loadRegions() async {
    try {
      final data = await ApiClient.get('/regions');
      final list = data['regions'] as List<dynamic>? ?? [];
      final regions = <RegionInfo>[
        const RegionInfo(code: 'ALL', nameEn: 'All Regions', nameKey: 'region_all'),
        ...list.map((r) => RegionInfo(
          code:    r['code']      ?? '',
          nameEn:  r['name_en']   ?? '',
          nameKey: 'region_${(r['code'] ?? '').toLowerCase()}',
          lat:     (r['latitude']  as num?)?.toDouble(),
          lng:     (r['longitude'] as num?)?.toDouble(),
        )),
      ];
      setState(() => _regions = regions);
    } catch (_) {
      // 실패 시 기본 목록 사용
      setState(() => _regions = _defaultRegions);
    }
  }

  Future<void> _loadServerSettings() async {
    final userId = UserSession.userId;
    if (userId == null) return;
    try {
      final data = await ApiClient.get('/users/$userId/settings');
      final prefs = await SharedPreferences.getInstance();
      final alert  = data['alert_enabled'] ?? true;
      final sound  = data['sound_enabled'] ?? true;
      final region = data['selected_region_code'] ?? 'ALL';
      await prefs.setBool('setting_alert', alert);
      await prefs.setBool('setting_sound', sound);
      await prefs.setString('setting_region', region);
      if (mounted) setState(() {
        _emergencyAlerts    = alert;
        _alertSound         = sound;
        _selectedRegionCode = region;
      });
    } catch (_) {}
  }

  Future<void> _saveSettings({
    bool? alertEnabled,
    bool? soundEnabled,
    RegionInfo? region,
  }) async {
    final alert  = alertEnabled ?? _emergencyAlerts;
    final sound  = soundEnabled ?? _alertSound;
    final lang   = context.read<LanguageProvider>();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('setting_alert', alert);
    await prefs.setBool('setting_sound', sound);

    if (region != null) {
      await prefs.setString('setting_region', region.code);
      await prefs.setString('setting_region_name', region.nameEn);
      if (region.lat != null) await prefs.setDouble('setting_lat', region.lat!);
      if (region.lng != null) await prefs.setDouble('setting_lng', region.lng!);
    }

    final userId = UserSession.userId;
    if (userId == null) return;
    try {
      await ApiClient.put('/users/$userId/settings', {
        'alert_enabled':         alert,
        'sound_enabled':         sound,
        'language_code':         lang.currentLang,
        'selected_region_code':  region?.code ?? _selectedRegionCode,
      });
    } catch (_) {}
  }

  String _regionLabel(LanguageProvider lang) {
    if (_regions.isEmpty) {
      return lang.t('region_${_selectedRegionCode.toLowerCase()}');
    }
    final found = _regions.firstWhere(
      (r) => r.code == _selectedRegionCode,
      orElse: () => const RegionInfo(
          code: 'ALL', nameEn: 'All Regions', nameKey: 'region_all'),
    );
    return lang.t(found.nameKey).isNotEmpty &&
           lang.t(found.nameKey) != found.nameKey
        ? lang.t(found.nameKey)
        : found.nameEn;
  }

  void _showLanguagePicker(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: lang,
        child: const _LanguagePickerSheet(),
      ),
    );
  }

  void _showRegionPicker(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ChangeNotifierProvider.value(
        value: lang,
        child: _RegionPickerSheet(
          regions: _regions.isEmpty ? _defaultRegions : _regions,
          selectedCode: _selectedRegionCode,
          onSelect: (region) {
            setState(() {
              _selectedRegionCode = region.code;
              _selectedRegionName = region.nameEn;
              _selectedLat = region.lat;
              _selectedLng = region.lng;
            });
            _saveSettings(region: region);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        titleSpacing: 20,
        title: Text(lang.t('settings'),
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          _isLoadingSettings
              ? const Center(child: CircularProgressIndicator(color: kNavy))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    _SectionLabel(lang.t('language')),
                    const SizedBox(height: 8),
                    _SettingsCard(children: [
                      _TileWithChip(
                        icon: Icons.language,
                        iconBg: const Color(0xFFE8EAF6),
                        iconColor: const Color(0xFF5C6BC0),
                        title: lang.t('app_language'),
                        subtitle: lang.t('alert_translation'),
                        chipLabel: '${lang.currentFlag} ${lang.currentLangName}',
                        onTap: () => _showLanguagePicker(context),
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _SectionLabel(lang.t('notifications')),
                    const SizedBox(height: 8),
                    _SettingsCard(children: [
                      _TileWithToggle(
                        icon: Icons.notifications_outlined,
                        iconBg: const Color(0xFFFFEBEE),
                        iconColor: const Color(0xFFE53935),
                        title: lang.t('emergency_alerts'),
                        subtitle: lang.t('push_notifications'),
                        value: _emergencyAlerts,
                        onChanged: (v) {
                          setState(() => _emergencyAlerts = v);
                          _saveSettings(alertEnabled: v);
                        },
                      ),
                      const _Divider(),
                      _TileWithToggle(
                        icon: Icons.star_border,
                        iconBg: const Color(0xFFFFF8E1),
                        iconColor: const Color(0xFFFFB300),
                        title: lang.t('alert_sound'),
                        subtitle: lang.t('alarm_on_critical'),
                        value: _alertSound,
                        onChanged: _emergencyAlerts
                            ? (v) {
                                setState(() => _alertSound = v);
                                _saveSettings(soundEnabled: v);
                              }
                            : null,
                      ),
                      const _Divider(),
                      _TileWithChip(
                        icon: Icons.location_on_outlined,
                        iconBg: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF43A047),
                        title: lang.t('region'),
                        subtitle: lang.t('my_alert_area'),
                        chipLabel: _regionLabel(lang),
                        onTap: () => _showRegionPicker(context),
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _SectionLabel(lang.t('about')),
                    const SizedBox(height: 8),
                    _SettingsCard(children: [
                      _TileAbout(
                        icon: Icons.info_outline,
                        iconBg: const Color(0xFFE3F2FD),
                        iconColor: const Color(0xFF1E88E5),
                        title: lang.t('app_version'),
                        subtitle: 'ResQ',
                        trailing: 'v1.0.0',
                      ),
                    ]),
                  ],
                ),

          if (lang.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: kNavy),
                        SizedBox(height: 12),
                        Text('Translating...', style: TextStyle(color: kNavy)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 기본 지역 목록 (API 실패 시 fallback)
const List<RegionInfo> _defaultRegions = [
  RegionInfo(code: 'ALL',        nameEn: 'All Regions', nameKey: 'region_all'),
  RegionInfo(code: 'SEOUL',      nameEn: 'Seoul',       nameKey: 'region_seoul',      lat: 37.5665, lng: 126.9780),
  RegionInfo(code: 'BUSAN',      nameEn: 'Busan',       nameKey: 'region_busan',      lat: 35.1796, lng: 129.0756),
  RegionInfo(code: 'DAEGU',      nameEn: 'Daegu',       nameKey: 'region_daegu',      lat: 35.8714, lng: 128.6014),
  RegionInfo(code: 'INCHEON',    nameEn: 'Incheon',     nameKey: 'region_incheon',    lat: 37.4563, lng: 126.7052),
  RegionInfo(code: 'GWANGJU',    nameEn: 'Gwangju',     nameKey: 'region_gwangju',    lat: 35.1595, lng: 126.8526),
  RegionInfo(code: 'DAEJEON',    nameEn: 'Daejeon',     nameKey: 'region_daejeon',    lat: 36.3504, lng: 127.3845),
  RegionInfo(code: 'ULSAN',      nameEn: 'Ulsan',       nameKey: 'region_ulsan',      lat: 35.5384, lng: 129.3114),
  RegionInfo(code: 'SEJONG',     nameEn: 'Sejong',      nameKey: 'region_sejong',     lat: 36.4800, lng: 127.2890),
  RegionInfo(code: 'GYEONGGI',   nameEn: 'Gyeonggi',   nameKey: 'region_gyeonggi',   lat: 37.4138, lng: 127.5183),
  RegionInfo(code: 'GANGWON',    nameEn: 'Gangwon',     nameKey: 'region_gangwon',    lat: 37.8228, lng: 128.1555),
  RegionInfo(code: 'CHUNGBUK',   nameEn: 'Chungbuk',   nameKey: 'region_chungbuk',   lat: 36.6357, lng: 127.4917),
  RegionInfo(code: 'CHUNGNAM',   nameEn: 'Chungnam',   nameKey: 'region_chungnam',   lat: 36.5184, lng: 126.8000),
  RegionInfo(code: 'CHEONAN',    nameEn: 'Cheonan',     nameKey: 'region_cheonan',    lat: 36.8151, lng: 127.1139),
  RegionInfo(code: 'JEONBUK',    nameEn: 'Jeonbuk',     nameKey: 'region_jeonbuk',    lat: 35.7175, lng: 127.1530),
  RegionInfo(code: 'JEONNAM',    nameEn: 'Jeonnam',     nameKey: 'region_jeonnam',    lat: 34.8679, lng: 126.9910),
  RegionInfo(code: 'GYEONGBUK',  nameEn: 'Gyeongbuk',  nameKey: 'region_gyeongbuk',  lat: 36.4919, lng: 128.8889),
  RegionInfo(code: 'GYEONGNAM',  nameEn: 'Gyeongnam',  nameKey: 'region_gyeongnam',  lat: 35.4606, lng: 128.2132),
  RegionInfo(code: 'JEJU',       nameEn: 'Jeju',        nameKey: 'region_jeju',       lat: 33.4996, lng: 126.5312),
];

// ── 지역 선택 바텀시트 ────────────────────────────────────────
class _RegionPickerSheet extends StatelessWidget {
  final List<RegionInfo> regions;
  final String selectedCode;
  final void Function(RegionInfo) onSelect;

  const _RegionPickerSheet({
    required this.regions,
    required this.selectedCode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(lang.t('select_region'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
                  const SizedBox(height: 4),
                  Text(lang.t('select_region_sub'),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF718096))),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final region = regions[index];
                  final isSelected = selectedCode == region.code;
                  final label = lang.t(region.nameKey).isNotEmpty &&
                          lang.t(region.nameKey) != region.nameKey
                      ? lang.t(region.nameKey)
                      : region.nameEn;

                  return InkWell(
                    onTap: () {
                      onSelect(region);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kNavy.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? kNavy : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          region.code == 'ALL'
                              ? Icons.public
                              : Icons.location_on_outlined,
                          size: 20, color: kNavy,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? kNavy
                                    : const Color(0xFF2D3748),
                              )),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: kNavy, size: 20),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── 언어 선택 바텀시트 ────────────────────────────────────────
class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 120),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Select Language',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
                const SizedBox(height: 16),
                ...AppStrings.languageNames.entries.map((entry) {
                  final isSelected = lang.currentLang == entry.key;
                  return _LanguageTile(
                    flag: AppStrings.languageFlags[entry.key] ?? '',
                    name: entry.value,
                    isSelected: isSelected,
                    onTap: () async {
                      Navigator.pop(context);
                      await lang.setLanguage(entry.key);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag, required this.name,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? kNavy.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kNavy : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? kNavy : const Color(0xFF2D3748),
                )),
          ),
          if (isSelected) const Icon(Icons.check_circle, color: kNavy, size: 20),
        ]),
      ),
    );
  }
}

// ── 공통 위젯 ─────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: kNavy, letterSpacing: 1.2));
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: children));
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 68, color: Color(0xFFF0F2F5));
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color color;
  const _IconBox({required this.icon, required this.bg, required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20));
}

class _TileWithToggle extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const _TileWithToggle({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final isDisabled = onChanged == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        _IconBox(icon: icon, bg: iconBg, color: iconColor),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
              color: isDisabled ? Colors.grey : kNavy)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12,
              color: isDisabled ? Colors.grey.shade400 : const Color(0xFF718096))),
        ])),
        Switch(value: value, onChanged: onChanged,
            activeThumbColor: Colors.white, activeTrackColor: kNavy),
      ]),
    );
  }
}

class _TileWithChip extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle, chipLabel;
  final VoidCallback onTap;
  const _TileWithChip({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle,
    required this.chipLabel, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        _IconBox(icon: icon, bg: iconBg, color: iconColor),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(
              fontSize: 12, color: Color(0xFF718096))),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(8)),
          child: Text(chipLabel, style: const TextStyle(
              fontSize: 13, color: kNavy, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: Color(0xFFCBD5E0), size: 20),
      ]),
    ),
  );
}

class _TileAbout extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle, trailing;
  const _TileAbout({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.trailing,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(children: [
      _IconBox(icon: icon, bg: iconBg, color: iconColor),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(
            fontSize: 12, color: Color(0xFF718096))),
      ])),
      Text(trailing, style: const TextStyle(
          fontSize: 13, color: Color(0xFF9AA5B4))),
    ]),
  );
}
