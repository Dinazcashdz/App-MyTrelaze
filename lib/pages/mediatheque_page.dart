import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

// ── Données horaires ──────────────────────────────────────────────────────────

class _Horaire {
  final String jour;
  final String? matin;
  final String? apm;
  const _Horaire(this.jour, {this.matin, this.apm});
}

const _horaires = [
  _Horaire('Mardi',    matin: '10h – 12h',  apm: '14h – 18h'),
  _Horaire('Mercredi', matin: '10h – 12h',  apm: '14h – 18h'),
  _Horaire('Jeudi',    matin: null,          apm: '14h – 18h'),
  _Horaire('Vendredi', matin: '10h – 12h',  apm: '14h – 18h'),
  _Horaire('Samedi',   matin: '10h – 12h30',apm: null),
];

// ── Sections catalogue ────────────────────────────────────────────────────────

const _collections = [
  (icon: Icons.menu_book_outlined,     label: 'Romans & BD',      count: '8 000+'),
  (icon: Icons.child_care,             label: 'Jeunesse',         count: '3 500+'),
  (icon: Icons.album_outlined,         label: 'CD / Vinyles',     count: '1 200+'),
  (icon: Icons.movie_outlined,         label: 'DVD & Blu-ray',    count: '600+'),
  (icon: Icons.newspaper,              label: 'Presse & Revues',  count: '15 titres'),
  (icon: Icons.desktop_mac_outlined,   label: 'Postes internet',  count: '4 postes'),
];

// ── Page ──────────────────────────────────────────────────────────────────────

class MediathequePage extends StatelessWidget {
  const MediathequePage({super.key});

  bool get _isOpenNow {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=lun … 7=dim
    final minutes = now.hour * 60 + now.minute;
    // Mardi=2, Mercredi=3, Jeudi=4, Vendredi=5, Samedi=6
    if (weekday == 2 || weekday == 3 || weekday == 5) {
      return (minutes >= 600 && minutes < 720) ||
          (minutes >= 840 && minutes < 1080);
    }
    if (weekday == 4) return minutes >= 840 && minutes < 1080;
    if (weekday == 6) return minutes >= 600 && minutes < 750;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final open = _isOpenNow;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar avec gradient ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            title: const Text('Médiathèque'),
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF4A235A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A235A), Color(0xFF7B4FA0)],
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
                        Row(children: [
                          const Icon(Icons.local_library_outlined,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ville de Trélazé',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: open
                                ? Colors.green.withValues(alpha: 0.25)
                                : Colors.red.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: open
                                  ? Colors.greenAccent.withValues(alpha: 0.6)
                                  : Colors.redAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: open
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              open
                                  ? 'Ouvert maintenant'
                                  : 'Fermé · Réouverture mardi 10h',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Horaires ─────────────────────────────────────────
                  _SectionTitle('Horaires d\'ouverture',
                      Icons.schedule_outlined),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(children: [
                        for (final h in _horaires) ...[
                          _HoraireRow(h, isToday: _isToday(h.jour)),
                          if (h != _horaires.last)
                            Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade100),
                        ],
                        Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade100),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(children: [
                            SizedBox(
                              width: 90,
                              child: Text(
                                'Lun · Dim',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade500),
                              ),
                            ),
                            Text(
                              'Fermé',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade400),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Collections ──────────────────────────────────────
                  _SectionTitle('Collections disponibles',
                      Icons.collections_bookmark_outlined),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _collections.length,
                    itemBuilder: (ctx, i) {
                      final c = _collections[i];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(c.icon,
                                  color: const Color(0xFF7B4FA0), size: 26),
                              const SizedBox(height: 6),
                              Text(
                                c.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.count,
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Services ─────────────────────────────────────────
                  _SectionTitle('Services', Icons.star_border_outlined),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    child: Column(children: [
                      _ServiceTile(
                        Icons.badge_outlined,
                        'Carte de médiathèque',
                        'Gratuite pour les habitants de Trélazé',
                      ),
                      _ServiceTile(
                        Icons.wifi,
                        'Wi-Fi gratuit',
                        'Connexion libre pendant vos visites',
                      ),
                      _ServiceTile(
                        Icons.print_outlined,
                        'Impression & photocopie',
                        'Noir/blanc et couleur disponibles',
                      ),
                      _ServiceTile(
                        Icons.people_outlined,
                        'Animations & ateliers',
                        'Lectures enfants, clubs lecture, expositions',
                        last: true,
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // ── Accès / contact ──────────────────────────────────
                  _SectionTitle('Accès & contact', Icons.location_on_outlined),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ContactRow(Icons.location_on_outlined,
                                'Rue Paul Éluard, 49800 Trélazé'),
                            const SizedBox(height: 12),
                            _ContactRow(Icons.phone_outlined,
                                '02 41 33 74 80'),
                            const SizedBox(height: 16),
                            Row(children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(
                                        'https://maps.google.com/?q=Médiathèque+Trélazé+49800');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode
                                              .externalApplication);
                                    }
                                  },
                                  icon: const Icon(Icons.directions, size: 16),
                                  label: const Text("Itinéraire"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF7B4FA0),
                                    side: const BorderSide(
                                        color: Color(0xFF7B4FA0)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse('tel:0241337480');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  icon: const Icon(Icons.phone, size: 16),
                                  label: const Text("Appeler"),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF7B4FA0),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(String jourFr) {
    const map = {
      'Lundi': 1, 'Mardi': 2, 'Mercredi': 3,
      'Jeudi': 4, 'Vendredi': 5, 'Samedi': 6, 'Dimanche': 7,
    };
    return DateTime.now().weekday == (map[jourFr] ?? -1);
  }
}

// ── Widgets utilitaires ───────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF7B4FA0)),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSub)),
      ]);
}

class _HoraireRow extends StatelessWidget {
  final _Horaire h;
  final bool isToday;
  const _HoraireRow(this.h, {this.isToday = false});

  @override
  Widget build(BuildContext context) => Container(
        color: isToday
            ? const Color(0xFF7B4FA0).withValues(alpha: 0.07)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          SizedBox(
            width: 90,
            child: Text(
              h.jour,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday ? const Color(0xFF7B4FA0) : null,
              ),
            ),
          ),
          if (h.matin != null && h.apm != null)
            Text('${h.matin}  ·  ${h.apm}',
                style: TextStyle(
                    fontSize: 13,
                    color: isToday ? const Color(0xFF7B4FA0) : null))
          else if (h.matin != null)
            Text(h.matin!,
                style: TextStyle(
                    fontSize: 13,
                    color: isToday ? const Color(0xFF7B4FA0) : null))
          else if (h.apm != null)
            Text(h.apm!,
                style: TextStyle(
                    fontSize: 13,
                    color: isToday ? const Color(0xFF7B4FA0) : null)),
          if (isToday) ...[
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF7B4FA0).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text("Aujourd'hui",
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7B4FA0),
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      );
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool last;
  const _ServiceTile(this.icon, this.title, this.sub, {this.last = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF7B4FA0).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF7B4FA0), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text(sub,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
        ]),
      ),
      if (!last)
        Divider(
            height: 1,
            indent: 68,
            color: isDark ? Colors.white12 : Colors.grey.shade100),
    ]);
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ContactRow(this.icon, this.value);

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF7B4FA0)),
        const SizedBox(width: 10),
        Flexible(
            child: Text(value, style: const TextStyle(fontSize: 14))),
      ]);
}
