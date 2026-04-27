import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/local_notification_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// HELPERS
// ──────────────────────────────────────────────────────────────────────────────

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _fmtDateFull(DateTime dt) {
  const mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
  return '${jours[dt.weekday - 1]} ${dt.day} ${mois[dt.month - 1]} ${dt.year}';
}

String _fmtMonth(DateTime dt) {
  const mois = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];
  return '${mois[dt.month - 1]} ${dt.year}';
}

String _fmtHeure(DateTime dt) =>
    '${dt.hour}h${dt.minute.toString().padLeft(2, '0')}';

Color _categorieColor(String cat) {
  switch (cat) {
    case 'Culture':    return Colors.purple;
    case 'Sport':      return Colors.blue;
    case 'Jeunesse':   return Colors.orange;
    case 'Solidarité': return Colors.green;
    case 'Marché':     return Colors.teal;
    case 'Fête':       return Colors.pink;
    case 'Réunion':    return AppTheme.primary;
    default:           return Colors.grey;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// AGENDA PAGE
// ──────────────────────────────────────────────────────────────────────────────

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _today = DateTime.now();
  late DateTime _selectedDay;
  late DateTime _focusedMonth;

  // Événements ville (Firestore) — mis à jour par le StreamBuilder
  List<Map<String, dynamic>> _cityEvents = [];

  // RDV personnels (SharedPreferences)
  List<Map<String, dynamic>> _rdvs = [];

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _selectedDay = DateTime(_today.year, _today.month, _today.day);
    _focusedMonth = DateTime(_today.year, _today.month, 1);
    _loadRdvs();
  }

  // ─── SharedPreferences ───────────────────────────────────────────────────

  Future<void> _loadRdvs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('personal_rdvs') ?? '[]';
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    if (mounted) setState(() => _rdvs = list);
  }

  Future<void> _saveRdvs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personal_rdvs', jsonEncode(_rdvs));
  }

  void _addRdv(Map<String, dynamic> rdv) {
    setState(() => _rdvs.add(rdv));
    _saveRdvs();
  }

  void _deleteRdv(String id) {
    LocalNotificationService.annulerRappelRdv(id.hashCode.abs() % 100000);
    setState(() => _rdvs.removeWhere((r) => r['id'] == id));
    _saveRdvs();
  }

  void _updateRdv(Map<String, dynamic> updated) {
    setState(() {
      final idx = _rdvs.indexWhere((r) => r['id'] == updated['id']);
      if (idx != -1) _rdvs[idx] = updated;
    });
    _saveRdvs();
  }

  // ─── Filtres par jour ────────────────────────────────────────────────────

  bool _dayHasCityEvent(DateTime day) => _cityEvents.any((e) {
        final d = e['_date'] as DateTime?;
        return d != null && _sameDay(d, day);
      });

  bool _dayHasRdv(DateTime day) => _rdvs.any((r) {
        final d = DateTime.tryParse(r['date'] as String? ?? '');
        return d != null && _sameDay(d, day);
      });

  List<Map<String, dynamic>> _cityEventsForDay(DateTime day) =>
      _cityEvents.where((e) {
        final d = e['_date'] as DateTime?;
        return d != null && _sameDay(d, day);
      }).toList()
        ..sort((a, b) =>
            (a['_date'] as DateTime).compareTo(b['_date'] as DateTime));

  List<Map<String, dynamic>> _rdvsForDay(DateTime day) =>
      _rdvs.where((r) {
        final d = DateTime.tryParse(r['date'] as String? ?? '');
        return d != null && _sameDay(d, day);
      }).toList()
        ..sort((a, b) {
          final da = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(0);
          final db = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(0);
          return da.compareTo(db);
        });

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppL10n.of(context).pageAgenda),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: "Aujourd'hui",
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _today = now;
                _selectedDay = DateTime(now.year, now.month, now.day);
                _focusedMonth = DateTime(now.year, now.month, 1);
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('evenements')
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _cityEvents = snapshot.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final dt = (d['date'] as Timestamp?)?.toDate();
              return {
                ...d,
                '_id': doc.id,
                '_date': dt,
                '_dateFin': (d['dateFin'] as Timestamp?)?.toDate(),
              };
            }).toList();
          }

          final dayCity = _cityEventsForDay(_selectedDay);
          final dayRdvs = _rdvsForDay(_selectedDay);

          return Column(children: [
            // ── Calendrier mensuel ───────────────────────────────────
            _CalendarSection(
              focusedMonth: _focusedMonth,
              selectedDay: _selectedDay,
              today: _today,
              hasCityEvent: _dayHasCityEvent,
              hasRdv: _dayHasRdv,
              onDaySelected: (d) => setState(() => _selectedDay = d),
              onMonthChanged: (m) => setState(() => _focusedMonth = m),
            ),

            const Divider(height: 1),

            // ── Bandeau du jour sélectionné ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              child: Row(children: [
                Text(
                  _fmtDateFull(_selectedDay),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${dayCity.length + dayRdvs.length} évén.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ]),
            ),

            // ── Liste des événements du jour ─────────────────────────
            Expanded(
              child: _DayEventsView(
                cityEvents: dayCity,
                rdvs: dayRdvs,
                onDeleteRdv: _deleteRdv,
                onEditRdv: (rdv) => _openRdvSheet(existing: rdv),
              ),
            ),
          ]);
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRdvSheet(),
        icon: const Icon(Icons.add),
        label: const Text('Rendez-vous'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openRdvSheet({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRdvSheet(
        initialDate: existing != null
            ? DateTime.tryParse(existing['date'] as String? ?? '') ??
                _selectedDay
            : _selectedDay,
        existing: existing,
        onSave: (rdv) {
          if (existing == null) {
            _addRdv(rdv);
          } else {
            _updateRdv(rdv);
          }
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CALENDRIER MENSUEL
// ──────────────────────────────────────────────────────────────────────────────

class _CalendarSection extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final DateTime today;
  final bool Function(DateTime) hasCityEvent;
  final bool Function(DateTime) hasRdv;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;

  const _CalendarSection({
    required this.focusedMonth,
    required this.selectedDay,
    required this.today,
    required this.hasCityEvent,
    required this.hasRdv,
    required this.onDaySelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Décalage lundi=0 … dimanche=6
    final startOffset = focusedMonth.weekday - 1;
    final daysInMonth =
        DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(children: [
        // ── Navigation mois ──────────────────────────────────────────
        Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onMonthChanged(
              DateTime(focusedMonth.year, focusedMonth.month - 1, 1),
            ),
          ),
          Expanded(
            child: Text(
              _fmtMonth(focusedMonth),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onMonthChanged(
              DateTime(focusedMonth.year, focusedMonth.month + 1, 1),
            ),
          ),
        ]),

        // ── En-têtes jours de la semaine ─────────────────────────────
        const Row(children: [
          _DayHeader('Lun'), _DayHeader('Mar'), _DayHeader('Mer'),
          _DayHeader('Jeu'), _DayHeader('Ven'),
          _DayHeader('Sam', weekend: true), _DayHeader('Dim', weekend: true),
        ]),

        const SizedBox(height: 4),

        // ── Grille ───────────────────────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.05,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, i) {
            if (i < startOffset) return const SizedBox.shrink();
            final dayNum = i - startOffset + 1;
            final day =
                DateTime(focusedMonth.year, focusedMonth.month, dayNum);
            final isToday = _sameDay(day, today);
            final isSelected = _sameDay(day, selectedDay);
            final hasCity = hasCityEvent(day);
            final hasP = hasRdv(day);
            final isWeekend = day.weekday >= 6;

            return GestureDetector(
              onTap: () => onDaySelected(day),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : isToday
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : null,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(color: AppTheme.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (isSelected || isToday)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isWeekend
                                ? Colors.red.shade400
                                : null,
                      ),
                    ),
                    if (hasCity || hasP)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasCity)
                            _Dot(
                              color: isSelected ? Colors.white : Colors.orange,
                            ),
                          if (hasP)
                            _Dot(
                              color: isSelected
                                  ? Colors.white70
                                  : AppTheme.primary,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // ── Légende ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _LegendDot(color: Colors.orange, label: 'Événement ville'),
            const SizedBox(width: 14),
            _LegendDot(color: AppTheme.primary, label: 'Mon RDV'),
          ]),
        ),
      ]),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  final bool weekend;
  const _DayHeader(this.label, {this.weekend = false});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: weekend ? Colors.red.shade300 : Colors.grey,
            ),
          ),
        ),
      );
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 5, height: 5,
        margin: const EdgeInsets.only(top: 2, left: 1, right: 1),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]);
}

