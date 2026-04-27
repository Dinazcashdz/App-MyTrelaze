import 'package:flutter/material.dart';
import '../theme.dart';

/// Logo indépendant de l'app My Trélazé.
/// Monogramme "MT" sur fond dégradé teal→vert, avec un pin en filigrane.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E5F5F), AppTheme.primary, Color(0xFF5A9A6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.45),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Filigrane pin
          Positioned(
            bottom: size * 0.04,
            right: size * 0.05,
            child: Icon(
              Icons.location_on_rounded,
              color: Colors.white.withValues(alpha: 0.10),
              size: size * 0.75,
            ),
          ),
          // Monogramme MT
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'MT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -size * 0.012,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: size * 0.38,
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.3), Colors.white, Colors.white.withValues(alpha: 0.3)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'My Trélazé',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: size * 0.095,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
