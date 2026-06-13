import 'package:flutter/material.dart';

const Color kNavy = Color(0xFF1B2F6E);

class QrResultPage extends StatelessWidget {
  const QrResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: kNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Info',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Scanned from ResQ',
                style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 프로필 카드 ────────────────────────────────────
          _Card(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: kNavy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('James Wilson',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kNavy)),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Text('🇺🇸', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
                        Text('United States · Male · 28',
                            style: TextStyle(fontSize: 13, color: Color(0xFF718096))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 혈액형 / 국적 ─────────────────────────────────
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('BLOOD TYPE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: Color(0xFF9AA5B4), letterSpacing: 1.1)),
                      SizedBox(height: 6),
                      Text('A+',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                              color: Color(0xFFD04040))),
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: const Color(0xFFF0F2F5)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('NATIONALITY',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: Color(0xFF9AA5B4), letterSpacing: 1.1)),
                        SizedBox(height: 6),
                        Text('American',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 비상 연락처 ────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('EMERGENCY CONTACTS'),
                const SizedBox(height: 12),
                _ContactRow(
                  name: 'Sarah Wilson',
                  detail: 'Mother · +1-555-0192',
                  onCall: () {},
                ),
                const SizedBox(height: 10),
                _ContactRow(
                  name: 'US Embassy Seoul',
                  detail: 'Embassy · 02-397-4114',
                  onCall: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 의료 정보 ──────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('MEDICAL INFO'),
                const SizedBox(height: 14),
                const Text('ALLERGIES',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Color(0xFF9AA5B4), letterSpacing: 1.1)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: const [
                    _MedChip(label: 'Penicillin', color: Color(0xFFFFD6D6), textColor: Color(0xFFD04040)),
                    _MedChip(label: 'Peanuts',   color: Color(0xFFFFD6D6), textColor: Color(0xFFD04040)),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('CONDITIONS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Color(0xFF9AA5B4), letterSpacing: 1.1)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: const [
                    _MedChip(label: 'Asthma',   color: Color(0xFFDDEEFF), textColor: Color(0xFF3A78C0)),
                    _MedChip(label: 'Diabetes', color: Color(0xFFDDEEFF), textColor: Color(0xFF3A78C0)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 경고 배너 ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE0A0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFD08000), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This information is provided for emergency use only. Please contact the embassy if further assistance is needed.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8A6000), height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── 공통 위젯 ─────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: kNavy, letterSpacing: 1.2));
  }
}

class _ContactRow extends StatelessWidget {
  final String name;
  final String detail;
  final VoidCallback onCall;

  const _ContactRow({required this.name, required this.detail, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kNavy)),
              const SizedBox(height: 2),
              Text(detail, style: const TextStyle(fontSize: 12, color: Color(0xFF718096))),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.phone, size: 14),
          label: const Text('Call', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}

class _MedChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _MedChip({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500)),
    );
  }
}
