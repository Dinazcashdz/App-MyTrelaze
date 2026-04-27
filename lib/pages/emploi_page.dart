import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _contractColor(String type) {
  switch (type.toUpperCase()) {
    case 'CDI':        return const Color(0xFF1B6CA8);
    case 'CDD':        return const Color(0xFF2E7D32);
    case 'ALTERNANCE': return const Color(0xFF7B1FA2);
    case 'STAGE':      return const Color(0xFFE65100);
    case 'INTERIM':    return const Color(0xFF00838F);
    default:           return Colors.grey.shade600;
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays == 0) return "Aujourd'hui";
  if (diff.inDays == 1) return 'Hier';
  if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
  if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} sem.';
  return 'Il y a ${(diff.inDays / 30).floor()} mois';
}

// ── Offres statiques de secours ───────────────────────────────────────────────

final _now = DateTime.now();

final List<Map<String, dynamic>> _offresStatiques = [
  {
    '_id': 's1',
    'titre': 'Agent de production agroalimentaire',
    'entreprise': 'Bonduelle Trélazé',
    'contrat': 'CDI',
    'lieu': 'Trélazé (49)',
    'salaire': 'SMIC + primes',
    'description':
        'Poste sur chaîne de production, travail en équipe 2×8. Aucune expérience requise, formation interne assurée.',
    'contact': '',
    'lien':
        'https://fr.indeed.com/jobs?q=Bonduelle+Trélazé&l=Trélazé+49800',
    '_date': DateTime(_now.year, _now.month, _now.day - 1),
  },
  {
    '_id': 's2',
    'titre': 'Conducteur SPL régional',
    'entreprise': 'Transports Jaouen',
    'contrat': 'CDI',
    'lieu': 'Trélazé (49)',
    'salaire': '2 400 – 2 700 € brut/mois',
    'description':
        'Livraisons régionales Pays de la Loire. Permis EC + FIMO/FCO exigés. Départ de Trélazé.',
    'contact': 'recrutement@jaouen-transports.fr',
    'lien': '',
    '_date': DateTime(_now.year, _now.month, _now.day - 2),
  },
  {
    '_id': 's3',
    'titre': 'Aide-soignant(e)',
    'entreprise': 'EHPAD Les Forges',
    'contrat': 'CDD',
    'lieu': 'Trélazé (49)',
    'salaire': '1 800 – 2 100 € brut/mois',
    'description':
        'Remplacement été. Accompagnement des résidents dans les actes de la vie quotidienne. Diplôme AS ou AMP requis.',
    'contact': 'direction@ehpad-lesforges.fr',
    'lien': '',
    '_date': DateTime(_now.year, _now.month, _now.day - 3),
  },
  {
    '_id': 's4',
    'titre': 'Développeur Flutter / Mobile',
    'entreprise': 'Sophis Digital – Angers',
    'contrat': 'CDI',
    'lieu': 'Angers (49) · hybride',
    'salaire': '32 000 – 42 000 € brut/an',
    'description':
        'Développement d\'applications mobiles cross-platform. Expérience Flutter ou React Native appréciée.',
    'contact': '',
    'lien':
        'https://fr.indeed.com/jobs?q=Flutter+développeur&l=Angers+49000',
    '_date': DateTime(_now.year, _now.month, _now.day - 4),
  },
  {
    '_id': 's5',
    'titre': 'Alternant BTS GPME',
    'entreprise': 'Mairie de Trélazé',
    'contrat': 'Alternance',
    'lieu': 'Trélazé (49)',
    'salaire': 'Légal alternance',
    'description':
        'Gestion administrative, accueil usagers, appui aux services municipaux. Profil BTS GPME ou équivalent.',
    'contact': 'rh@mairie-trelaze.fr',
    'lien': '',
    '_date': DateTime(_now.year, _now.month, _now.day - 5),
  },
  {
    '_id': 's6',
    'titre': 'Employé(e) polyvalent(e)',
    'entreprise': 'Carrefour Market Trélazé',
    'contrat': 'CDI',
    'lieu': 'Trélazé (49)',
    'salaire': 'SMIC',
    'description':
        'Mise en rayon, encaissement, relation client. Temps plein ou partiel possible. Travail le samedi.',
    'contact': '',
    'lien':
        'https://recrutement.carrefour.com',
    '_date': DateTime(_now.year, _now.month, _now.day - 6),
  },
  {
    '_id': 's7',
    'titre': 'Stage communication / réseaux sociaux',
    'entreprise': 'Association SportTrélazé',
    'contrat': 'Stage',
    'lieu': 'Trélazé (49)',
    'salaire': 'Gratification légale',
    'description':
        'Gestion des réseaux sociaux, création de contenu, newsletters. Licence ou Master communication.',
    'contact': 'contact@sport-trelaze.fr',
    'lien': '',
    '_date': DateTime(_now.year, _now.month, _now.day - 7),
  },
  {
    '_id': 's8',
    'titre': 'Manutentionnaire entrepôt logistique',
    'entreprise': 'FM Logistic – Saint-Barthélemy',
    'contrat': 'Intérim',
    'lieu': 'Saint-Barthélemy-d\'Anjou (10 min)',
    'salaire': '11,88 € / heure',
    'description':
        'Préparation de commandes, manutention, port de charges. Horaires 2×8. Mission longue durée possible.',
    'contact': '',
    'lien':
        'https://www.adecco.fr/offres-emploi/manutentionnaire-saint-barthelemy-anjou',
    '_date': DateTime(_now.year, _now.month, _now.day - 8),
  },
];

