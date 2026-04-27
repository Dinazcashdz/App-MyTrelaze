import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

// ─── Modèle ───────────────────────────────────────────────────────────────────

class _Service {
  final String nom;
  final String? adresse;
  final String? horaires;
  final String? phone;
  final String? email;
  final String? url;
  final String? urlLabel;
  final IconData icon;
  final Color color;
  const _Service({
    required this.nom,
    this.adresse,
    this.horaires,
    this.phone,
    this.email,
    this.url,
    this.urlLabel,
    required this.icon,
    required this.color,
  });
}

class _Categorie {
  final String titre;
  final IconData icon;
  final Color color;
  final List<_Service> services;
  const _Categorie({
    required this.titre,
    required this.icon,
    required this.color,
    required this.services,
  });
}

// ─── Données réelles du site trelaze.fr ───────────────────────────────────────

const _categories = [
  _Categorie(
    titre: 'Mairie & Administration',
    icon: Icons.location_city,
    color: AppTheme.primary,
    services: [
      _Service(
        nom: 'Mairie de Trélazé',
        adresse: 'Place Olivier Thuau, CS40027\n49801 Trélazé Cedex',
        horaires: 'Lun : 8h45–12h15, 13h30–17h45\n'
            'Mar / Mer / Ven : 8h45–12h15, 13h30–17h\n'
            'Jeu : 10h–12h15, 13h30–19h\n'
            'Sam : 10h–12h (État civil uniquement)',
        phone: '0241337474',
        email: 'contact@mairie-trelaze.fr',
        icon: Icons.location_city,
        color: AppTheme.primary,
      ),
      _Service(
        nom: 'État civil',
        adresse: 'Mairie — fermé le lundi matin',
        horaires: 'Sam : 10h–12h (naissances, mariages, décès)',
        phone: '0241337474',
        icon: Icons.badge,
        color: AppTheme.primary,
      ),
      _Service(
        nom: 'Carte d\'identité / Passeport',
        adresse: 'Mairie de Trélazé — sur rendez-vous',
        url: 'https://www.rdv360.com/mairie-de-trelaze',
        urlLabel: 'Prendre rendez-vous en ligne',
        icon: Icons.credit_card,
        color: AppTheme.primary,
      ),
      _Service(
        nom: 'Urbanisme & Permis de construire',
        adresse: 'Mairie — sur rendez-vous\nFermé lun. matin, mar. et ven. après-midi',
        phone: '0241699801',
        email: 'service.permis.de.construire@mairie-trelaze.fr',
        url: 'https://gnau3.operis.fr',
        urlLabel: 'Dépôt de permis en ligne',
        icon: Icons.construction,
        color: Colors.orange,
      ),
      _Service(
        nom: 'Inscriptions scolaires',
        adresse: 'Mairie de Trélazé',
        phone: '0241337474',
        url: 'https://www.trelaze.fr/demarches',
        urlLabel: 'Démarches en ligne',
        icon: Icons.school,
        color: Colors.teal,
      ),
    ],
  ),

  _Categorie(
    titre: 'Social & Solidarité',
    icon: Icons.favorite,
    color: Colors.pink,
    services: [
      _Service(
        nom: 'CCAS — Centre Communal d\'Action Sociale',
        adresse: 'Mairie de Trélazé',
        horaires: 'Matin : sur rendez-vous\n'
            '13h30–17h : sans rendez-vous\n'
            'Fermé le lundi matin',
        phone: '0241337465',
        email: 'ccas@mairie-trelaze.fr',
        icon: Icons.people,
        color: Colors.pink,
      ),
      _Service(
        nom: 'Aides sociales & logement',
        adresse: 'CCAS de Trélazé',
        phone: '0241337465',
        email: 'ccas@mairie-trelaze.fr',
        icon: Icons.home_work,
        color: Colors.pink,
      ),
      _Service(
        nom: 'Services aux Séniors',
        adresse: 'Mairie de Trélazé',
        phone: '0241337474',
        icon: Icons.elderly,
        color: Colors.deepPurple,
      ),
    ],
  ),

  _Categorie(
    titre: 'Enfance & Jeunesse',
    icon: Icons.child_care,
    color: Colors.green,
    services: [
      _Service(
        nom: 'Multi-accueil Petite Enfance',
        adresse: 'Trélazé',
        phone: '0241337474',
        url: 'https://espacefamille.aiga.fr',
        urlLabel: 'Espace famille en ligne',
        icon: Icons.child_care,
        color: Colors.green,
      ),
      _Service(
        nom: 'Centres de loisirs (3–11 ans)',
        adresse: 'Trélazé',
        phone: '0241337474',
        icon: Icons.sports_esports,
        color: Colors.lightGreen,
      ),
      _Service(
        nom: 'Hub Rep\'R — Jeunesse (11–15 ans)',
        adresse: 'Trélazé',
        phone: '0241337474',
        icon: Icons.groups,
        color: Colors.teal,
      ),
      _Service(
        nom: 'Plateforme Jeunesse (15–30 ans)',
        adresse: 'Trélazé',
        phone: '0241337474',
        icon: Icons.group_work,
        color: Colors.cyan,
      ),
    ],
  ),

  _Categorie(
    titre: 'Culture',
    icon: Icons.theater_comedy,
    color: Color(0xFF7263A9),
    services: [
      _Service(
        nom: 'Médiathèque Hervé-Bazin',
        adresse: 'Chemin de la Maraîchère, Trélazé',
        phone: '0241691964',
        icon: Icons.library_books,
        color: Color(0xFF7263A9),
      ),
      _Service(
        nom: 'Théâtre de l\'Avant-Scène',
        adresse: 'Trélazé',
        url: 'https://ville-trelaze.mapado.com',
        urlLabel: 'Billetterie en ligne',
        icon: Icons.theater_comedy,
        color: Color(0xFF7263A9),
      ),
      _Service(
        nom: 'Musée de l\'Ardoise',
        adresse: 'Trélazé — patrimoine ardoisier',
        phone: '0241337474',
        icon: Icons.museum,
        color: Color(0xFF5b3db5),
      ),
      _Service(
        nom: 'École de musique Henri Dutilleux',
        adresse: 'Trélazé',
        phone: '0241337474',
        icon: Icons.music_note,
        color: Color(0xFF7263A9),
      ),
      _Service(
        nom: 'École de danse',
        adresse: 'Trélazé',
        phone: '0241337474',
        icon: Icons.self_improvement,
        color: Color(0xFF9c27b0),
      ),
      _Service(
        nom: 'Espace d\'art contemporain',
        adresse: 'Anciennes Écuries — Trélazé',
        phone: '0241337474',
        icon: Icons.palette,
        color: Color(0xFF7263A9),
      ),
    ],
  ),

  _Categorie(
    titre: 'Sport',
    icon: Icons.sports,
    color: Color(0xFFE8A020),
    services: [
      _Service(
        nom: 'Piscine municipale',
        adresse: '100 avenue de la République, Trélazé',
        phone: '0241690179',
        icon: Icons.pool,
        color: Color(0xFF00AEEF),
      ),
      _Service(
        nom: 'Arena Loire Trélazé',
        adresse: 'Avenue de la Loire, Trélazé',
        url: 'https://ville-trelaze.mapado.com',
        urlLabel: 'Événements & billetterie',
        icon: Icons.stadium,
        color: Color(0xFF5b3db5),
      ),
      _Service(
        nom: 'Salle omnisports',
        adresse: 'Trélazé',
        phone: '0241337474',
        icon: Icons.sports_soccer,
        color: Color(0xFFE8A020),
      ),
    ],
  ),

  _Categorie(
    titre: 'Emploi',
    icon: Icons.work,
    color: Colors.indigo,
    services: [
      _Service(
        nom: 'Mission Emploi — moins de 25 ans',
        adresse: 'Mairie de Trélazé',
        phone: '0241337474',
        url: 'https://www.trelaze.fr/offres-demploi',
        urlLabel: 'Voir les offres d\'emploi',
        icon: Icons.work,
        color: Colors.indigo,
      ),
      _Service(
        nom: 'France Travail (Pôle Emploi)',
        adresse: 'Angers',
        url: 'https://www.francetravail.fr',
        urlLabel: 'francetravail.fr',
        icon: Icons.business_center,
        color: Colors.indigo,
      ),
    ],
  ),

  _Categorie(
    titre: 'Liens utiles',
    icon: Icons.link,
    color: Colors.blueGrey,
    services: [
      _Service(
        nom: 'Service-public.fr',
        adresse: 'Démarches administratives nationales',
        url: 'https://www.service-public.fr',
        urlLabel: 'service-public.fr',
        icon: Icons.public,
        color: Colors.blueGrey,
      ),
      _Service(
        nom: 'Immatriculation véhicule (ANTS)',
        adresse: 'Carte grise en ligne',
        url: 'https://immatriculation.ants.gouv.fr',
        urlLabel: 'immatriculation.ants.gouv.fr',
        icon: Icons.directions_car,
        color: Colors.blueGrey,
      ),
      _Service(
        nom: 'Impôts — Centre des Finances',
        adresse: '15 bis rue Dupetit-Thouars, 49000 Angers',
        url: 'https://www.impots.gouv.fr',
        urlLabel: 'impots.gouv.fr',
        icon: Icons.account_balance,
        color: Colors.blueGrey,
      ),
      _Service(
        nom: 'France Services',
        adresse: 'Accompagnement démarches du quotidien',
        url: 'https://www.france-services.gouv.fr',
        urlLabel: 'france-services.gouv.fr',
        icon: Icons.assistant,
        color: Colors.blueGrey,
      ),
      _Service(
        nom: 'Préfecture Maine-et-Loire',
        adresse: 'Place Michel Debré, 49934 Angers Cedex 9',
        phone: '0241818181',
        icon: Icons.account_balance_wallet,
        color: Colors.blueGrey,
      ),
    ],
  ),
];

