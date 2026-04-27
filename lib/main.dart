import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';
import 'l10n.dart';
import 'services/weather_service.dart';
import 'widgets/weather_icon.dart';
import 'services/news_service.dart';
import 'pages/map_page.dart';
import 'pages/splash_page.dart';
import 'pages/objets_page.dart';
import 'pages/signalement_page.dart';
import 'pages/agenda_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/restaurants_page.dart';
import 'pages/dechets_page.dart';
import 'pages/services_page.dart';
import 'pages/transport_page.dart';
import 'pages/lieux_page.dart';
import 'pages/gare_page.dart';
import 'pages/emploi_page.dart';
import 'pages/mediatheque_page.dart';
import 'services/irigo_service.dart';
import 'services/sncf_service.dart';
import 'services/notification_service.dart';
import 'services/local_notification_service.dart';
import 'services/ad_service.dart';
import 'widgets/ad_banner.dart';
import 'pages/meteo_page.dart';
import 'pages/privacy_policy_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase doit être prêt avant runApp pour qu'AdMob puisse l'intégrer
  await Firebase.initializeApp();
  runApp(const MyApp());
  // Defer heavy inits to after first frame — prevents ANR on the launcher
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.wait([
      NotificationService.initialize(navigatorKey: MyApp.navigatorKey),
      LocalNotificationService.initialize(),
    ]);
    AdService.initialize();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  // Clé de navigation globale (utilisée par les notifications)
  static final navigatorKey = GlobalKey<NavigatorState>();
  // ignore: library_private_types_in_public_api
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('fr');

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool('dark_mode') ?? false;
    final lang = prefs.getString('locale') ?? 'fr';
    setState(() {
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
      _locale = Locale(lang);
    });
  }

  void toggleTheme(bool isDark) async {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('dark_mode', isDark);
  }

  void setLocale(Locale locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('locale', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Trélazé',
      debugShowCheckedModeBanner: false,
      navigatorKey: MyApp.navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/home': (context) => InAppNotifOverlay(
              key: NotificationService.overlayKey,
              child: const MainPage(),
            ),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;
  final pages = const [
    HomePage(), TransportPage(), NewsPage(), InfoPage(), SettingsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          setState(() => _index = i);
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.navHome),
          NavigationDestination(icon: const Icon(Icons.directions_bus_outlined), selectedIcon: const Icon(Icons.directions_bus), label: l.navBus),
          NavigationDestination(icon: const Icon(Icons.article_outlined), selectedIcon: const Icon(Icons.article), label: l.navNews),
          NavigationDestination(icon: const Icon(Icons.info_outline), selectedIcon: const Icon(Icons.info), label: l.navInfo),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l.navSettings),
        ],
      ),
    );
  }
}