// ── Page principale ───────────────────────────────────────────────────────────

class EmploiPage extends StatefulWidget {
  const EmploiPage({super.key});

  @override
  State<EmploiPage> createState() => _EmploiPageState();
}

class _EmploiPageState extends State<EmploiPage> {
  String _filterContrat = 'Tous';
  String _search = '';
  final _searchCtrl = TextEditingController();

  static const _contrats = ['Tous', 'CDI', 'CDD', 'Alternance', 'Stage', 'Intérim'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            title: const Text('Mission Emploi'),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B3A6B), Color(0xFF2E6DA4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.work_outline,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Offres d\'emploi à Trélazé et alentours',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF1B3A6B),
          ),
        ],
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('offres_emploi')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (ctx, snap) {
            final firestoreOffres = snap.hasData
                ? snap.data!.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return {
                      ...data,
                      '_id': d.id,
                      '_date': (data['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    };
                  }).toList()
                : <Map<String, dynamic>>[];
            final allOffres = firestoreOffres.isNotEmpty
                ? firestoreOffres
                : _offresStatiques;

            // Filtres
            final offres = allOffres.where((o) {
              final contrat =
                  (o['contrat'] as String? ?? '').toUpperCase();
              final titre = (o['titre'] as String? ?? '').toLowerCase();
              final entreprise =
                  (o['entreprise'] as String? ?? '').toLowerCase();
              final matchContrat = _filterContrat == 'Tous' ||
                  contrat == _filterContrat.toUpperCase();
              final matchSearch = _search.isEmpty ||
                  titre.contains(_search.toLowerCase()) ||
                  entreprise.contains(_search.toLowerCase());
              return matchContrat && matchSearch;
            }).toList();

            return CustomScrollView(
              slivers: [
                // ── Barre de recherche ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un poste, une entreprise…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.grey.shade100,
                      ),
                    ),
                  ),
                ),

                // ── Filtres contrat ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      scrollDirection: Axis.horizontal,
                      itemCount: _contrats.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final c = _contrats[i];
                        final selected = _filterContrat == c;
                        return GestureDetector(
                          onTap: () => setState(() => _filterContrat = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF1B3A6B)
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Compteur ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Row(children: [
                      Text(
                        snap.connectionState == ConnectionState.waiting
                            ? 'Chargement…'
                            : '${offres.length} offre${offres.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]),
                  ),
                ),

                // ── État chargement / vide ──────────────────────────────
                if (snap.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (offres.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyState(search: _search),
                  )
                else
                  // ── Liste des offres ──────────────────────────────────
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _OffreCard(offre: offres[i]),
                      childCount: offres.length,
                    ),
                  ),

                // ── Bannière Mission Emploi ─────────────────────────────
                SliverToBoxAdapter(
                  child: _MissionEmploiBanner(),
                ),

                // ── Liens utiles ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _LiensUtiles(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Carte offre d'emploi ───────────────────────────────────────────────────────

class _OffreCard extends StatelessWidget {
  final Map<String, dynamic> offre;
  const _OffreCard({required this.offre});

  @override
  Widget build(BuildContext context) {
    final titre = offre['titre'] as String? ?? '';
    final entreprise = offre['entreprise'] as String? ?? '';
    final lieu = offre['lieu'] as String? ?? 'Trélazé';
    final contrat = offre['contrat'] as String? ?? '';
    final salaire = offre['salaire'] as String? ?? '';
    final description = offre['description'] as String? ?? '';
    final contact = offre['contact'] as String? ?? '';
    final lien = offre['lien'] as String? ?? '';
    final date = offre['_date'] as DateTime;
    final color = _contractColor(contrat);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : entreprise + badge contrat
              Row(children: [
                // Logo placeholder
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      entreprise.isNotEmpty
                          ? entreprise[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entreprise.isNotEmpty ? entreprise : 'Entreprise',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _timeAgo(date),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    contrat.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Titre du poste
              Text(
                titre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),

              // Lieu + salaire
              Wrap(spacing: 16, runSpacing: 4, children: [
                _InfoChip(Icons.location_on_outlined, lieu),
                if (salaire.isNotEmpty)
                  _InfoChip(Icons.euro_outlined, salaire),
              ]),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              Row(children: [
                if (lien.isNotEmpty || contact.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDetail(context),
                      icon: const Icon(Icons.open_in_new, size: 15),
                      label: const Text('Voir l\'offre'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: color),
                        foregroundColor: color,
                      ),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final titre = offre['titre'] as String? ?? '';
    final entreprise = offre['entreprise'] as String? ?? '';
    final lieu = offre['lieu'] as String? ?? 'Trélazé';
    final contrat = offre['contrat'] as String? ?? '';
    final salaire = offre['salaire'] as String? ?? '';
    final description = offre['description'] as String? ?? '';
    final contact = offre['contact'] as String? ?? '';
    final lien = offre['lien'] as String? ?? '';
    final color = _contractColor(contrat);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, ctrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Poignée
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: _Handle(),
            ),
            // En-tête coloré
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      contrat.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    titre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entreprise,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Corps
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  if (lieu.isNotEmpty)
                    _DetailRow(Icons.location_on_outlined, 'Lieu', lieu),
                  if (salaire.isNotEmpty)
                    _DetailRow(Icons.euro_outlined, 'Rémunération', salaire),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Description du poste',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: const TextStyle(fontSize: 14, height: 1.6)),
                  ],
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _DetailRow(
                        Icons.alternate_email, 'Contact / candidature', contact),
                  ],
                  const SizedBox(height: 24),
                  if (lien.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(lien);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Postuler / voir l\'offre complète'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  if (contact.isNotEmpty && lien.isEmpty) ...[
                    FilledButton.icon(
                      onPressed: () async {
                        final uri =
                            Uri.parse('mailto:$contact?subject=$titre');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Envoyer ma candidature'),
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Bannière Mission Emploi (permanente) ──────────────────────────────────────

class _MissionEmploiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3A6B), Color(0xFF2456A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mission Emploi · Trélazé',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          'Vous cherchez un emploi, une alternance ou un stage ? '
          'La Mission Emploi de Trélazé vous accompagne gratuitement.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pour les – de 25 ans : accompagnement personnalisé, CV, entretiens.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _BannerBtn(
            icon: Icons.phone,
            label: '02 41 33 74 74',
            onTap: () async {
              final uri = Uri.parse('tel:0241337474');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
          const SizedBox(width: 10),
          _BannerBtn(
            icon: Icons.directions_walk,
            label: 'Mairie',
            onTap: () async {
              final uri = Uri.parse(
                  'https://maps.google.com/?q=Place+Olivier+Thuau+49800+Trélazé');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ]),
      ]),
    );
  }
}

class _BannerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BannerBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ── Liens utiles ──────────────────────────────────────────────────────────────

class _LiensUtiles extends StatelessWidget {
  static const _links = [
    (
      icon: Icons.work_outline,
      label: 'France Travail',
      sub: 'Toutes les offres nationales',
      color: Color(0xFF00529B),
      url: 'https://www.francetravail.fr/emploi/recherche/?lieux=49&rayon=20',
    ),
    (
      icon: Icons.school_outlined,
      label: 'Alternance.emploi.gouv.fr',
      sub: 'Trouver une alternance',
      color: Color(0xFF7B1FA2),
      url: 'https://labonnealternance.apprentissage.beta.gouv.fr/',
    ),
    (
      icon: Icons.business_center_outlined,
      label: 'Indeed Trélazé',
      sub: 'Offres proches de chez vous',
      color: Color(0xFF2244CC),
      url: 'https://fr.indeed.com/jobs?l=Tr%C3%A9laz%C3%A9+49800',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'LIENS UTILES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final link in _links)
            _LinkTile(link: link),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final ({
    IconData icon,
    String label,
    String sub,
    Color color,
    String url
  }) link;
  const _LinkTile({required this.link});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final uri = Uri.parse(link.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: link.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(link.icon, color: link.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(link.sub,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 13, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}

// ── Widgets utilitaires ────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ]),
      );
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String search;
  const _EmptyState({required this.search});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(children: [
          Icon(Icons.work_off_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            search.isNotEmpty
                ? 'Aucune offre pour "$search"'
                : 'Aucune offre disponible pour le moment',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Consultez France Travail ci-dessous\nou contactez la Mission Emploi.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ]),
      );
}
