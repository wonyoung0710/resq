import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_strings.dart';
import '../../core/api_client.dart';
import '../../core/user_session.dart';

const Color kNavy = Color(0xFF1B2F6E);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _emergencyAlerts = true;
  bool _alertSound = true;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ── 서버에서 설정 불러오기 ─────────────────────────────────
  Future<void> _loadSettings() async {
    final userId = UserSession.userId;
    if (userId == null) {
      setState(() => _isLoadingSettings = false);
      return;
    }
    try {
      final data = await ApiClient.get('/users/$userId/settings');
      setState(() {
        _emergencyAlerts = data['alert_enabled'] ?? true;
        _alertSound = data['sound_enabled'] ?? true;
        _isLoadingSettings = false;
      });
    } catch (_) {
      setState(() => _isLoadingSettings = false);
    }
  }

  // ── 서버에 설정 저장 ───────────────────────────────────────
  Future<void> _saveSettings({
    required bool alertEnabled,
    required bool soundEnabled,
  }) async {
    final userId = UserSession.userId;
    if (userId == null) return;
    try {
      final lang = context.read<LanguageProvider>();
      await ApiClient.put('/users/$userId/settings', {
        'alert_enabled': alertEnabled,
        'sound_enabled': soundEnabled,
        'language_code': lang.currentLang,
      });
    } catch (_) {
      // 서버 실패해도 UI는 이미 업데이트됨
    }
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
      builder: (ctx) {
        return ChangeNotifierProvider.value(
          value: lang,
          child: const _LanguagePickerSheet(),
        );
      },
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
        title: Text(
          lang.t('settings'),
          style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          _isLoadingSettings
              ? const Center(child: CircularProgressIndicator(color: kNavy))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    // ── LANGUAGE ──────────────────────────────
                    _SectionLabel(lang.t('language')),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _TileWithChip(
                          icon: Icons.language,
                          iconBg: const Color(0xFFE8EAF6),
                          iconColor: const Color(0xFF5C6BC0),
                          title: lang.t('app_language'),
                          subtitle: lang.t('alert_translation'),
                          chipLabel: '${lang.currentFlag} ${lang.currentLangName}',
                          onTap: () => _showLanguagePicker(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── NOTIFICATIONS ─────────────────────────
                    _SectionLabel(lang.t('notifications')),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _TileWithToggle(
                          icon: Icons.notifications_outlined,
                          iconBg: const Color(0xFFFFEBEE),
                          iconColor: const Color(0xFFE53935),
                          title: lang.t('emergency_alerts'),
                          subtitle: lang.t('push_notifications'),
                          value: _emergencyAlerts,
                          onChanged: (v) {
                            setState(() => _emergencyAlerts = v);
                            _saveSettings(
                              alertEnabled: v,
                              soundEnabled: _alertSound,
                            );
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
                          // Emergency alerts 꺼져있으면 sound도 비활성화
                          onChanged: _emergencyAlerts
                              ? (v) {
                                  setState(() => _alertSound = v);
                                  _saveSettings(
                                    alertEnabled: _emergencyAlerts,
                                    soundEnabled: v,
                                  );
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
                          chipLabel: 'Cheonan',
                          onTap: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── ABOUT ─────────────────────────────────
                    _SectionLabel(lang.t('about')),
                    const SizedBox(height: 8),
                    _SettingsCard(
                      children: [
                        _TileAbout(
                          icon: Icons.info_outline,
                          iconBg: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF1E88E5),
                          title: lang.t('app_version'),
                          subtitle: 'resQ',
                          trailing: 'v1.0.0',
                        ),
                      ],
                    ),
                  ],
                ),

          // 번역 로딩 오버레이
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
              24, 16, 24,
              MediaQuery.of(context).viewInsets.bottom + 80,
            ),
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
                const Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: kNavy,
                  ),
                ),
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
    required this.flag,
    required this.name,
    required this.isSelected,
    required this.onTap,
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
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? kNavy : const Color(0xFF2D3748),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: kNavy, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── 공통 위젯 ─────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: kNavy, letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 68, color: Color(0xFFF0F2F5));
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color color;
  const _IconBox({required this.icon, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _TileWithToggle extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged; // nullable → null이면 비활성화

  const _TileWithToggle({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onChanged == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _IconBox(icon: icon, bg: iconBg, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey : kNavy)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDisabled
                            ? Colors.grey.shade400
                            : const Color(0xFF718096))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: kNavy,
          ),
        ],
      ),
    );
  }
}

class _TileWithChip extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String chipLabel;
  final VoidCallback onTap;

  const _TileWithChip({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.chipLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBox(icon: icon, bg: iconBg, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(chipLabel,
                  style: const TextStyle(
                      fontSize: 13, color: kNavy, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E0), size: 20),
          ],
        ),
      ),
    );
  }
}

class _TileAbout extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;

  const _TileAbout({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _IconBox(icon: icon, bg: iconBg, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
              ],
            ),
          ),
          Text(trailing,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9AA5B4))),
        ],
        
      ),
    );
  }
}
