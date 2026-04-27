import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/local_notification_service.dart';

class _Collecte {
  final String type;
  final String description;
  final Color color;
  final IconData icon;
  final List<int> joursEnSemaine; // 1=lun ... 7=dim
  final String frequence;
  final String consignes;
  const _Collecte({
    required this.type,
    required this.description,
    required this.color,
    required this.icon,
    required this.joursEnSemaine,
    required this.frequence,
    required this.consignes,
  });
}

const _collectes = [
  _Collecte(
    type: 'Ordures ménagères',
    description: 'Poubelle grise',
    color: Color(0xFF616161),
    icon: Icons.delete,
    joursEnSemaine: [2, 5], // mar & ven
    frequence: 'Mardi et Vendredi',
    consignes: 'Sortir le bac la veille au soir avant 20h. Rentrer le bac le soir même de la collecte.',
  ),
  _Collecte(
    type: 'Tri sélectif',
    description: 'Poubelle jaune',
    color: Color(0xFFF9A825),
    icon: Icons.recycling,
    joursEnSemaine: [3], // mer
    frequence: 'Mercredi (semaines paires)',
    consignes: 'Plastiques, métaux, papiers, cartons. Pas de verre dans ce bac. Aplatir les emballages.',
  ),
  _Collecte(
    type: 'Verre',
    description: 'Colonne verte',
    color: Color(0xFF388E3C),
    icon: Icons.wine_bar,
    joursEnSemaine: [],
    frequence: 'Dépôt libre en colonne',
    consignes: 'Bouteilles, bocaux et pots en verre uniquement. Ne pas mettre de couvercles, capsules ou bouchons.',
  ),
  _Collecte(
    type: 'Encombrants',
    description: 'Gros objets',
    color: Color(0xFFE8401C),
    icon: Icons.chair,
    joursEnSemaine: [],
    frequence: 'Sur rendez-vous',
    consignes: 'Meubles, électroménager, matelas. Appeler la mairie pour fixer un rendez-vous de collecte.',
  ),
  _Collecte(
    type: 'Déchets verts',
    description: 'Tontes, tailles',
    color: Color(0xFF66BB6A),
    icon: Icons.grass,
    joursEnSemaine: [],
    frequence: 'Déchetterie',
    consignes: 'Branchages, feuilles, tontes. À déposer à la déchetterie d\'Angers Métropole. Brûlage interdit.',
  ),
];

class DechetsPage extends StatefulWidget {
  const DechetsPage({super.key});
  @override
  State<DechetsPage> createState() => _DechetsPageState();
}

class _DechetsPageState extends State<DechetsPage> {
  bool _rappelsActifs = false;

  @override
  void initState() {
    super.initState();
    _loadRappels();
  }

  Future<void> _loadRappels() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _rappelsActifs = prefs.getBool('rappels_dechets') ?? false);
  }

  Future<void> _toggleRappels(bool actif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rappels_dechets', actif);
    setState(() => _rappelsActifs = actif);

    for (final c in _collectes) {
      if (c.joursEnSemaine.isEmpty) continue;
      if (actif) {
        await LocalNotificationService.planifierRappelsDechets(
          id: 100 + _collectes.indexOf(c) * 10,
          titre: 'Collecte demain : ${c.type}',
          corps: 'Pensez à sortir ${c.description.toLowerCase()} ce soir avant 20h.',
          joursEnSemaine: c.joursEnSemaine,
        );
      } else {
        await LocalNotificationService.annulerRappelsDechets(
          100 + _collectes.indexOf(c) * 10,
          c.joursEnSemaine,
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(actif ? 'Rappels de collecte activés ✓' : 'Rappels désactivés'),
        backgroundColor: actif ? Colors.green : Colors.grey,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppL10n.of(context).pageWaste),
        actions: [
          Row(children: [
            Icon(Icons.notifications_outlined,
                size: 18, color: _rappelsActifs ? Colors.amber : Colors.white54),
            const SizedBox(width: 4),
            Switch(
              value: _rappelsActifs,
              onChanged: _toggleRappels,
              activeThumbColor: Colors.amber,
            ),
          ]),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Prochaines collectes
          _ProchainCollecteCard(now: now),

          // Section consignes
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text("Guide du tri",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain)),
          ),

          ..._collectes.map((c) => _CollecteTile(collecte: c)),

          // Déchetterie
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text("Déchetterie",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_on,
                          color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text("Déchetterie d'Angers Métropole",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("Accessible aux habitants de Trélazé",
                            style:
                                TextStyle(fontSize: 12, color: Colors.grey)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _InfoLigne(
                      icon: Icons.access_time,
                      text: "Lun–Sam : 8h30–12h / 13h30–17h30"),
                  const SizedBox(height: 6),
                  _InfoLigne(
                      icon: Icons.info_outline,
                      text:
                          "Apporter sa carte habitant Angers Loire Métropole"),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Carte prochaines collectes ───────────────────────────────────────────────

class _ProchainCollecteCard extends StatelessWidget {
  final DateTime now;
  const _ProchainCollecteCard({required this.now});

  String _prochainJour(_Collecte c) {
    if (c.joursEnSemaine.isEmpty) return c.frequence;
    // Trouve le prochain jour de collecte
    for (int delta = 0; delta <= 7; delta++) {
      final d = now.add(Duration(days: delta));
      if (c.joursEnSemaine.contains(d.weekday)) {
        if (delta == 0) return "Aujourd'hui";
        if (delta == 1) return "Demain";
        const jours = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
        return '${jours[d.weekday]} ${d.day}/${d.month}';
      }
    }
    return c.frequence;
  }

  @override
  Widget build(BuildContext context) {
    final regulieres = _collectes.where((c) => c.joursEnSemaine.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF0A2729)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.calendar_today, color: Colors.white70, size: 16),
          SizedBox(width: 8),
          Text("Prochaines collectes",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        ...regulieres.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(c.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.type,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Text(c.description,
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_prochainJour(c),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
        )),
      ]),
    );
  }
}

// ─── Tuile collecte ───────────────────────────────────────────────────────────

class _CollecteTile extends StatelessWidget {
  final _Collecte collecte;
  const _CollecteTile({required this.collecte});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: collecte.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(collecte.icon, color: collecte.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(collecte.type,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(collecte.description,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.schedule, size: 12, color: collecte.color),
                const SizedBox(width: 4),
                Text(collecte.frequence,
                    style: TextStyle(
                        fontSize: 11,
                        color: collecte.color,
                        fontWeight: FontWeight.w600)),
              ]),
            ])),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey.shade400),
          ]),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: collecte.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(collecte.icon, color: collecte.color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(collecte.type,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17)),
              Text(collecte.description,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600)),
            ])),
          ]),
          const SizedBox(height: 20),
          _InfoLigne(
              icon: Icons.schedule, text: collecte.frequence, bold: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: collecte.color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: collecte.color.withValues(alpha: 0.2)),
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Icon(Icons.tips_and_updates,
                  color: collecte.color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(collecte.consignes,
                    style:
                        const TextStyle(fontSize: 13, height: 1.5)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _InfoLigne extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;
  const _InfoLigne(
      {required this.icon, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppTheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight:
                    bold ? FontWeight.w600 : FontWeight.normal)),
      ),
    ]);
  }
}
