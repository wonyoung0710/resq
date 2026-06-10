import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../core/user_session.dart';
import '../../services/alert_service.dart';
import 'qr_result_screen.dart';
import '../screens/call119.dart';
import '../screens/safetyguide.dart';

const Color kNavy = Color(0xFF1B2F6E);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlertModel> _recentAlerts = [];
  bool _hasDangerAlert = false;
  AlertModel? _dangerAlert;
  bool _isLoading = true;
  bool _isTranslating = false;
  String _lastLang = '';

  @override
  void initState() {
    super.initState();
    _lastLang = context.read<LanguageProvider>().currentLang;
    _fetchAlerts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLang = context.read<LanguageProvider>().currentLang;
    if (_lastLang != currentLang && _lastLang.isNotEmpty) {
      _lastLang = currentLang;
      _fetchAlerts();
    } else {
      _lastLang = currentLang;
    }
  }

  void _applyAlerts(List<AlertModel> all) {
    final recent3Days = all.where((a) => _isWithin3Days(a.issuedAt)).toList();
    if (mounted) {
      setState(() {
        _hasDangerAlert = recent3Days.isNotEmpty;
        _dangerAlert = recent3Days.isNotEmpty ? recent3Days.first : null;
        _recentAlerts = all.take(5).toList();
      });
    }
  }

  bool _isWithin3Days(String issuedAt) {
    try {
      final dt = DateTime.parse(issuedAt);
      return DateTime.now().difference(dt).inDays < 3;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchAlerts() async {
    setState(() { _isLoading = true; _isTranslating = true; });
    try {
      await AlertService.fetchAlertsWithCallback(
        lang: _lastLang,
        onUpdate: (alerts) {
          if (!mounted) return;
          alerts.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
          _applyAlerts(alerts);
          setState(() => _isLoading = false);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
    if (mounted) setState(() => _isTranslating = false);
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
        title: const Text(
          'ResQ',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isTranslating)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white60, strokeWidth: 2),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrResultScreen()),
              ),
              icon: const Icon(Icons.qr_code_2, color: Colors.white, size: 18),
              label: const Text('My Info',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAlerts,
        color: kNavy,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            if (_isLoading)
              _LoadingCard()
            else if (_hasDangerAlert && _dangerAlert != null)
              _DangerCard(alert: _dangerAlert!, lang: lang)
            else
              _SafeCard(lang: lang),

            const SizedBox(height: 24),
            _SectionLabel(lang.t('quick_actions')),
            const SizedBox(height: 10),
            _EmergencyCallCard(lang: lang),
            const SizedBox(height: 10),
            _SafetyGuideCard(lang: lang),

            const SizedBox(height: 24),
            _SectionLabel(lang.t('recent_alerts')),
            const SizedBox(height: 10),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: kNavy),
                ),
              )
            else if (_recentAlerts.isEmpty)
              _EmptyAlerts(lang: lang)
            else
              ..._recentAlerts.map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AlertCard(alert: alert, lang: lang),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: const Center(
        child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: kNavy),
        ),
      ),
    );
  }
}

class _SafeCard extends StatelessWidget {
  final LanguageProvider lang;
  const _SafeCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 12),
            const SizedBox(width: 8),
            Text(lang.t('no_active_alerts'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
          ]),
          const SizedBox(height: 8),
          Text(lang.t('area_safe'),
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF4A5568), height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD0EED1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(lang.t('all_clear'),
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  final AlertModel alert;
  final LanguageProvider lang;
  const _DangerCard({required this.alert, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE58E8E), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.circle, color: Color(0xFFC0392B), size: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(alert.title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB12B2B))),
              ),
              Text(
                alert.issuedAt.length >= 16
                    ? alert.issuedAt.substring(11, 16)
                    : '',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB12B2B),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(lang.t('alert_tap_to_translate'),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF7A2020), height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCFCF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Active · ${alert.regionName}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB12B2B),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kNavy,
            letterSpacing: 1.2));
  }
}

class _EmergencyCallCard extends StatelessWidget {
  final LanguageProvider lang;
  const _EmergencyCallCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kNavy,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Call119Screen())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10)),
              child: const Center(
                child: Text('119',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.t('call_119'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(lang.t('fire_ambulance'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ]),
        ),
      ),
    );
  }
}

class _SafetyGuideCard extends StatelessWidget {
  final LanguageProvider lang;
  const _SafetyGuideCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SafetyGuideScreen())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: const Color(0xFFEEF0FB),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.menu, color: kNavy, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.t('safety_guide'),
                      style: const TextStyle(
                          color: kNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(lang.t('safety_guide_sub'),
                      style: const TextStyle(
                          color: Color(0xFF718096), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E0)),
          ]),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final LanguageProvider lang;
  const _AlertCard({required this.alert, required this.lang});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    try {
      borderColor =
          Color(int.parse(alert.colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      borderColor = const Color(0xFF9AA5B4);
    }
    final isActive = alert.status == 'ACTIVE';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(alert.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: kNavy,
                          height: 1.4)),
                ),
                Text(alert.timeAgo,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9AA5B4))),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(alert.categoryLabel,
                    style: TextStyle(
                        color: borderColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Text(
                '${alert.regionName} · ${isActive ? lang.t('alert_active') : lang.t('alert_resolved')}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF718096)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  final LanguageProvider lang;
  const _EmptyAlerts({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(children: [
        Icon(Icons.notifications_none, color: Colors.grey[400], size: 40),
        const SizedBox(height: 8),
        Text(lang.t('no_recent_alerts'),
            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ]),
    );
  }
}
