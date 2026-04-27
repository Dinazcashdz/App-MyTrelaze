import 'package:flutter/material.dart';
import '../theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Politique de confidentialité")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            title: "1. Présentation",
            body:
                "My Trélazé est une application citoyenne indépendante, non affiliée à la Mairie de Trélazé. "
                "Elle est développée et maintenue par un développeur indépendant à titre informatif pour les habitants de Trélazé.",
          ),
          _Section(
            title: "2. Données collectées",
            body:
                "• Localisation GPS : utilisée uniquement pour afficher votre position sur la carte et calculer les itinéraires. Elle n'est jamais transmise à des tiers.\n"
                "• Photos : envoyées uniquement lors du dépôt d'un objet trouvé ou perdu, stockées sur Firebase Storage (Google). Non partagées.\n"
                "• Token de notification (FCM) : utilisé pour l'envoi de notifications push. Non partagé.\n"
                "• Préférences locales (thème, langue) : stockées uniquement sur votre appareil via SharedPreferences.\n\n"
                "Le signalement citoyen redirige vers les canaux officiels de la Mairie (email, téléphone, site web) — aucune donnée n'est collectée par l'application dans ce cadre.",
          ),
          _Section(
            title: "3. Données Firebase",
            body:
                "L'application utilise Firebase (Google) pour :\n"
                "• Firestore : agenda des événements, offres d'emploi, objets trouvés/perdus.\n"
                "• Firebase Storage : photos des objets trouvés/perdus.\n"
                "• Firebase Messaging : notifications push.\n\n"
                "Google Firebase est soumis à la politique de confidentialité de Google : https://policies.google.com/privacy",
          ),
          _Section(
            title: "4. Données météo",
            body:
                "Les données météo sont récupérées via l'API OpenWeatherMap. "
                "Seule la ville « Trélazé » est transmise, aucune donnée personnelle.",
          ),
          _Section(
            title: "5. Conservation des données",
            body:
                "Les objets trouvés/perdus déposés via l'application sont conservés dans Firestore jusqu'à leur réclamation. "
                "Vous pouvez demander la suppression de vos données à tout moment en nous contactant.",
          ),
          _Section(
            title: "6. Vos droits (RGPD)",
            body:
                "Conformément au RGPD, vous disposez d'un droit d'accès, de rectification et de suppression de vos données. "
                "Pour exercer ces droits, contactez : azedinesadniapro@gmail.com",
          ),
          _Section(
            title: "7. Sécurité",
            body:
                "Toutes les communications entre l'application et les serveurs sont chiffrées (HTTPS/TLS). "
                "Aucune donnée sensible n'est stockée en clair sur l'appareil.",
          ),
          _Section(
            title: "8. Contact",
            body:
                "Pour toute question relative à la confidentialité :\n"
                "azedinesadniapro@gmail.com",
          ),
          SizedBox(height: 8),
          Text(
            "Dernière mise à jour : avril 2026",
            style: TextStyle(fontSize: 12, color: AppTheme.textSub),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppTheme.textMain)),
        ],
      ),
    );
  }
}