// ─── Page principale ──────────────────────────────────────────────────────────

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Services municipaux")),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _categories.length,
        itemBuilder: (context, i) => _CategorieSection(cat: _categories[i]),
      ),
    );
  }
}

// ─── Section catégorie ────────────────────────────────────────────────────────

class _CategorieSection extends StatefulWidget {
  final _Categorie cat;
  const _CategorieSection({required this.cat});
  @override
  State<_CategorieSection> createState() => _CategorieSectionState();
}

class _CategorieSectionState extends State<_CategorieSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // En-tête catégorie
      InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cat.icon, color: cat.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(cat.titre,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cat.color)),
            ),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: cat.color,
            ),
          ]),
        ),
      ),
      if (_expanded)
        ...cat.services.map((s) => _ServiceCard(service: s)),
    ]);
  }
}

// ─── Carte service ────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _Service service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Titre + icône
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: service.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(service.icon, color: service.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(service.nom,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),

          // Adresse
          if (service.adresse != null) ...[
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.location_on_outlined,
                  size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Expanded(
                child: Text(service.adresse!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600, height: 1.4)),
              ),
            ]),
          ],

          // Horaires
          if (service.horaires != null) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 5),
              Expanded(
                child: Text(service.horaires!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600, height: 1.4)),
              ),
            ]),
          ],

          // Email
          if (service.email != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('mailto:${service.email}')),
              child: Row(children: [
                Icon(Icons.email_outlined, size: 13, color: service.color),
                const SizedBox(width: 5),
                Text(service.email!,
                    style: TextStyle(
                        fontSize: 11,
                        color: service.color,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ],

          // Boutons d'action
          if (service.phone != null || service.url != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (service.phone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        launchUrl(Uri.parse('tel:${service.phone}')),
                    icon: const Icon(Icons.phone, size: 14),
                    label: Text(_formatTel(service.phone!),
                        style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: service.color,
                      side: BorderSide(color: service.color),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              if (service.phone != null && service.url != null)
                const SizedBox(width: 8),
              if (service.url != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(service.url!),
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: Text(service.urlLabel ?? 'Ouvrir',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: service.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
            ]),
          ],
        ]),
      ),
    );
  }

  static String _formatTel(String tel) {
    if (tel.length == 10) {
      return '${tel.substring(0, 2)} ${tel.substring(2, 4)} '
          '${tel.substring(4, 6)} ${tel.substring(6, 8)} ${tel.substring(8, 10)}';
    }
    return tel;
  }
}
