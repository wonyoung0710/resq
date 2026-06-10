import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/language_provider.dart';

const Color kNavy = Color(0xFF1B2F6E);

class EmbassyData {
  final String flag;
  final String country;
  final String address;
  final String phone;
  String translatedCountry;
  String translatedAddress;

  EmbassyData({
    required this.flag,
    required this.country,
    required this.address,
    required this.phone,
    String? translatedCountry,
    String? translatedAddress,
  })  : translatedCountry = translatedCountry ?? country,
        translatedAddress = translatedAddress ?? address;
}

class EmbassyPage extends StatefulWidget {
  const EmbassyPage({super.key});

  @override
  State<EmbassyPage> createState() => _EmbassyPageState();
}

class _EmbassyPageState extends State<EmbassyPage> {
  List<EmbassyData> _embassyList = [];
  List<EmbassyData> _filteredList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isTranslating = false;
  String _lastLang = 'en';

  @override
  void initState() {
    super.initState();
    _loadCsv();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLang = context.read<LanguageProvider>().currentLang;
    if (_lastLang != currentLang && _embassyList.isNotEmpty) {
      _lastLang = currentLang;
      _translateEmbassies(currentLang);
    } else {
      _lastLang = currentLang;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _embassyList.where((e) =>
        e.translatedCountry.toLowerCase().contains(query) ||
        e.country.toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> _loadCsv() async {
    final rawData = await rootBundle.loadString('assets/embassy_utf8_C.txt');
    final csvTable = const CsvToListConverter(
      fieldDelimiter: '\t',
      shouldParseNumbers: false,
    ).convert(rawData);

    // 🌐 국제기구 제외, 국가만 로드
    List<EmbassyData> tempList = [];
    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      if (row.length < 5) continue;
      final flag = row[0].toString().trim();
      if (flag == '🌐') continue; // 국제기구 제외
      tempList.add(EmbassyData(
        flag:    flag,
        country: row[1].toString().trim(),
        address: row[2].toString().trim(),
        phone:   row[4].toString().trim(),
      ));
    }

    setState(() {
      _embassyList = tempList;
      _filteredList = tempList;
    });

    final lang = context.read<LanguageProvider>().currentLang;
    _lastLang = lang;
    if (lang != 'en') {
      _translateEmbassies(lang);
    }
  }

  // Google Translate API - 재시도 포함
  Future<String> _translateText(String text, String targetLang) async {
    if (text.isEmpty || targetLang == 'en') return text;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final uri = Uri.parse(
          'https://translate.googleapis.com/translate_a/single'
          '?client=gtx&sl=en&tl=$targetLang&dt=t'
          '&q=${Uri.encodeComponent(text)}',
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final buffer = StringBuffer();
          for (final item in data[0]) {
            if (item[0] != null) buffer.write(item[0]);
          }
          final result = buffer.toString();
          if (result.isNotEmpty) return result;
        }
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }
    return text;
  }

  Future<void> _translateEmbassies(String lang) async {
    if (lang == 'en') {
      setState(() {
        for (final e in _embassyList) {
          e.translatedCountry = e.country;
          e.translatedAddress = e.address;
        }
        _filteredList = List.from(_embassyList);
      });
      return;
    }

    setState(() => _isTranslating = true);

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'embassy_cache_$lang';
    final cached = prefs.getString(cacheKey);

    Map<String, dynamic> cacheData = {};
    bool hasIncomplete = false;

    // 기존 캐시 로드
    if (cached != null) {
      try {
        cacheData = jsonDecode(cached);

        // 캐시 적용
        setState(() {
          for (final e in _embassyList) {
            e.translatedCountry = cacheData['c_${e.country}'] ?? e.country;
            e.translatedAddress = cacheData['a_${e.country}'] ?? e.address;
          }
          _filteredList = List.from(_embassyList);
        });

        // 번역 실패한 항목 있는지 확인 (원본과 같으면 실패)
        for (final e in _embassyList) {
          final cachedCountry = cacheData['c_${e.country}'];
          final cachedAddress = cacheData['a_${e.country}'];
          // 캐시 없거나 원본과 동일하면 재번역 필요
          if (cachedCountry == null || cachedCountry == e.country ||
              cachedAddress == null || cachedAddress == e.address) {
            hasIncomplete = true;
            break;
          }
        }

        // 완전히 번역됐으면 종료
        if (!hasIncomplete) {
          setState(() => _isTranslating = false);
          return;
        }
      } catch (_) {}
    }

    // 번역 안 된 항목만 재번역
    const batchSize = 10;
    final Map<String, dynamic> newCache = Map.from(cacheData);

    for (int i = 0; i < _embassyList.length; i += batchSize) {
      if (_lastLang != lang || !mounted) break;

      final batch = _embassyList.sublist(
        i, (i + batchSize).clamp(0, _embassyList.length),
      );

      // 이미 번역된 항목은 스킵
      final needTranslate = batch.where((e) {
        final cachedC = cacheData['c_${e.country}'];
        final cachedA = cacheData['a_${e.country}'];
        return cachedC == null || cachedC == e.country ||
               cachedA == null || cachedA == e.address;
      }).toList();

      if (needTranslate.isEmpty) continue;

      final futures = needTranslate.map((e) async {
        final tCountry = await _translateText(e.country, lang);
        final tAddress = await _translateText(e.address, lang);
        return MapEntry(e, (tCountry, tAddress));
      });

      final results = await Future.wait(futures);

      for (final entry in results) {
        final e = entry.key;
        final tCountry = entry.value.$1;
        final tAddress = entry.value.$2;

        e.translatedCountry = tCountry;
        e.translatedAddress = tAddress;
        newCache['c_${e.country}'] = tCountry;
        newCache['a_${e.country}'] = tAddress;
      }

      if (mounted) setState(() => _filteredList = List.from(_embassyList));
    }

    // 캐시 저장
    if (newCache.isNotEmpty) {
      await prefs.setString(cacheKey, jsonEncode(newCache));
    }

    if (mounted) setState(() => _isTranslating = false);
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: kNavy,
        title: Row(
          children: [
            Text(
              lang.t('nav_embassy'),
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold,
              ),
            ),
            if (_isTranslating) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white60, strokeWidth: 2,
                ),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: lang.t('embassy_search_hint'),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF2F4F8),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _embassyList.isEmpty
                ? const Center(child: CircularProgressIndicator(color: kNavy))
                : _filteredList.isEmpty
                    ? Center(
                        child: Text(
                          lang.t('embassy_no_results'),
                          style: const TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final data = _filteredList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data.flag,
                                    style: const TextStyle(fontSize: 30)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.translatedCountry,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.location_on_outlined,
                                              size: 14, color: kNavy),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              data.translatedAddress,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: kNavy,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () => _call(data.phone),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: kNavy.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.call,
                                                  size: 14, color: kNavy),
                                              const SizedBox(width: 6),
                                              Text(
                                                data.phone,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: kNavy,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
