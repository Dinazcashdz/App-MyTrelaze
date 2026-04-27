import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ──────────────────────────────────────────────────────────────────────────────
// MODÈLE
// ──────────────────────────────────────────────────────────────────────────────

class _Lieu {
  final String nom;
  final String? adresse;
  final String? description;
  final String? horaires;
  final String? phone;
  final String? mapsUrl;
  final IconData icon;
  final Color color;

  const _Lieu({
    required this.nom,
    this.adresse,
    this.description,
    this.horaires,
    this.phone,
    this.mapsUrl,
    required this.icon,
    required this.color,
  });
}

class _Categorie {
  final String titre;
  final IconData icon;
  final Color color;
  final List<_Lieu> lieux;

  const _Categorie({
    required this.titre,
    required this.icon,
    required this.color,
    required this.lieux,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// DONNÉES — source : trelaze.fr
// ──────────────────────────────────────────────────────────────────────────────

const _categories = <_Categorie>[
  // ── Espaces verts ───────────────────────────────────────────────────────────
  _Categorie(
    titre: 'Espaces verts',
    icon: Icons.park,
    color: Colors.green,
    lieux: [
      _Lieu(
        nom: 'Parc des Ardoisières',
        adresse: 'Rond-point Saint-Lézin, 49800 Trélazé',
        description:
            'Ancien site ardoisier reconverti en parc naturel. Lacs, végétation aride, aires de jeux, espaces pique-nique et patrimoine industriel. Accueil de festivals, concerts et expositions.',
        icon: Icons.park,
        color: Colors.green,
        mapsUrl:
            'https://maps.google.com/?q=Parc+des+Ardoisi%C3%A8res+Tr%C3%A9laz%C3%A9',
      ),
      _Lieu(
        nom: 'Micro-forêts (méthode Miyawaki)',
        adresse: 'Rue des Acacias & Rue de la Gare, Trélazé',
        description:
            'Deux micro-forêts urbaines plantées selon la méthode Miyawaki pour favoriser la biodiversité locale.',
        icon: Icons.forest,
        color: Colors.green,
      ),
      _Lieu(
        nom: 'Jardins partagés',
        adresse: 'Différents quartiers de Trélazé',
        description:
            'Jardins collectifs ouverts aux habitants. Renseignements à la mairie.',
        phone: '0241337474',
        icon: Icons.eco,
        color: Color(0xFF388E3C),
      ),
    ],
  ),

  // ── Sport ───────────────────────────────────────────────────────────────────
  _Categorie(
    titre: 'Sport & Loisirs',
    icon: Icons.sports,
    color: Color(0xFF0288D1),
    lieux: [
      _Lieu(
        nom: 'Piscine municipale',
        adresse: '100 bd de la République — Parc des Sports de la Goducière, 49800 Trélazé',
        description:
            'Bassin 25 m + bassin d\'apprentissage pour enfants de moins de 6 ans.',
        horaires:
            'Période scolaire :\n'
            '  Mar 16h30–19h · Mer 15h–19h · Ven 16h–19h30\n'
            'Vacances scolaires :\n'
            '  Mar–Ven 9h–11h30 & 15h–19h30\n'
            'Été :\n'
            '  Mar–Ven 9h15–12h, 14h30–17h30, 18h–19h30',
        phone: '0241690179',
        icon: Icons.pool,
        color: Color(0xFF00AEEF),
        mapsUrl: 'https://maps.google.com/?q=Piscine+Trelaze+République',
      ),
      _Lieu(
        nom: 'Arena Loire Trélazé',
        adresse: '131 rue Ferdinand Vest, 49800 Trélazé',
        description:
            'Complexe multisports et événementiel, accueille compétitions nationales, concerts et spectacles.',
        phone: '0272798000',
        icon: Icons.stadium,
        color: Color(0xFF5b3db5),
        mapsUrl: 'https://maps.google.com/?q=Arena+Loire+Trelaze',
      ),
      _Lieu(
        nom: 'Parc des Sports de la Goducière',
        adresse: '100 bd de la République, 49800 Trélazé',
        description:
            'Gymnases Goducière 1 & 2 · Salle de gymnastique · Piste d\'athlétisme · '
            'Terrains de tennis · Terrain de handball · 2 terrains de foot synthétiques · '
            'Pétanque · Dojo arts martiaux.',
        phone: '0241337474',
        icon: Icons.sports_soccer,
        color: Color(0xFFE8A020),
        mapsUrl: 'https://maps.google.com/?q=Parc+des+Sports+Goduciere+Trelaze',
      ),
      _Lieu(
        nom: 'Skate Park & City Stade',
        adresse: 'Trélazé',
        description:
            '1 200 m² de skate park couvert · Salle de jeux · '
            '2 terrains de foot synthétiques en accès libre.',
        icon: Icons.skateboarding,
        color: Color(0xFFE8A020),
      ),
      _Lieu(
        nom: 'Mouv\'roc — Musculation extérieure',
        adresse: 'Différents quartiers, Trélazé',
        description:
            'Agrès et appareils de musculation en plein air, accessibles gratuitement.',
        icon: Icons.fitness_center,
        color: Color(0xFFE8A020),
      ),
    ],
  ),

  // ── Culture ─────────────────────────────────────────────────────────────────
  _Categorie(
    titre: 'Culture & Patrimoine',
    icon: Icons.museum,
    color: Color(0xFF7263A9),
    lieux: [
      _Lieu(
        nom: 'Médiathèque Hervé-Bazin',
        adresse: 'Chemin de la Maraîchère, 49800 Trélazé',
        description:
            '1 300 m² — livres, films, musique, presse. '
            'Collection locale sur Trélazé et l\'ardoise (~300 documents). '
            'Catalogue en ligne : trelaze.bibli.fr',
        horaires:
            'Mar & Ven : 16h–18h30\n'
            'Mer : 10h–12h & 14h–18h30\n'
            'Sam : 10h–12h30 & 14h–17h\n'
            '1 dim./mois : 10h–12h30',
        phone: '0241691964',
        icon: Icons.library_books,
        color: Color(0xFF7263A9),
        mapsUrl:
            'https://maps.google.com/?q=Mediath%C3%A8que+Herv%C3%A9+Bazin+Tr%C3%A9laz%C3%A9',
      ),
      _Lieu(
        nom: 'Musée de l\'Ardoise',
        adresse: '32 chemin de la Maraîchère, Pôle Hervé Bazin, 49800 Trélazé',
        description:
            '600 ans d\'histoire ardoisière : vie des ouvriers, géologie régionale, '
            'évolution du paysage. Démonstrations de taille d\'ardoise. '
            'Salles modernisées en 2015.',
        phone: '0241337474',
        icon: Icons.museum,
        color: Color(0xFF5b3db5),
        mapsUrl:
            'https://maps.google.com/?q=Mus%C3%A9e+de+l+Ardoise+Tr%C3%A9laz%C3%A9',
      ),
      _Lieu(
        nom: 'Théâtre de l\'Avant-Scène',
        adresse: 'Chemin de la Maraîchère, 49800 Trélazé',
        description:
            '135 places assises + 4 places PMR. '
            'Scène de 80 m², billetterie, loges, salle de réception.',
        phone: '0241337485',
        icon: Icons.theater_comedy,
        color: Color(0xFF7263A9),
        mapsUrl:
            'https://maps.google.com/?q=Th%C3%A9%C3%A2tre+Avant+Sc%C3%A8ne+Tr%C3%A9laz%C3%A9',
      ),
      _Lieu(
        nom: 'Espace d\'Art Contemporain — Anciennes Écuries',
        adresse: 'Pôle Hervé Bazin, Trélazé',
        description:
            'Lieu dédié aux expositions d\'art contemporain, '
            'aménagé dans les anciennes écuries du domaine.',
        phone: '0241337474',
        icon: Icons.palette,
        color: Color(0xFF9c27b0),
      ),
      _Lieu(
        nom: 'École de Musique Henri Dutilleux',
        adresse: 'Pôle Hervé Bazin, Trélazé',
        description:
            'Cours d\'instruments, formation musicale et pratiques collectives.',
        phone: '0241337474',
        icon: Icons.music_note,
        color: Color(0xFF7263A9),
      ),
    ],
  ),

  // ── Santé ───────────────────────────────────────────────────────────────────
  _Categorie(
    titre: 'Santé',
    icon: Icons.local_hospital,
    color: Colors.red,
    lieux: [
      _Lieu(
        nom: 'Centre Hospitalier de Trélazé',
        adresse: '47 rue de la Foucaudière, 49800 Trélazé',
        description: 'Établissement de santé. Accès PMR. Urgences disponibles.',
        phone: '0241417300',
        icon: Icons.local_hospital,
        color: Colors.red,
        mapsUrl:
            'https://maps.google.com/?q=H%C3%B4pital+Tr%C3%A9laz%C3%A9+Foucaudi%C3%A8re',
      ),
      _Lieu(
        nom: 'Urgences — Centre Hospitalier',
        adresse: '47 rue de la Foucaudière, 49800 Trélazé',
        phone: '0241868641',
        icon: Icons.emergency,
        color: Colors.red,
      ),
      _Lieu(
        nom: 'CHU d\'Angers',
        adresse: '4 rue Larrey, 49100 Angers',
        description: 'Centre Hospitalier Universitaire — plateau technique complet.',
        phone: '0241353636',
        icon: Icons.local_hospital,
        color: Colors.red,
        mapsUrl: 'https://maps.google.com/?q=CHU+Angers',
      ),
      _Lieu(
        nom: 'Pharmacie — Place Vasco de Gama',
        adresse: '11 place Vasco de Gama, 49800 Trélazé',
        phone: '0241341800',
        icon: Icons.local_pharmacy,
        color: Color(0xFF2E7D32),
      ),
      _Lieu(
        nom: 'Pharmacie — Jean Jaurès (centre)',
        adresse: '99 rue Jean Jaurès, 49800 Trélazé',
        phone: '0241690027',
        icon: Icons.local_pharmacy,
        color: Color(0xFF2E7D32),
      ),
      _Lieu(
        nom: 'Pharmacie — Jean Jaurès (sud)',
        adresse: '202 rue Jean Jaurès, 49800 Trélazé',
        phone: '0241690259',
        icon: Icons.local_pharmacy,
        color: Color(0xFF2E7D32),
      ),
    ],
  ),

  // ── Éducation ───────────────────────────────────────────────────────────────
  _Categorie(
    titre: 'Éducation',
    icon: Icons.school,
    color: Colors.teal,
    lieux: [
      _Lieu(
        nom: 'Collège Jean Rostand',
        adresse: '142 avenue de la République, 49800 Trélazé',
        description: '~782 élèves (11–14 ans). Collège public.',
        phone: '0241690180',
        icon: Icons.school,
        color: Colors.teal,
        mapsUrl:
            'https://maps.google.com/?q=Coll%C3%A8ge+Jean+Rostand+Tr%C3%A9laz%C3%A9',
      ),
      _Lieu(
        nom: 'Lycée Professionnel Ludovic Ménard',
        adresse: '24 place des Tilleuls, 49801 Trélazé Cedex',
        description: '~670 élèves. Formations professionnelles et CAP.',
        phone: '0241961920',
        icon: Icons.account_balance,
        color: Colors.teal,
        mapsUrl:
            'https://maps.google.com/?q=Lyc%C3%A9e+Ludovic+M%C3%A9nard+Tr%C3%A9laz%C3%A9',
      ),
      _Lieu(
        nom: 'École élémentaire Aimé Césaire',
        adresse: '130 rue André Malraux, 49800 Trélazé',
        phone: '0241337474',
        icon: Icons.school,
        color: Colors.teal,
      ),
      _Lieu(
        nom: 'École élémentaire Paul Fort',
        adresse: '255 rue Élisée Reclus, 49800 Trélazé',
        phone: '0241337474',
        icon: Icons.school,
        color: Colors.teal,
      ),
      _Lieu(
        nom: 'École élémentaire Henri et Yvonne Dufour',
        adresse: '25 rue Édouard Branly, 49800 Trélazé',
        phone: '0241337474',
        icon: Icons.school,
        color: Colors.teal,
      ),
      _Lieu(
        nom: 'École Privée Montrieux',
        adresse: '113 rue André Malraux, 49800 Trélazé',
        phone: '0241337474',
        icon: Icons.school,
        color: Color(0xFF00796B),
      ),
      _Lieu(
        nom: 'France Services',
        adresse: '3 rue Christophe Colomb — Quartier Quantinière, 49800 Trélazé',
        description:
            'Accompagnement gratuit et confidentiel pour toutes vos démarches administratives numériques.',
        phone: '0241337474',
        icon: Icons.assistant,
        color: Colors.teal,
      ),
    ],
  ),
];

// ──────────────────────────────────────────────────────────────────────────────
// PAGE PRINCIPALE
// ──────────────────────────────────────────────────────────────────────────────

class LieuxPage extends StatefulWidget {
  const LieuxPage({super.key});

  @override
  State<LieuxPage> createState() => _LieuxPageState();
}

class _LieuxPageState extends State<LieuxPage> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Categorie> get _filtered {
    if (_query.isEmpty) return _categories;
    final q = _query.toLowerCase();
    return _categories
        .map((cat) {
          final lieux = cat.lieux.where((l) {
            return l.nom.toLowerCase().contains(q) ||
                (l.adresse?.toLowerCase().contains(q) ?? false) ||
                (l.description?.toLowerCase().contains(q) ?? false);
          }).toList();
          if (lieux.isEmpty) return null;
          return _Categorie(
            titre: cat.titre,
            icon: cat.icon,
            color: cat.color,
            lieux: lieux,
          );
        })
        .whereType<_Categorie>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cats = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lieux à Trélazé'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un lieu…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: cats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Aucun résultat pour « $_query »',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: cats.length,
              itemBuilder: (context, i) =>
                  _CategorieSection(cat: cats[i], startExpanded: i == 0),
            ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION CATÉGORIE (expandable)
// ──────────────────────────────────────────────────────────────────────────────

class _CategorieSection extends StatefulWidget {
  final _Categorie cat;
  final bool startExpanded;
  const _CategorieSection(
      {required this.cat, this.startExpanded = false});

  @override
  State<_CategorieSection> createState() => _CategorieSectionState();
}

class _CategorieSectionState extends State<_CategorieSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── En-tête catégorie ──────────────────────────────────────────
      InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.titre,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cat.color)),
                  Text('${cat.lieux.length} lieu${cat.lieux.length > 1 ? 'x' : ''}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: cat.color,
            ),
          ]),
        ),
      ),

      // ── Cartes lieux ──────────────────────────────────────────────
      if (_expanded)
        ...cat.lieux.map((l) => _LieuCard(lieu: l)),
    ]);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CARTE LIEU
