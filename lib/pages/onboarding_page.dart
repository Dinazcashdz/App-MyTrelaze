import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_done') ?? false);
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = [
    _OnboardingStep(
      icon: Icons.location_city,
      color: Color(0xFF406868),
      title: "Bienvenue à Trélazé",
      subtitle: "My Trélazé",
      body:
          "L'application citoyenne indépendante pour les habitants de Trélazé. Retrouvez tous les services de votre ville en un seul endroit.",
    ),
    _OnboardingStep(
      icon: Icons.directions_bus,
      color: Color(0xFF008E8C),
      title: "Vos bus en temps réel",
      subtitle: "Transport",
      body:
          "Consultez les prochains passages des lignes 1, 8 et 10 à l'arrêt de votre choix. Plus besoin d'attendre sans savoir !",
    ),
    _OnboardingStep(
      icon: Icons.report_problem,
      color: Color(0xFFE8A020),
      title: "Signalez un problème",
      subtitle: "Signalement citoyen",
      body:
          "Un trou dans la route, un lampadaire cassé, des graffitis ? Signalez-le en quelques secondes avec une photo et votre localisation GPS.",
    ),
    _OnboardingStep(
      icon: Icons.event,
      color: Color(0xFF7263A9),
      title: "L'agenda de la ville",
      subtitle: "Événements",
      body:
          "Ne manquez plus aucun événement : marchés, fêtes, réunions publiques, activités sportives et culturelles.",
    ),
    _OnboardingStep(
      icon: Icons.notifications_active,
      color: Color(0xFF0A2729),
      title: "Restez informé",
      subtitle: "Notifications",
      body:
          "Activez les notifications pour recevoir les alertes importantes concernant votre ville directement sur votre téléphone.",
    ),
  ];

  void _next() {
    if (_page < _steps.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() async {
    await OnboardingPage.markDone();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_page];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Bouton passer
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text("Passer",
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _StepView(step: _steps[i]),
              ),
            ),

            // Indicateurs + bouton
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Points indicateurs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? step.color : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Bouton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: step.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _page < _steps.length - 1
                            ? "Suivant"
                            : "Commencer",
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  final _OnboardingStep step;
  const _StepView({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, size: 52, color: step.color),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Subtitle (catégorie)
          Text(
            step.subtitle.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: step.color,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 12),

          // Titre
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Corps
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String body;
  const _OnboardingStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.body,
  });
}
