import 'package:flutter/material.dart';

/// Affiche l'icône officielle OpenWeatherMap avec effet de lueur dynamique.
/// [iconCode] : code OWM comme "01d", "10n", etc.
class WeatherIcon extends StatelessWidget {
  final String iconCode;
  final double size;

  const WeatherIcon({super.key, required this.iconCode, this.size = 60});

  String get _url =>
      'https://openweathermap.org/img/wn/$iconCode@4x.png';

  // Couleur de la lueur selon le type de météo
  Color get _glowColor {
    final code = int.tryParse(iconCode.replaceAll(RegExp(r'[dn]'), '')) ?? 0;
    if (code == 1) return const Color(0xFFFFD060);        // grand soleil
    if (code == 2) return const Color(0xFFFFBC44);        // peu nuageux
    if (code == 3 || code == 4) return const Color(0xFF7A98B0); // nuageux
    if (code == 9) return const Color(0xFF4A80BC);        // averses
    if (code == 10) return const Color(0xFF3A6EA8);       // pluie
    if (code == 11) return const Color(0xFF6050A0);       // orage
    if (code == 13) return const Color(0xFFA0C8E8);       // neige
    if (code == 50) return const Color(0xFF8A9EB4);       // brume
    return const Color(0xFF6A90B0);
  }

  Color get _glowColorNight {
    final code = int.tryParse(iconCode.replaceAll(RegExp(r'[dn]'), '')) ?? 0;
    if (code == 1) return const Color(0xFF4060C0);  // nuit claire
    if (code == 2) return const Color(0xFF3A5490);  // nuit peu nuageux
    return _glowColor;
  }

  bool get _isNight => iconCode.endsWith('n');

  String get _fallback {
    final code = int.tryParse(iconCode.replaceAll(RegExp(r'[dn]'), '')) ?? 0;
    if (code == 1) return _isNight ? '🌙' : '☀️';
    if (code == 2) return _isNight ? '🌙' : '🌤️';
    if (code == 3 || code == 4) return '☁️';
    if (code == 9) return '🌦️';
    if (code == 10) return '🌧️';
    if (code == 11) return '⛈️';
    if (code == 13) return '❄️';
    if (code == 50) return '🌫️';
    return '🌤️';
  }

  @override
  Widget build(BuildContext context) {
    final glow = _isNight ? _glowColorNight : _glowColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.55),
            blurRadius: size * 0.7,
            spreadRadius: size * 0.05,
          ),
          BoxShadow(
            color: glow.withValues(alpha: 0.25),
            blurRadius: size * 1.2,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
      child: Image.network(
        _url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: CircularProgressIndicator(
                color: glow,
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (ctx, err, st) => Text(
          _fallback,
          style: TextStyle(fontSize: size * 0.72),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
