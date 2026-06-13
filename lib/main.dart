import 'package:flutter/material.dart';
import 'package:provider/provider.dart';          // 🆕
import 'core/user_session.dart';
import 'screens/home_screen.dart';
import 'pages/alerts/alerts_page.dart';
import 'pages/embassy/embassy_page.dart';
import 'pages/settings/settings_page.dart';
import 'providers/language_provider.dart';         // 🆕
import 'services/alert_service.dart'; // ← 추가
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AlertService.clearCache(); // ← 이 줄 추가
  await UserSession.init();

  // 🆕 저장된 언어 미리 로드
  final langProvider = LanguageProvider();
  await langProvider.init();

  runApp(
    ChangeNotifierProvider.value(                  // 🆕
      value: langProvider,
      child: const ResQApp(),
    ),
  );
}

class ResQApp extends StatelessWidget {
  const ResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQ',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B2F6E)),
        scaffoldBackgroundColor: const Color(0xFFF2F4F8),
        fontFamily: 'Roboto',
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    AlertsPage(),
    EmbassyPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 🆕 BottomNav 라벨도 번역 적용하려면 watch 추가
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B2F6E),
        unselectedItemColor: const Color(0xFF9AA5B4),
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: lang.t('nav_home')),           // 🆕 번역
          BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_outlined),
              activeIcon: const Icon(Icons.notifications),
              label: lang.t('nav_alerts')),          // 🆕 번역
          BottomNavigationBarItem(
              icon: const Icon(Icons.business_outlined),
              activeIcon: const Icon(Icons.business),
              label: lang.t('nav_embassy')),         // 🆕 번역
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: lang.t('nav_settings')),        // 🆕 번역
        ],
      ),
    );
  }
}