///// PAGE ACCUEIL
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _weather;
  bool _loadingWeather = true;
  List<Map<String, String>> _trelazNews = [];

  // ── Badges live ──────────────────────────────────────────────────────────
  String _nextBusLabel() {
    final now = DateTime.now();
    final times = IrigoService.getNextDepartures('01_0_TRELAZE', now);
    if (times.isEmpty) return 'Voir horaires';
    final diff = times.first.difference(now).inMinutes;
    if (diff == 0) return 'Imminent';
    return 'Dans $diff min';
  }

  String _nextTrainLabel() {
    final dep = SncfService.getNextDeparture();
    if (dep == null) return 'Voir horaires';
    final diff = dep.displayTime.difference(DateTime.now()).inMinutes;
    final dir = dep.direction.contains('Angers') ? 'Angers' : 'Le Mans';
    if (diff <= 0) return 'En gare';
    return '$dir dans $diff min';
  }

  String _nextCollecteLabel() {
    final now = DateTime.now();
    final wd = now.weekday; // 1=lun … 7=dim
    // OM : mardi(2) et vendredi(5)
    final omDays = [2, 5];
    int best = 8;
    for (final d in omDays) {
      int diff = d - wd;
      if (diff < 0) diff += 7;
      if (diff == 0 && now.hour >= 20) diff = 7;
      if (diff < best) best = diff;
    }
    if (best == 0) return '🗑️ Collecte aujourd\'hui';
    if (best == 1) return '🗑️ Collecte demain';
    const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '🗑️ ${jours[(wd - 1 + best) % 7]}';
  }

  String _mairieLabel() {
    final now = DateTime.now();
    final wd = now.weekday;
    final h = now.hour + now.minute / 60.0;
    bool open = false;
    if (wd == 4) {
      open = (h >= 10 && h < 12.25) || (h >= 13.5 && h < 19);
    } else if (wd == 6) {
      open = h >= 10 && h < 12;
    } else if (wd <= 5) {
      open = (h >= 8.75 && h < 12.25) || (h >= 13.5 && h < 17);
    }
    return open ? '🟢 Ouverte' : '🔴 Fermée';
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _fetchTrelazNews();
  }

  Future<void> _fetchWeather() async {
    setState(() => _loadingWeather = true);
    final data = await WeatherService.getWeather();
    if (mounted) setState(() { _weather = data; _loadingWeather = false; });
  }

  Future<void> _fetchTrelazNews() async {
    final data = await NewsService.getActualitesTrelaze(limit: 5);
    if (mounted) setState(() => _trelazNews = data);
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 5)  return 'Bonne nuit 🌙';
    if (h < 12) return 'Bonjour 👋';
    if (h < 18) return 'Bon après-midi ☀️';
    return 'Bonsoir 🌆';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, Color(0xFF0A2729)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 56, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_getGreeting(),
                      style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w400, height: 1.2)),
                  const Text('Trélazé',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => showSearch(
              context: context,
              delegate: _AppSearchDelegate(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_fetchWeather(), _fetchTrelazNews()]);
        },
        color: AppTheme.primary,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 15, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Application citoyenne indépendante — non affiliée à la Mairie de Trélazé",
                  style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
          GestureDetector(
            onTap: _weather == null ? null : () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MeteoPage(weatherData: _weather!))),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF0A2729)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: _loadingWeather
                  ? _WeatherSkeleton()
                  : _weather == null
                      ? Text(AppL10n.of(context).weatherUnavailable, style: const TextStyle(color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Text("📍 Trélazé", style: TextStyle(color: Colors.white70, fontSize: 13)),
                                if (_weather!['_fromCache'] == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white38, width: 0.8),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.wifi_off, color: Colors.white70, size: 10),
                                      const SizedBox(width: 3),
                                      Text(AppL10n.of(context).weatherCached, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
                                    ]),
                                  ),
                                ],
                              ]),
                              const SizedBox(height: 4),
                              Text("${_weather!['main']['temp'].toStringAsFixed(0)}°C",
                                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, height: 1)),
                              const SizedBox(height: 4),
                              Text(_weather!['weather'][0]['description'],
                                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(children: [
                                _WeatherBadge(label: "Ressenti ${(_weather!['main']['feels_like'] as num).toStringAsFixed(0)}°"),
                                const SizedBox(width: 8),
                                _WeatherBadge(label: "Humidité ${_weather!['main']['humidity']}%"),
                              ]),
                            ]),
                            WeatherIcon(iconCode: _weather!['weather'][0]['icon'] as String? ?? '01d', size: 72),
                          ],
                        ),
            ),
          ),
          // ── Dernières infos de Trélazé ─────────────────────────────
          if (_trelazNews.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(children: [
              const Text("Infos de Trélazé",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
              const Spacer(),
              GestureDetector(
                onTap: () => _openPage(context, const NewsPage()),
                child: const Text("Tout voir →",
                    style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _trelazNews.length,
                itemBuilder: (context, i) {
                  final article = _trelazNews[i];
                  final imgUrl = article['image'] ?? '';
                  final cat = article['category'] ?? '';
                  return GestureDetector(
                    onTap: () {
                      final url = article['link'] ?? '';
                      if (url.isNotEmpty) {
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: 200,
                      margin: EdgeInsets.only(right: i < _trelazNews.length - 1 ? 12 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Image
                        SizedBox(
                          height: 110,
                          width: double.infinity,
                          child: imgUrl.isNotEmpty
                              ? Image.network(imgUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: AppTheme.primary.withValues(alpha: 0.15),
                                    child: const Icon(Icons.article, size: 40, color: AppTheme.primary),
                                  ))
                              : Container(
                                  color: AppTheme.primary.withValues(alpha: 0.12),
                                  child: const Icon(Icons.article, size: 40, color: AppTheme.primary),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (cat.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 5),
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(cat,
                                    style: const TextStyle(fontSize: 9, color: AppTheme.primary, fontWeight: FontWeight.w700),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            Text(article['title'] ?? '',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
                                maxLines: 3, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(AppL10n.of(context).homeQuickAccess,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true, crossAxisCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82,
            children: [
              _QuickCard(icon: Icons.directions_bus, label: AppL10n.of(context).cardBus, color: AppTheme.primary,
                  subtitle: _nextBusLabel(),
                  onTap: () => _openPage(context, const TransportPage())),
              _QuickCard(icon: Icons.train, label: 'Gare SNCF', color: const Color(0xFF1A5276),
                  subtitle: _nextTrainLabel(),
                  onTap: () => _openPage(context, const GarePage())),
              _QuickCard(icon: Icons.article, label: AppL10n.of(context).cardNews, color: const Color(0xFF5A7070),
                  subtitle: _trelazNews.isEmpty ? 'Actualités' : '${_trelazNews.length} articles',
                  onTap: () => _openPage(context, const NewsPage())),
              _QuickCard(icon: Icons.location_on, label: AppL10n.of(context).cardPlaces, color: AppTheme.green,
                  subtitle: '26 lieux',
                  onTap: () => _openPage(context, const LieuxPage())),
              _QuickCard(icon: Icons.account_balance, label: AppL10n.of(context).cardServices, color: AppTheme.primary,
                  subtitle: _mairieLabel(),
                  onTap: () => _openPage(context, const ServicesPage())),
              _QuickCard(icon: Icons.event, label: AppL10n.of(context).cardEvents, color: AppTheme.primary,
                  subtitle: 'Calendrier',
                  onTap: () => _openPage(context, const AgendaPage())),
              _QuickCard(icon: Icons.restaurant, label: AppL10n.of(context).cardRestaurants, color: AppTheme.green,
                  subtitle: '9 restaurants',
                  onTap: () => _openPage(context, const RestaurantsPage())),
              _QuickCard(icon: Icons.delete_outline, label: AppL10n.of(context).cardWaste, color: AppTheme.green,
                  subtitle: _nextCollecteLabel(),
                  onTap: () => _openPage(context, const DechetsPage())),
              _QuickCard(icon: Icons.report_problem, label: AppL10n.of(context).cardReport, color: AppTheme.accent,
                  subtitle: 'Signalez ici',
                  onTap: () => _openPage(context, const SignalementPage())),
              _QuickCard(icon: Icons.work_outline, label: 'Mission Emploi', color: const Color(0xFF1B3A6B),
                  subtitle: 'Offres & conseils',
                  onTap: () => _openPage(context, const EmploiPage())),
              _QuickCard(icon: Icons.local_library_outlined, label: 'Médiathèque', color: const Color(0xFF7B4FA0),
                  subtitle: 'Horaires & catalogue',
                  onTap: () => _openPage(context, const MediathequePage())),
            ],
          ),
          const SizedBox(height: 20),
          Text(AppL10n.of(context).homeServices,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.map, color: AppTheme.primary),
              ),
              title: Text(AppL10n.of(context).homeCityMap, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSub),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage())),
            ),
          ),
          const SizedBox(height: 20),
          // ── Bannière pub ─────────────────────────────────────────────────
          Center(child: AdBanner(adUnitId: AdIds.bannerHome)),
          const SizedBox(height: 20),
          Text(AppL10n.of(context).homeEmergency,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 10),
          Row(children: [
            _UrgenceCard(numero: "15", label: AppL10n.of(context).labelSamu, icon: Icons.local_hospital, color: AppTheme.accent),
            const SizedBox(width: 10),
            _UrgenceCard(numero: "18", label: AppL10n.of(context).labelFiremen, icon: Icons.local_fire_department, color: AppTheme.accent),
            const SizedBox(width: 10),
            _UrgenceCard(numero: "17", label: AppL10n.of(context).labelPolice, icon: Icons.local_police, color: AppTheme.primary),
            const SizedBox(width: 10),
            _UrgenceCard(numero: "112", label: AppL10n.of(context).labelEmergency, icon: Icons.emergency, color: Color(0xFF0A2729)),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    ),  // RefreshIndicator
    );
  }
}

class _WeatherBadge extends StatelessWidget {
  final String label;
  const _WeatherBadge({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class _WeatherSkeleton extends StatefulWidget {
  @override
  State<_WeatherSkeleton> createState() => _WeatherSkeletonState();
}

class _WeatherSkeletonState extends State<_WeatherSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _fade = Tween(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _bar(double w, double h) => FadeTransition(
    opacity: _fade,
    child: Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _bar(80, 12),
        const SizedBox(height: 10),
        _bar(110, 42),
        const SizedBox(height: 8),
        _bar(90, 12),
        const SizedBox(height: 10),
        Row(children: [_bar(72, 26), const SizedBox(width: 8), _bar(88, 26)]),
      ]),
      FadeTransition(
        opacity: _fade,
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(36)),
        ),
      ),
    ]);
  }
}

class _QuickCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;
  const _QuickCard({required this.icon, required this.label, required this.color, required this.onTap, this.subtitle});
  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF122020) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E3A3A) : Colors.grey.shade100;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return AnimatedScale(
      scale: _pressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Material(
          color: cardColor, borderRadius: BorderRadius.circular(16), elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: isDark ? [] : [BoxShadow(color: widget.color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
              color: cardColor,
            ),
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                decoration: BoxDecoration(color: widget.color.withValues(alpha: isDark ? 0.20 : 0.10), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(11),
                child: Icon(widget.icon, color: isDark ? widget.color.withValues(alpha: 0.9) : widget.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(widget.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 3),
                Text(widget.subtitle!, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: subColor)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _UrgenceCard extends StatefulWidget {
  final String numero;
  final String label;
  final IconData icon;
  final Color color;
  const _UrgenceCard({required this.numero, required this.label, required this.icon, required this.color});
  @override
  State<_UrgenceCard> createState() => _UrgenceCardState();
}

class _UrgenceCardState extends State<_UrgenceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // En dark mode, les couleurs trop sombres deviennent invisibles — on les éclaircit
    final color = isDark
        ? Color.lerp(widget.color, Colors.white, 0.55)!
        : widget.color;
    return Expanded(
      child: Semantics(
        label: '${widget.label}, appeler le ${widget.numero}',
        button: true,
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              HapticFeedback.mediumImpact();
              launchUrl(Uri.parse('tel:${widget.numero}'));
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: _pressed ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(widget.icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(widget.numero, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(widget.label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

///// PAGE ACTUS
class NewsPage extends StatefulWidget {
  const NewsPage({super.key});
  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Map<String, String>> _articles = [];
  bool _loading = true;
  String _sourceFilter = 'Tous';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _chargerActus(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _chargerActus() async {
    setState(() => _loading = true);
    final data = await NewsService.getActualites();
    if (mounted) setState(() { _articles = data; _loading = false; });
  }

  List<Map<String, String>> get _filtered {
    var list = _sourceFilter == 'Tous'
        ? _articles
        : _articles.where((a) => a['source'] == _sourceFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) =>
        (a['title'] ?? '').toLowerCase().contains(q) ||
        (a['description'] ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<String> get _sources {
    final s = _articles.map((a) => a['source'] ?? '').toSet().toList()..sort();
    return ['Tous', ...s];
  }

  /// Parse date RSS (RFC 2822) ou ISO 8601 → "17 avr. 2025"
  static String _parseDate(String raw) {
    if (raw.isEmpty) return '';
    const months = {
      'Jan': 'jan.', 'Feb': 'fév.', 'Mar': 'mar.', 'Apr': 'avr.',
      'May': 'mai', 'Jun': 'jun.', 'Jul': 'jul.', 'Aug': 'aoû.',
      'Sep': 'sep.', 'Oct': 'oct.', 'Nov': 'nov.', 'Dec': 'déc.',
    };
    try {
      // ISO 8601
      final dt = DateTime.parse(raw);
      final m = [
        '', 'jan.', 'fév.', 'mar.', 'avr.', 'mai', 'jun.',
        'jul.', 'aoû.', 'sep.', 'oct.', 'nov.', 'déc.',
      ][dt.month];
      return '${dt.day} $m ${dt.year}';
    } catch (_) {}
    // RFC 2822 : "Thu, 17 Apr 2025 12:00:00 +0000"
    final parts = raw.split(RegExp(r'[\s,]+'));
    final clean = parts.where((p) => p.isNotEmpty).toList();
    if (clean.length >= 4) {
      final day = int.tryParse(clean[1]);
      final mon = months[clean[2]];
      final year = int.tryParse(clean[3]);
      if (day != null && mon != null && year != null) return '$day $mon $year';
    }
    return '';
  }

  Widget _newsImage(Map<String, String> article, int index) {
    final imgUrl = article['image'] ?? '';
    Widget placeholder() => Container(
      height: 160, width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF0A2729)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(
        index % 3 == 0 ? Icons.location_city
            : index % 3 == 1 ? Icons.article
            : Icons.event,
        size: 72, color: Colors.white.withValues(alpha: 0.18),
      )),
    );

    if (imgUrl.isEmpty) return placeholder();
    return SizedBox(
      height: 160, width: double.infinity,
      child: Image.network(
        imgUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return placeholder();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sources = _sources;
    final articles = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualités"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _chargerActus)],
      ),
      body: RefreshIndicator(
        onRefresh: _chargerActus,
        color: AppTheme.primary,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("Actualités indisponibles", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ])),
                ])
              : Column(children: [
                  // ── Barre de recherche ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un article…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() {
                                  _searchCtrl.clear();
                                  _searchQuery = '';
                                }),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  // ── Filtres source ────────────────────────────────────
                  if (sources.length > 2)
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        children: sources.map((s) {
                          final sel = s == _sourceFilter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(s),
                              selected: sel,
                              onSelected: (_) => setState(() => _sourceFilter = s),
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: sel ? Colors.white : null,
                                fontSize: 12,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                              ),
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // ── Bannière pub ──────────────────────────────────────
                  Center(child: AdBanner(adUnitId: AdIds.bannerNews)),
                  // ── Liste articles ────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        final dateStr = _parseDate(article['date'] ?? '');
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          builder: (context, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
                          ),
                          child: GestureDetector(
                          onTap: () {
                            final url = article['link'] ?? '';
                            if (url.isNotEmpty) {
                              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Image (réelle ou placeholder) ────────
                                _newsImage(article, index),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Source + Catégorie + Date
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(article['source'] ?? '',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.primary,
                                                    fontWeight: FontWeight.w600)),
                                          ),
                                          if ((article['category'] ?? '').isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0A2729).withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(article['category']!,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF0A2729),
                                                      fontWeight: FontWeight.w500)),
                                            ),
                                          if (dateStr.isNotEmpty)
                                            Row(mainAxisSize: MainAxisSize.min, children: [
                                              const Icon(Icons.calendar_today,
                                                  size: 11, color: Colors.grey),
                                              const SizedBox(width: 3),
                                              Text(dateStr,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey)),
                                            ]),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(article['title'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis),
                                      if ((article['description'] ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(article['description']!,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600]),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                      const SizedBox(height: 10),
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text("Lire la suite →",
                                              style: TextStyle(
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
      ),  // RefreshIndicator
    );
  }
}

///// PAGE INFOS
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Infos utiles")),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Padding(padding: EdgeInsets.only(bottom: 8),
            child: Text("Mairie de Trélazé", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Card(child: Column(children: [
          const ListTile(leading: Icon(Icons.location_city, color: AppTheme.primary),
              title: Text("Mairie de Trélazé"), subtitle: Text("Place Olivier Thuau, CS40027\n49801 Trélazé Cedex")),
          const ListTile(leading: Icon(Icons.access_time, color: AppTheme.primary),
              title: Text("Horaires d'ouverture"),
              subtitle: Text("Lun : 8h45–12h15, 13h30–17h45\nMar/Mer/Ven : 8h45–12h15, 13h30–17h\nJeu : 10h–12h15, 13h30–19h\nSam : 10h–12h (État civil)")),
          ListTile(leading: const Icon(Icons.phone, color: AppTheme.primary),
              title: const Text("02 41 33 74 74"),
              onTap: () => launchUrl(Uri.parse('tel:0241337474')),
              trailing: const Icon(Icons.call, color: Colors.green)),
        ])),
        const SizedBox(height: 16),
        const Padding(padding: EdgeInsets.only(bottom: 8),
            child: Text("Urgences", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.local_hospital, color: Colors.red), title: const Text("SAMU"),
              subtitle: const Text("Service d'aide médicale urgente"),
              trailing: const Text("15", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
              onTap: () => launchUrl(Uri.parse('tel:15'))),
          ListTile(leading: const Icon(Icons.local_fire_department, color: Colors.orange), title: const Text("Pompiers"),
              trailing: const Text("18", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
              onTap: () => launchUrl(Uri.parse('tel:18'))),
          ListTile(leading: const Icon(Icons.local_police, color: Colors.blue), title: const Text("Police"),
              trailing: const Text("17", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
              onTap: () => launchUrl(Uri.parse('tel:17'))),
          ListTile(leading: const Icon(Icons.emergency, color: Colors.purple), title: const Text("Numéro d'urgence européen"),
              trailing: const Text("112", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
              onTap: () => launchUrl(Uri.parse('tel:112'))),
        ])),
        const SizedBox(height: 16),
        const Padding(padding: EdgeInsets.only(bottom: 8),
            child: Text("Services utiles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.local_hospital, color: AppTheme.primary),
              title: const Text("CHU Angers"), subtitle: const Text("4 Rue Larrey, 49100 Angers"),
              onTap: () => launchUrl(Uri.parse('tel:0241353636')),
              trailing: const Icon(Icons.call, color: Colors.green)),
          ListTile(leading: const Icon(Icons.medical_services, color: AppTheme.primary),
              title: const Text("Pharmacie de Trélazé"), subtitle: const Text("Ouverte du lundi au samedi"),
              onTap: () => launchUrl(Uri.parse('tel:0241693030')),
              trailing: const Icon(Icons.call, color: Colors.green)),
        ])),
      ]),
    );
  }
}


///// PAGE CONTACTS
class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contacts")),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Padding(padding: EdgeInsets.only(bottom: 8),
            child: Text("Mairie & Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.location_city, color: AppTheme.primary),
              title: const Text("Mairie de Trélazé"), subtitle: const Text("02 41 33 74 74"),
              onTap: () => launchUrl(Uri.parse('tel:0241337474')),
              trailing: const Icon(Icons.call, color: Colors.green)),
          ListTile(leading: const Icon(Icons.people, color: Colors.pink),
              title: const Text("CCAS"), subtitle: const Text("02 41 33 74 65"),
              onTap: () => launchUrl(Uri.parse('tel:0241337465')),
              trailing: const Icon(Icons.call, color: Colors.green)),
          ListTile(leading: const Icon(Icons.construction, color: Colors.orange),
              title: const Text("Urbanisme / Permis"), subtitle: const Text("02 41 69 98 01"),
              onTap: () => launchUrl(Uri.parse('tel:0241699801')),
              trailing: const Icon(Icons.call, color: Colors.green)),
          ListTile(leading: const Icon(Icons.pool, color: Color(0xFF00AEEF)),
              title: const Text("Piscine municipale"), subtitle: const Text("02 41 69 01 79"),
              onTap: () => launchUrl(Uri.parse('tel:0241690179')),
              trailing: const Icon(Icons.call, color: Colors.green)),
          ListTile(leading: const Icon(Icons.library_books, color: Color(0xFF7263A9)),
              title: const Text("Médiathèque Hervé-Bazin"), subtitle: const Text("02 41 69 19 64"),
              onTap: () => launchUrl(Uri.parse('tel:0241691964')),
              trailing: const Icon(Icons.call, color: Colors.green)),
        ])),
        const SizedBox(height: 16),
        const Padding(padding: EdgeInsets.only(bottom: 8),
            child: Text("Urgences", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.local_fire_department, color: Colors.orange),
              title: const Text("Pompiers"), subtitle: const Text("18"),
              onTap: () => launchUrl(Uri.parse('tel:18')),
              trailing: const Icon(Icons.call, color: Colors.green)),
          ListTile(leading: const Icon(Icons.local_police, color: Colors.blue),
              title: const Text("Police"), subtitle: const Text("17"),
              onTap: () => launchUrl(Uri.parse('tel:17')),
              trailing: const Icon(Icons.call, color: Colors.green)),
          ListTile(leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: const Text("SAMU"), subtitle: const Text("15"),
              onTap: () => launchUrl(Uri.parse('tel:15')),
              trailing: const Icon(Icons.call, color: Colors.green)),
        ])),
      ]),
    );
  }
}

