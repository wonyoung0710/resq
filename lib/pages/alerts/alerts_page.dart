import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/language_provider.dart';
import '../../services/alert_service.dart';

const Color kNavy = Color(0xFF1B2F6E);

class AlertCategory2 {
  final String code;
  final String labelKey;
  final Color color;
  const AlertCategory2({required this.code, required this.labelKey, required this.color});
}

const List<AlertCategory2> kCategories = [
  AlertCategory2(code: 'ALL',        labelKey: 'filter_all',        color: kNavy),
  AlertCategory2(code: 'RAIN',       labelKey: 'filter_rain',       color: Color(0xFF1565C0)),
  AlertCategory2(code: 'FLOOD',      labelKey: 'filter_flood',      color: Color(0xFF0277BD)),
  AlertCategory2(code: 'EARTHQUAKE', labelKey: 'filter_earthquake', color: Color(0xFFBF360C)),
  AlertCategory2(code: 'FIRE',       labelKey: 'filter_fire',       color: Color(0xFFE53935)),
  AlertCategory2(code: 'SNOW',       labelKey: 'filter_snow',       color: Color(0xFF5C6BC0)),
  AlertCategory2(code: 'LANDSLIDE',  labelKey: 'filter_landslide',  color: Color(0xFF6D4C41)),
  AlertCategory2(code: 'OTHER',      labelKey: 'filter_other',      color: Color(0xFF546E7A)),
];

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<AlertModel> _alerts = [];
  String _selectedCategory = 'ALL';
  bool _isLoading = true;
  bool _isTranslating = false;
  String? _error;
  String _lastLang = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lang = context.read<LanguageProvider>();
      _lastLang = lang.currentLang;
      lang.addListener(_onLangChanged);
      _loadAll(_lastLang);
    });
  }

  @override
  void dispose() {
    try {
      context.read<LanguageProvider>().removeListener(_onLangChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onLangChanged() {
    if (!mounted) return;
    final provider = context.read<LanguageProvider>();
    if (provider.isLoading) return;
    final currentLang = provider.currentLang;
    if (_lastLang != currentLang) {
      _lastLang = currentLang;
      _loadAll(currentLang);
    }
  }

  Future<void> _loadAll([String? langOverride]) async {
    final lang = langOverride ?? _lastLang;
    if (!mounted) return;

    setState(() {
      _error = null;
      _isLoading = _alerts.isEmpty;
      _isTranslating = true;
    });

    try {
      // 저장된 지역 설정 읽기
      final prefs = await SharedPreferences.getInstance();
      final regionCode = prefs.getString('setting_region') ?? 'ALL';

      await AlertService.fetchAlertsWithCallback(
        lang: lang,
        regionCode: regionCode == 'ALL' ? null : regionCode,
        onUpdate: (alerts) {
          if (!mounted || _lastLang != lang) return;
          setState(() {
            _alerts = alerts;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }

    if (mounted) setState(() => _isTranslating = false);
  }

  List<AlertModel> get _filtered {
    if (_selectedCategory == 'ALL') return _alerts;
    return _alerts.where((a) => a.categoryCode == _selectedCategory).toList();
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
        title: Row(
          children: [
            Text(lang.t('nav_alerts'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            if (_isTranslating) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white60, strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            categories: kCategories,
            selectedCategory: _selectedCategory,
            lang: lang,
            onSelected: (code) => setState(() => _selectedCategory = code),
          ),
          Expanded(child: _buildBody(lang)),
        ],
      ),
    );
  }

  Widget _buildBody(LanguageProvider lang) {
    if (_isLoading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: kNavy),
          const SizedBox(height: 14),
          Text(lang.t('alerts_loading'),
              style: const TextStyle(color: Color(0xFF9AA5B4))),
        ]),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_outlined, color: Color(0xFFCBD5E0), size: 48),
          const SizedBox(height: 12),
          Text(lang.t('alerts_connection_error'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9AA5B4), fontSize: 13, height: 1.6)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(lang.t('retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNavy, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.notifications_none, color: Color(0xFFCBD5E0), size: 48),
          const SizedBox(height: 12),
          Text(lang.t('alerts_empty'),
              style: const TextStyle(color: Color(0xFF9AA5B4))),
        ]),
      );
    }

    return RefreshIndicator(
      color: kNavy,
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _AlertCard(item: _filtered[index], lang: lang),
      ),
    );
  }
}

// ── 필터 바 (좌우 화살표 포함) ──────────────────────────────
class _FilterBar extends StatefulWidget {
  final List<AlertCategory2> categories;
  final String selectedCategory;
  final LanguageProvider lang;
  final void Function(String) onSelected;

  const _FilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.lang,
    required this.onSelected,
  });

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrows);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrows());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateArrows);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateArrows() {
    if (!_scrollController.hasClients) return;
    setState(() {
      _canScrollLeft = _scrollController.offset > 0;
      _canScrollRight =
          _scrollController.offset < _scrollController.position.maxScrollExtent;
    });
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 150).clamp(0, double.infinity),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 150,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: _canScrollLeft ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _canScrollLeft ? _scrollLeft : null,
              child: Container(
                width: 28, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4, offset: const Offset(2, 0),
                  )],
                ),
                child: const Icon(Icons.chevron_left, size: 20, color: kNavy),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: widget.categories.map((cat) {
                  final isSelected = widget.selectedCategory == cat.code;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: widget.lang.t(cat.labelKey),
                      selected: isSelected,
                      activeColor: cat.code == 'ALL'
                          ? kNavy : cat.color.withValues(alpha: 0.15),
                      activeTextColor: cat.code == 'ALL' ? Colors.white : cat.color,
                      onTap: () => widget.onSelected(cat.code),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _canScrollRight ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: _canScrollRight ? _scrollRight : null,
              child: Container(
                width: 28, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4, offset: const Offset(-2, 0),
                  )],
                ),
                child: const Icon(Icons.chevron_right, size: 20, color: kNavy),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final Color activeTextColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label, required this.selected,
    required this.activeColor, required this.activeTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? activeTextColor : const Color(0xFF718096),
            )),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel item;
  final LanguageProvider lang;
  const _AlertCard({required this.item, required this.lang});

  @override
  Widget build(BuildContext context) {
    final borderColor = _hexColor(item.colorHex);
    final isActive = item.status == 'ACTIVE';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(item.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: kNavy, height: 1.4)),
            ),
            const SizedBox(width: 8),
            Text(_formatTime(item.issuedAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9AA5B4))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.severityLabel.isNotEmpty ? item.severityLabel : item.categoryLabel,
                style: TextStyle(color: borderColor, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFFEEEE) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? lang.t('alert_active') : lang.t('alert_resolved'),
                style: TextStyle(
                  color: isActive ? const Color(0xFFB12B2B) : const Color(0xFF2E7D32),
                  fontSize: 11, fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.actionGuide.isNotEmpty ? item.actionGuide : item.content,
                style: const TextStyle(fontSize: 13, color: Color(0xFF718096)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  String _formatTime(String issuedAt) {
    try {
      final dt = DateTime.parse(issuedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (_) {
      return issuedAt;
    }
  }

  static Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF9AA5B4);
    }
  }
}