// ──────────────────────────────────────────────────────────────────────────────

class _LieuCard extends StatelessWidget {
  final _Lieu lieu;
  const _LieuCard({required this.lieu});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Titre + icône ──────────────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: lieu.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(lieu.icon, color: lieu.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(lieu.nom,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ]),

            // ── Adresse ───────────────────────────────────────────
            if (lieu.adresse != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: lieu.adresse!,
                color: Colors.grey.shade500,
              ),
            ],

            // ── Description ───────────────────────────────────────
            if (lieu.description != null) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.info_outline,
                text: lieu.description!,
                color: Colors.grey.shade500,
              ),
            ],

            // ── Horaires ──────────────────────────────────────────
            if (lieu.horaires != null) ...[
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.access_time,
                text: lieu.horaires!,
                color: Colors.grey.shade500,
              ),
            ],

            // ── Boutons d'action ──────────────────────────────────
            if (lieu.phone != null || lieu.mapsUrl != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                if (lieu.phone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          launchUrl(Uri.parse('tel:${lieu.phone}')),
                      icon: const Icon(Icons.phone, size: 14),
                      label: Text(_formatTel(lieu.phone!),
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: lieu.color,
                        side: BorderSide(
                            color: lieu.color.withValues(alpha: 0.6)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                if (lieu.phone != null && lieu.mapsUrl != null)
                  const SizedBox(width: 8),
                if (lieu.mapsUrl != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(
                          Uri.parse(lieu.mapsUrl!),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.map_outlined, size: 14),
                      label: const Text('Itinéraire',
                          style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lieu.color,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatTel(String tel) {
    final t = tel.replaceAll(RegExp(r'\D'), '');
    if (t.length == 10) {
      return '${t.substring(0, 2)} ${t.substring(2, 4)} '
          '${t.substring(4, 6)} ${t.substring(6, 8)} ${t.substring(8, 10)}';
    }
    return tel;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(icon, size: 13, color: color),
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Text(text,
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade600, height: 1.45)),
      ),
    ]);
  }
}