///// PAGE RÉGLAGES
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  late String _langue;

  @override
  void initState() {
    super.initState();
    _loadNotifPref();
  }

  Future<void> _loadNotifPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true);
    }
  }

  void _noterApp() => launchUrl(
    Uri.parse('https://play.google.com/store/apps/details?id=fr.my_trelaze.my_trelaze'),
    mode: LaunchMode.externalApplication,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _langue = Localizations.localeOf(context).languageCode.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.pageSettings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text(s.settingsAppearance, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSub))),
        Card(child: SwitchListTile(
          secondary: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppTheme.primary)),
          title: Text(s.settingsDarkMode, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(isDark ? s.settingsDarkOn : s.settingsDarkOff),
          value: isDark, activeThumbColor: AppTheme.primary,
          onChanged: (val) => MyApp.of(context).toggleTheme(val),
        )),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text(s.settingsLanguage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSub))),
        Card(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.language, color: Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.settingsAppLanguage, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(s.settingsChooseLang, style: const TextStyle(fontSize: 12, color: AppTheme.textSub)),
            ])),
            Row(children: [
              GestureDetector(
                onTap: () {
                  setState(() => _langue = 'FR');
                  MyApp.of(context).setLocale(const Locale('fr'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Langue : Français 🇫🇷'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppTheme.primary,
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _langue == 'FR' ? AppTheme.primary : Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                  ),
                  child: Text("FR", style: TextStyle(color: _langue == 'FR' ? Colors.white : AppTheme.textSub,
                      fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _langue = 'EN');
                  MyApp.of(context).setLocale(const Locale('en'));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Language: English 🇬🇧'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppTheme.primary,
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _langue == 'EN' ? AppTheme.primary : Colors.grey.shade100,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                  ),
                  child: Text("EN", style: TextStyle(color: _langue == 'EN' ? Colors.white : AppTheme.textSub,
                      fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ]),
          ]),
        )),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text(s.settingsNotifications, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSub))),
        Card(child: SwitchListTile(
          secondary: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.notifications, color: Colors.orange)),
          title: Text(s.settingsPushNotifs, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(_notificationsEnabled ? s.settingsNotifsOn : s.settingsNotifsOff),
          value: _notificationsEnabled, activeThumbColor: AppTheme.primary,
          onChanged: (val) async {
            setState(() => _notificationsEnabled = val);
            final messenger = ScaffoldMessenger.of(context);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('notifications_enabled', val);
            await NotificationService.setNotificationsEnabled(val);
            if (mounted) {
              messenger.showSnackBar(SnackBar(
                content: Text(val ? '${s.settingsNotifications} ✅' : s.settingsNotifsOff),
                backgroundColor: val ? Colors.green : Colors.grey,
                duration: const Duration(seconds: 2),
              ));
            }
          },
        )),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text(s.settingsApp, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSub))),
        Card(child: Column(children: [
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.star, color: Colors.amber)),
            title: Text(s.settingsRate, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(s.settingsRateSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSub),
            onTap: _noterApp,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.info_outline, color: Colors.green)),
            title: Text(s.settingsVersion, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("1.0.0 — App citoyenne indépendante, non officielle"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(s.settingsUpToDate, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_city, color: AppTheme.primary),
            title: Text(s.settingsCity, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("49800 Trélazé, Maine-et-Loire"),
          ),
        ])),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text("Légal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSub)),
        ),
        Card(child: Column(children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primary),
            ),
            title: const Text("Politique de confidentialité", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("RGPD · données collectées · vos droits"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSub),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.gavel_outlined, color: Colors.blue),
            ),
            title: const Text("Mentions légales", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("Application citoyenne indépendante"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSub),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'My Trélazé',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 — Application citoyenne indépendante.\n⚠️ Non officielle — non affiliée à la Mairie de Trélazé.',
            ),
          ),
        ])),
      ]),
    );
  }
}