// ──────────────────────────────────────────────────────────────────────────────
// LISTE ÉVÉNEMENTS DU JOUR
// ──────────────────────────────────────────────────────────────────────────────

class _DayEventsView extends StatelessWidget {
  final List<Map<String, dynamic>> cityEvents;
  final List<Map<String, dynamic>> rdvs;
  final void Function(String) onDeleteRdv;
  final void Function(Map<String, dynamic>) onEditRdv;

  const _DayEventsView({
    required this.cityEvents,
    required this.rdvs,
    required this.onDeleteRdv,
    required this.onEditRdv,
  });

  @override
  Widget build(BuildContext context) {
    if (cityEvents.isEmpty && rdvs.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.event_available, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Aucun événement ce jour',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Appuyez sur + pour ajouter un rendez-vous',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
      children: [
        for (final e in cityEvents) _CityEventCard(event: e),
        for (final r in rdvs)
          _RdvCard(
            rdv: r,
            onDelete: () => onDeleteRdv(r['id'] as String),
            onEdit: () => onEditRdv(r),
          ),
      ],
    );
  }
}

// ── Carte événement ville ──
class _CityEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  const _CityEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final titre = event['titre'] as String? ?? '';
    final desc = event['description'] as String? ?? '';
    final lieu = event['lieu'] as String? ?? '';
    final cat = event['categorie'] as String? ?? 'Événement';
    final date = event['_date'] as DateTime?;
    final color = _categorieColor(cat);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailEvenementPage(data: event),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            // Barre colorée latérale
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Heure
            if (date != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _fmtHeure(date),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 13),
                ),
              ),
            const SizedBox(width: 10),
            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    Text(titre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (desc.isNotEmpty)
                      Text(desc,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    if (lieu.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 11, color: Colors.grey),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(lieu,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child:
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Carte RDV personnel ──
class _RdvCard extends StatelessWidget {
  final Map<String, dynamic> rdv;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RdvCard({
    required this.rdv,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final titre = rdv['titre'] as String? ?? '';
    final note = rdv['note'] as String? ?? '';
    final colorVal = rdv['couleur'] as int?;
    final color = colorVal != null ? Color(colorVal) : AppTheme.primary;
    final date = DateTime.tryParse(rdv['date'] as String? ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: IntrinsicHeight(
        child: Row(children: [
          // Barre colorée
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Heure
          if (date != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _fmtHeure(date),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 13),
              ),
            ),
          const SizedBox(width: 10),
          // Icone perso
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person, size: 16, color: color),
            ),
          ),
          const SizedBox(width: 10),
          // Infos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (note.isNotEmpty)
                    Text(note,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Mon RDV',
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          // Menu actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Supprimer'),
                    content: Text('Supprimer « $titre » ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET : AJOUTER / MODIFIER UN RDV
// ──────────────────────────────────────────────────────────────────────────────

const _kRdvColors = [
  Color(0xFF1E3A5F),
  Color(0xFFE8A020),
  Color(0xFF4CAF50),
  Color(0xFF9C27B0),
  Color(0xFFF44336),
  Color(0xFF009688),
  Color(0xFFE91E63),
];

class _AddRdvSheet extends StatefulWidget {
  final DateTime initialDate;
  final Map<String, dynamic>? existing;
  final void Function(Map<String, dynamic>) onSave;

  const _AddRdvSheet({
    required this.initialDate,
    required this.onSave,
    this.existing,
  });

  @override
  State<_AddRdvSheet> createState() => _AddRdvSheetState();
}

class _AddRdvSheetState extends State<_AddRdvSheet> {
  late TextEditingController _titreCtrl;
  late TextEditingController _noteCtrl;
  late DateTime _date;
  late TimeOfDay _time;
  late Color _color;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    final exDate = ex != null
        ? DateTime.tryParse(ex['date'] as String? ?? '') ?? widget.initialDate
        : widget.initialDate;

    _titreCtrl = TextEditingController(text: ex?['titre'] as String? ?? '');
    _noteCtrl = TextEditingController(text: ex?['note'] as String? ?? '');
    _date = DateTime(exDate.year, exDate.month, exDate.day);
    _time = ex != null
        ? TimeOfDay(hour: exDate.hour, minute: exDate.minute)
        : TimeOfDay.now();
    final cv = ex?['couleur'] as int?;
    _color = cv != null ? Color(cv) : const Color(0xFF1E3A5F);
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final titre = _titreCtrl.text.trim();
    if (titre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un titre')),
      );
      return;
    }
    final dt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final id = widget.existing?['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    final notifId = id.hashCode.abs() % 100000;

    // Annuler l'ancien rappel si modification
    if (widget.existing != null) {
      await LocalNotificationService.annulerRappelRdv(notifId);
    }
    // Planifier le nouveau rappel 1h avant
    await LocalNotificationService.planifierRappelRdv(
      id: notifId,
      titre: titre,
      note: _noteCtrl.text.trim(),
      rdvDateTime: dt,
    );

    widget.onSave({
      'id': id,
      'titre': titre,
      'note': _noteCtrl.text.trim(),
      'date': dt.toIso8601String(),
      'couleur': _color.toARGB32(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              isEdit ? 'Modifier le rendez-vous' : 'Nouveau rendez-vous',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ── Titre ────────────────────────────────────────────────
            TextField(
              controller: _titreCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Titre *',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // ── Note ─────────────────────────────────────────────────
            TextField(
              controller: _noteCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Note (optionnel)',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // ── Date + Heure ──────────────────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 17),
                  label: Text(
                    '${_date.day}/${_date.month}/${_date.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time, size: 17),
                label: Text(
                  '${_time.hour}h${_time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Couleur ───────────────────────────────────────────────
            const Text('Couleur',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: _kRdvColors
                  .map((c) => GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 10),
                          width: _color == c ? 36 : 30,
                          height: _color == c ? 36 : 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: _color == c
                                ? Border.all(color: Colors.white, width: 2.5)
                                : null,
                            boxShadow: _color == c
                                ? [
                                    BoxShadow(
                                      color: c.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: _color == c
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // ── Bouton sauvegarder ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: Icon(isEdit ? Icons.save : Icons.check),
                label: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// PAGE DÉTAIL ÉVÉNEMENT VILLE
// ──────────────────────────────────────────────────────────────────────────────

class DetailEvenementPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailEvenementPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final titre = data['titre'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final lieu = data['lieu'] as String? ?? '';
    final adresse = data['adresse'] as String? ?? '';
    final organisateur = data['organisateur'] as String? ?? '';
    final contact = data['contact'] as String? ?? '';
    final categorie = data['categorie'] as String? ?? 'Événement';
    final gratuit = data['gratuit'] as bool? ?? true;
    // Compatible avec les deux formats (Timestamp Firestore ou DateTime parsé)
    final date = data['_date'] is DateTime
        ? data['_date'] as DateTime
        : (data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : null);
    final dateFin = data['_dateFin'] is DateTime
        ? data['_dateFin'] as DateTime
        : (data['dateFin'] is Timestamp
            ? (data['dateFin'] as Timestamp).toDate()
            : null);
    final color = _categorieColor(categorie);

    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: ListView(children: [
        // En-tête coloré
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(categorie,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Text(titre,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3)),
            if (date != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.calendar_today,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(_fmtDateFull(date),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${date.hour}h${date.minute.toString().padLeft(2, '0')}'
                  '${dateFin != null ? ' – ${dateFin.hour}h${dateFin.minute.toString().padLeft(2, '0')}' : ''}',
                  style:
                      const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ]),
            ],
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gratuit
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: gratuit ? Colors.green : Colors.orange),
                ),
                child: Text(
                  gratuit ? '✅ Entrée gratuite' : '🎟️ Entrée payante',
                  style: TextStyle(
                      color: gratuit ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Description',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textSub)),
              const SizedBox(height: 8),
              Text(description,
                  style: const TextStyle(fontSize: 15, height: 1.6)),
            ],
            if (lieu.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Lieu',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textSub)),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(lieu,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    if (adresse.isNotEmpty)
                      Text(adresse,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                  ]),
                ),
              ]),
            ],
            if (organisateur.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Organisateur',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textSub)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.people, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(organisateur,
                    style: const TextStyle(fontSize: 15)),
              ]),
            ],
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Contact',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textSub)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.phone, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(contact, style: const TextStyle(fontSize: 15)),
              ]),
            ],
            const SizedBox(height: 30),
          ]),
        ),
      ]),
    );
  }
}
