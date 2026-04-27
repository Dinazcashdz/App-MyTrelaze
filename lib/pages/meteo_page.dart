import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../widgets/weather_icon.dart';

class MeteoPage extends StatefulWidget {
  final Map<String, dynamic> weatherData;
  const MeteoPage({super.key, required this.weatherData});
  @override
  State<MeteoPage> createState() => _MeteoPageState();
}

class _MeteoPageState extends State<MeteoPage> {
  List<Map<String, dynamic>> _forecast = [];
  List<Map<String, dynamic>> _hourly = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      WeatherService.getForecast(),
      WeatherService.getHourlyForecast(),
    ]);
    if (mounted) {
      setState(() {
        _forecast = results[0];
        _hourly = results[1];
        _loading = false;
      });
    }
  }

  String _hm(int unix) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _windDir(dynamic deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    return dirs[((deg as num).toInt() + 22) ~/ 45 % 8];
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.weatherData;
    final condition = w['weather'][0]['main'] as String;
    final gradients = WeatherService.getGradientColors(condition);
    final iconCode = w['weather'][0]['icon'] as String? ?? '01d';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Météo · Trélazé',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradients,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading && _forecast.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHero(w, iconCode)),
                  SliverToBoxAdapter(child: _buildHourlyCard()),
                  SliverToBoxAdapter(child: _buildForecastCard()),
                  SliverToBoxAdapter(child: _buildDetailGrid(w)),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────────
  Widget _buildHero(Map<String, dynamic> w, String iconCode) {
    final temp = (w['main']['temp'] as num).round();
    final desc = w['weather'][0]['description'] as String;
    final tMin = (w['main']['temp_min'] as num).round();
    final tMax = (w['main']['temp_max'] as num).round();

    return Padding(
      padding: const EdgeInsets.only(top: 100, bottom: 16),
      child: Column(children: [
        // Icône réaliste OWM
        WeatherIcon(iconCode: iconCode, size: 120),
        const SizedBox(height: 4),
        // Température
        Text(
          '$temp°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 96,
            fontWeight: FontWeight.w200,
            height: 1,
            letterSpacing: -4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _capitalize(desc),
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 20,
              fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 6),
        Text(
          'Max $tMax°  ·  Min $tMin°',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62), fontSize: 15),
        ),
        const SizedBox(height: 28),
      ]),
    );
  }

  // ── Carte horaire ─────────────────────────────────────────────────────────────
  Widget _buildHourlyCard() {
    if (_hourly.isEmpty && !_loading) return const SizedBox.shrink();
    return _GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle(Icons.schedule_outlined, 'Prévisions heure par heure'),
        const SizedBox(height: 14),
        SizedBox(
          height: 96,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white54, strokeWidth: 2))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _hourly.length,
                  itemBuilder: (ctx, i) {
                    final item = _hourly[i];
                    final dt = DateTime.fromMillisecondsSinceEpoch(
                        (item['dt'] as num).toInt() * 1000);
                    final label = i == 0
                        ? 'Maint.'
                        : '${dt.hour.toString().padLeft(2, '0')}h';
                    final code =
                        item['weather'][0]['icon'] as String? ?? '01d';
                    final t = (item['main']['temp'] as num).round();

                    return Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: i == 0
                          ? BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            )
                          : null,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: i == 0
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: i == 0
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 5),
                            WeatherIcon(iconCode: code, size: 36),
                            const SizedBox(height: 3),
                            Text(
                              '$t°',
                              style: TextStyle(
                                color: i == 0
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                fontWeight: i == 0
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  // ── Carte 7 jours ─────────────────────────────────────────────────────────────
  Widget _buildForecastCard() {
    if (_forecast.isEmpty) return const SizedBox.shrink();

    double gMin = double.infinity, gMax = double.negativeInfinity;
    for (final item in _forecast) {
      final mn = (item['main']['temp_min'] as num).toDouble();
      final mx = (item['main']['temp_max'] as num).toDouble();
      if (mn < gMin) gMin = mn;
      if (mx > gMax) gMax = mx;
    }
    final range = (gMax - gMin).clamp(1.0, double.infinity);

    return _GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle(Icons.calendar_today_outlined, 'Prévisions 7 jours'),
        const SizedBox(height: 8),
        ..._forecast.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final dt = DateTime.fromMillisecondsSinceEpoch(
              (item['dt'] as num).toInt() * 1000);
          final dayName = WeatherService.getDayName(dt);
          final code = item['weather'][0]['icon'] as String? ?? '01d';
          final mn = (item['main']['temp_min'] as num).round();
          final mx = (item['main']['temp_max'] as num).round();
          final barStart = ((mn - gMin) / range).clamp(0.0, 1.0);
          final barWidth = ((mx - mn) / range).clamp(0.05, 1.0);

          return Column(children: [
            if (i > 0)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                // Jour
                SizedBox(
                  width: 88,
                  child: Text(
                    dayName,
                    style: TextStyle(
                      color: i == 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight:
                          i == 0 ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                // Icône OWM
                WeatherIcon(iconCode: code, size: 28),
                const SizedBox(width: 8),
                // Min
                SizedBox(
                  width: 28,
                  child: Text(
                    '$mn°',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                // Barre temp
                Expanded(
                  child: LayoutBuilder(builder: (ctx, cstr) {
                    final total = cstr.maxWidth;
                    return Stack(children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Positioned(
                        left: barStart * total,
                        child: Container(
                          width: (barWidth * total).clamp(8.0, total),
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.lightBlue.shade300,
                              Colors.orange.shade300,
                            ]),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ]);
                  }),
                ),
                const SizedBox(width: 8),
                // Max
                SizedBox(
                  width: 28,
                  child: Text(
                    '$mx°',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ]);
        }),
      ]),
    );
  }

  // ── Grille détails ────────────────────────────────────────────────────────────
  Widget _buildDetailGrid(Map<String, dynamic> w) {
    final feelsLike = (w['main']['feels_like'] as num).round();
    final humidity = w['main']['humidity'] as int;
    final windSpeed = (w['wind']['speed'] as num).toStringAsFixed(1);
    final windDeg = w['wind']['deg'] ?? 0;
    final pressure = w['main']['pressure'] as int;
    final visibility = w['visibility'] as int? ?? 10000;
    final sunrise = w['sys']?['sunrise'] as int?;
    final sunset = w['sys']?['sunset'] as int?;
    final curTemp = (w['main']['temp'] as num).round();

    final stats = [
      _StatItem(
          icon: Icons.thermostat_outlined,
          label: 'Ressenti',
          value: '$feelsLike°',
          sub: feelsLike > curTemp ? 'Plus chaud' : 'Plus frais'),
      _StatItem(
          icon: Icons.water_drop_outlined,
          label: 'Humidité',
          value: '$humidity%',
          sub: humidity > 70
              ? 'Élevée'
              : humidity > 40
                  ? 'Confortable'
                  : 'Faible'),
      _StatItem(
          icon: Icons.air,
          label: 'Vent',
          value: '$windSpeed m/s',
          sub: _windDir(windDeg)),
      _StatItem(
          icon: Icons.visibility_outlined,
          label: 'Visibilité',
          value: visibility >= 1000
              ? '${(visibility / 1000).toStringAsFixed(0)} km'
              : '$visibility m',
          sub: visibility >= 10000
              ? 'Excellente'
              : visibility >= 5000
                  ? 'Bonne'
                  : 'Réduite'),
      _StatItem(
          icon: Icons.speed_outlined,
          label: 'Pression',
          value: '$pressure',
          sub: 'hPa'),
      if (sunrise != null && sunset != null)
        _StatItem(
            icon: Icons.wb_twilight_outlined,
            label: 'Lever / Coucher',
            value: _hm(sunrise),
            sub: 'Coucher ${_hm(sunset)}'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
        ),
        itemCount: stats.length,
        itemBuilder: (ctx, i) => _GlassCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(stats[i].icon,
                      color: Colors.white.withValues(alpha: 0.58), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    stats[i].label.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5),
                  ),
                ]),
                Text(stats[i].value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        height: 1)),
                Text(stats[i].sub,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
              ]),
        ),
      ),
    );
  }

  Widget _cardTitle(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: Colors.white.withValues(alpha: 0.58), size: 13),
      const SizedBox(width: 6),
      Text(
        title.toUpperCase(),
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.58),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8),
      ),
    ]);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  const _StatItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.sub});
}

// ── Glassmorphisme ────────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