// ─── PAGE MÉTÉO WRAPPER (chargement autonome pour la recherche) ──────────────

class _MeteoWrapperPage extends StatefulWidget {
  const _MeteoWrapperPage();
  @override
  State<_MeteoWrapperPage> createState() => _MeteoWrapperPageState();
}

class _MeteoWrapperPageState extends State<_MeteoWrapperPage> {
  Map<String, dynamic>? _weather;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WeatherService.getWeather().then((data) {
      if (mounted) setState(() { _weather = data; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_weather == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Météo')),
        body: const Center(child: Text('Données météo indisponibles')),
      );
    }
    return MeteoPage(weatherData: _weather!);
  }
}

// ─── RECHERCHE GLOBALE ────────────────────────────────────────────────────────

class _SearchItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
  const _SearchItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}

final _searchItems = [
  _SearchItem(title: 'Bus & Transport',     subtitle: 'Horaires, lignes, carte',         icon: Icons.directions_bus,    color: Colors.orange,      page: const TransportPage()),
  _SearchItem(title: 'Météo',               subtitle: 'Prévisions à Trélazé',            icon: Icons.wb_sunny,          color: Colors.blue,        page: const _MeteoWrapperPage()),
  _SearchItem(title: 'Actualités',          subtitle: 'France 3 Angers, Angers.fr',      icon: Icons.article,           color: Colors.purple,      page: const NewsPage()),
  _SearchItem(title: 'Agenda',              subtitle: 'Événements de la ville',          icon: Icons.event,             color: Colors.indigo,      page: const AgendaPage()),
  _SearchItem(title: 'Restaurants',         subtitle: 'Se restaurer à Trélazé',          icon: Icons.restaurant,        color: Colors.brown,       page: const RestaurantsPage()),
  _SearchItem(title: 'Objets perdus',       subtitle: 'Signaler ou consulter',           icon: Icons.find_in_page,      color: Colors.red,         page: const ObjetsPage()),
  _SearchItem(title: 'Signalement citoyen', subtitle: 'Voirie, éclairage, graffiti…',   icon: Icons.report_problem,    color: Colors.deepOrange,  page: const SignalementPage()),
  _SearchItem(title: 'Plan de la ville',    subtitle: 'Carte interactive de Trélazé',   icon: Icons.map,               color: AppTheme.primary,   page: const MapPage()),
  _SearchItem(title: 'Déchets',             subtitle: 'Calendrier de collecte, tri',     icon: Icons.delete_outline,    color: Colors.green,       page: const DechetsPage()),
  _SearchItem(title: 'Lieux',               subtitle: 'Parcs, équipements, culture',    icon: Icons.location_on,       color: Colors.teal,        page: const LieuxPage()),
  _SearchItem(title: 'Contacts',            subtitle: 'Mairie, services, urgences',     icon: Icons.contacts,          color: Colors.blue,        page: const ContactsPage()),
  _SearchItem(title: 'Infos utiles',        subtitle: 'Numéros, horaires mairie',       icon: Icons.info,              color: AppTheme.primary,   page: const InfoPage()),
];

class _AppSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Rechercher un service…';

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  List<_SearchItem> get _results {
    if (query.isEmpty) return _searchItems;
    final q = query.toLowerCase();
    return _searchItems.where((i) =>
      i.title.toLowerCase().contains(q) ||
      i.subtitle.toLowerCase().contains(q),
    ).toList();
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _results;
    if (results.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Aucun résultat pour "$query"',
              style: const TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final item = results[i];
        return ListTile(
          leading: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          title: Text(item.title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(item.subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
          onTap: () {
            close(context, item.title);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => item.page));
          },
        );
      },
    );
  }
}