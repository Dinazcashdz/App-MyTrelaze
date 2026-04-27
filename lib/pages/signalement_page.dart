import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class SignalementPage extends StatelessWidget {
  const SignalementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signalement citoyen")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppTheme.primary),
              SizedBox(width: 12),
              Expanded(child: Text(
                "Signalez un problème à la Mairie de Trélazé : voirie, éclairage, propreté, espaces verts, mobilier urbain…",
                style: TextStyle(fontSize: 13, color: AppTheme.primary),
              )),
            ]),
          ),
          const SizedBox(height: 28),
          const Text("Contactez la Mairie",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.email_outlined,
            color: AppTheme.primary,
            title: "Signaler par email",
            subtitle: "mairie@ville-trelaze.fr",
            onTap: () => launchUrl(Uri(
              scheme: 'mailto',
              path: 'mairie@ville-trelaze.fr',
              queryParameters: {
                'subject': 'Signalement citoyen',
                'body':
                    'Bonjour,\n\nJe souhaite signaler le problème suivant :\n\nCatégorie : \nDescription : \nLocalisation : \n\nCordialement.',
              },
            )),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.phone_outlined,
            color: const Color(0xFF1A5276),
            title: "Appeler la Mairie",
            subtitle: "02 41 33 74 74",
            onTap: () => launchUrl(Uri(scheme: 'tel', path: '0241337474')),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.open_in_browser_outlined,
            color: AppTheme.green,
            title: "Site officiel de la Mairie",
            subtitle: "www.ville-trelaze.fr",
            onTap: () => launchUrl(
              Uri.parse('https://www.ville-trelaze.fr'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),
          const Text("Types de signalements",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryChip(Icons.construction, "Voirie", Colors.orange),
              _CategoryChip(Icons.lightbulb_outline, "Éclairage", Colors.yellow.shade700),
              _CategoryChip(Icons.delete_outline, "Propreté", Colors.green),
              _CategoryChip(Icons.park, "Espaces verts", Colors.teal),
              _CategoryChip(Icons.chair_outlined, "Mobilier urbain", Colors.blue),
              _CategoryChip(Icons.format_paint, "Graffiti", Colors.purple),
              _CategoryChip(Icons.report_problem_outlined, "Autre", Colors.grey),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Mairie ouverte lun–ven 8h45–17h · Jeu jusqu'à 19h · Sam 10h–12h",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(14),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: color.withValues(alpha: 0.5)),
          ]),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CategoryChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
