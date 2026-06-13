import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/language_provider.dart';

class Call119Screen extends StatelessWidget {
  const Call119Screen({super.key});

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFf0f4f8),
      body: Column(
        children: [
          // 헤더
          Container(
            color: const Color(0xFF1a2744),
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left,
                          color: Colors.white70, size: 22),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lang.t('call_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    lang.t('call_subtitle'),
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // 바디
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 119 히어로 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFdc2626),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '119',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.t('call_119_desc'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 전화 버튼
                  GestureDetector(
                    onTap: () => _call('119'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFe2e8f0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone,
                              color: Color(0xFFdc2626), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            lang.t('tap_to_call'),
                            style: const TextStyle(
                              color: Color(0xFFdc2626),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    lang.t('other_numbers'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a2744),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 112
                  _EmergencyRow(
                    iconBg: const Color(0xFFeff6ff),
                    icon: Icons.local_police_outlined,
                    iconColor: const Color(0xFF2563eb),
                    title: lang.t('police_112'),
                    subtitle: lang.t('police_112_sub'),
                    onTap: () => _call('112'),
                  ),
                  const SizedBox(height: 8),

                  // 1339
                  _EmergencyRow(
                    iconBg: const Color(0xFFf0fdf4),
                    icon: Icons.medical_services_outlined,
                    iconColor: const Color(0xFF16a34a),
                    title: lang.t('medical_1339'),
                    subtitle: lang.t('medical_1339_sub'),
                    onTap: () => _call('1339'),
                  ),
                  const SizedBox(height: 8),

                  // 팁 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFfef9e7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFfde68a)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.t('call_tip_title'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400e),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.t('call_tip_body'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF78350f),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyRow extends StatelessWidget {
  final Color iconBg, iconColor;
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  const _EmergencyRow({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe2e8f0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1a2744))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748b))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFcbd5e1), size: 18),
          ],
        ),
      ),
    );
  }
}