import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';
import '../services/irigo_service.dart';
import '../services/favori_service.dart';

// ─── Coordonnées GPS approximatives de chaque arrêt ──────────────────────────

const _stopCoords = <String, LatLng>{
  // ── Trélazé ───────────────────────────────────────────────────────────────
  'TRELAZE':  LatLng(47.4588, -0.4744), // Quantinière
  'MALRAUX':  LatLng(47.4575, -0.4735),
  'FMAURIAC': LatLng(47.4553, -0.4716),
  'TRELGARE': LatLng(47.4530, -0.4680),
  'CIMTRELA': LatLng(47.4490, -0.4665),
  'EGLTRELA': LatLng(47.4482, -0.4672),
  'MAIRTREL': LatLng(47.4478, -0.4680),
  'MONTHIBE': LatLng(47.4455, -0.4745),
  'ARENA':    LatLng(47.4435, -0.4787),
  'BUISSON':  LatLng(47.4420, -0.4840),
  'MORLONG':  LatLng(47.4405, -0.4920),
  'BOURSE':   LatLng(47.4440, -0.5020),
  'MENARD':   LatLng(47.4450, -0.4970),
  'CHOUTEAU': LatLng(47.4460, -0.4950),
  'FRESNAIE': LatLng(47.4480, -0.4920),
  'MARAIS':   LatLng(47.4500, -0.5044),
  'BELLVUTR': LatLng(47.4490, -0.5010),
  'LEOLAGRA': LatLng(47.4478, -0.5099),
  'ALLUMETT': LatLng(47.4535, -0.5220),
  'LEFEVRE':  LatLng(47.4550, -0.5260),
  'HMTREL':   LatLng(47.4560, -0.4700),
  'HMTRE-E':  LatLng(47.4560, -0.4700),
  // ── Retour (même position physique) ──────────────────────────────────────
  'MARAIS-E': LatLng(47.4500, -0.5044),
  'FRESNA-E': LatLng(47.4480, -0.4920),
  'CHOUTE-E': LatLng(47.4460, -0.4950),
  'MENA-E':   LatLng(47.4450, -0.4970),
  'LEFEVR-E': LatLng(47.4550, -0.5260),
  'BUISSO-E': LatLng(47.4420, -0.4840),
  'ARENA-E':  LatLng(47.4435, -0.4787),
  'MONTHI-E': LatLng(47.4455, -0.4745),
  'MAIRTR-E': LatLng(47.4478, -0.4680),
  'EGLTRE-E': LatLng(47.4482, -0.4672),
  'CIMETR-E': LatLng(47.4490, -0.4665),
  'TRELGA-E': LatLng(47.4530, -0.4680),
  'FMAURI-E': LatLng(47.4553, -0.4716),
  'MALRAU-E': LatLng(47.4575, -0.4735),
  'ALLUME-E': LatLng(47.4535, -0.5220),
  'LEOLAG-E': LatLng(47.4478, -0.5099),
  'BELVTR-E': LatLng(47.4490, -0.5010),
  'PYRAM2-E': LatLng(47.4430, -0.4900),
  // ── Angers — L1 (vers Lorraine) ──────────────────────────────────────────
  'JEANVIL':  LatLng(47.4685, -0.5449), // Jean Vilar
  'RALLIE':   LatLng(47.4730, -0.5530), // Ralliement
  'LORRAIN':  LatLng(47.4695, -0.5697), // Lorraine (terminus)
  // ── Angers — L8 (Ste-Gemmes ↔ Floriloire) ────────────────────────────────
  'STLEZIN':  LatLng(47.4310, -0.4590), // St-Lézin (L10)
  'STGEMME':  LatLng(47.4375, -0.5543), // Ste-Gemmes
  'MADELE':   LatLng(47.4598, -0.5474), // Madeleine
  'FLORILO':  LatLng(47.4400, -0.5558), // Floriloire
  // ── Angers — L10 (vers Provins) ──────────────────────────────────────────
  'PROVINS':  LatLng(47.4640, -0.5244), // Provins (terminus L10)
};

double _distanceM(LatLng a, LatLng b) {
  const r = 6371000.0;
  final dLat = (b.latitude - a.latitude) * pi / 180;
  final dLng = (b.longitude - a.longitude) * pi / 180;
  final sin2 = sin(dLat / 2) * sin(dLat / 2) +
      cos(a.latitude * pi / 180) * cos(b.latitude * pi / 180) *
          sin(dLng / 2) * sin(dLng / 2);
  return r * 2 * atan2(sqrt(sin2), sqrt(1 - sin2));
}

// ─── Données des lignes ───────────────────────────────────────────────────────

class _Ligne {
  final String num;
  final String label;
  final String terminus1;
  final String terminus2;
  final Color color;
  final bool trelaze;
  final bool hasData;
  const _Ligne({
    required this.num,
    required this.label,
    required this.terminus1,
    required this.terminus2,
    required this.color,
    this.trelaze = false,
    this.hasData = false,
  });
  String get trajet => '$terminus1 ↔ $terminus2';
  String get routeNum {
    if (num == '1') return '01';
    if (num == '8') return '08';
    return num;
  }
}

const _lignesTrelaze = [
  _Ligne(num:'1',   label:'L1',   terminus1:'Quantinière',  terminus2:'Lorraine',    color:Color(0xFF008E8C), trelaze:true, hasData:true),
  _Ligne(num:'8',   label:'L8',   terminus1:'Ste-Gemmes',   terminus2:'Floriloire',  color:Color(0xFFE50076), trelaze:true, hasData:true),
  _Ligne(num:'10',  label:'L10',  terminus1:'St-Lézin',     terminus2:'Provins',     color:Color(0xFF7263A9), trelaze:true, hasData:true),
  _Ligne(num:'112', label:'L112', terminus1:'Quantinière',  terminus2:'St-Aubin',    color:Color(0xFF484F54), trelaze:true, hasData:true),
  _Ligne(num:'163', label:'L163', terminus1:'Trélazé',      terminus2:'Villon',      color:Color(0xFF484F54), trelaze:true, hasData:true),
  _Ligne(num:'172', label:'L172', terminus1:'Quantinière',  terminus2:'Chevrolier',  color:Color(0xFF484F54), trelaze:true, hasData:true),
];

const _lignesAngers = [
  _Ligne(num:'A',  label:'TW A', terminus1:'Avrillé',       terminus2:'Beaucouzé',      color:Color(0xFF004B9E)),
  _Ligne(num:'2',  label:'L2',  terminus1:'La Meignanne',   terminus2:'St-Barthélemy',  color:Color(0xFFE5312B)),
  _Ligne(num:'3',  label:'L3',  terminus1:'Pellouailles',   terminus2:'Monplaisir',     color:Color(0xFF78BE20)),
  _Ligne(num:'4',  label:'L4',  terminus1:'Villebernier',   terminus2:'Belle-Beille',   color:Color(0xFFF7941D)),
  _Ligne(num:'5',  label:'L5',  terminus1:'Écouflant',      terminus2:'CHU',            color:Color(0xFF8B1A8F)),
  _Ligne(num:'6',  label:'L6',  terminus1:'St-Sylvain',     terminus2:'Ralliement',     color:Color(0xFF00AEEF)),
  _Ligne(num:'7',  label:'L7',  terminus1:'Avrillé',        terminus2:'Monplaisir',     color:Color(0xFFF9B234)),
  _Ligne(num:'9',  label:'L9',  terminus1:'St-Léonard',     terminus2:'Hauts-de-Saint', color:Color(0xFF00833E)),
  _Ligne(num:'11', label:'L11', terminus1:'Vernantes',      terminus2:'Jean-Vilar',     color:Color(0xFF006F62)),
  _Ligne(num:'12', label:'L12', terminus1:'Rochefort',      terminus2:'Madeleine',      color:Color(0xFFE5312B)),
  _Ligne(num:'15', label:'L15', terminus1:'Briollay',       terminus2:'Ralliement',     color:Color(0xFF004B9E)),
  _Ligne(num:'16', label:'L16', terminus1:'Cantenay',       terminus2:'Angers Centre',  color:Color(0xFF78BE20)),
  _Ligne(num:'20', label:'L20', terminus1:'Murs-Erigné',    terminus2:'Madeleine',      color:Color(0xFFF7941D)),
  _Ligne(num:'21', label:'L21', terminus1:'Les Ponts',      terminus2:'Jean-Vilar',     color:Color(0xFF8B1A8F)),
  _Ligne(num:'22', label:'L22', terminus1:'Ste-Gemmes',     terminus2:'Belle-Beille',   color:Color(0xFF00AEEF)),
  _Ligne(num:'N1', label:'N1',  terminus1:'Noctibus',       terminus2:'Angers Centre',  color:Color(0xFF1A237E)),
];

// ─── PAGE PRINCIPALE ──────────────────────────────────────────────────────────

class TransportPage extends StatefulWidget {
  const TransportPage({super.key});
  @override
  State<TransportPage> createState() => _TransportPageState();
}

class _TransportPageState extends State<TransportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F1F),
      appBar: AppBar(
        title: const Text("Bus · Irigo"),
        backgroundColor: const Color(0xFF0A2729),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.greenLight,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.schedule, size: 18), text: "Lignes"),
            Tab(icon: Icon(Icons.alt_route, size: 18), text: "Trajet"),
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: "Carte"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_LignesTab(), _PlanifierTab(), _CarteTab()],
      ),
    );
  }
}

// ─── ONGLET LIGNES ────────────────────────────────────────────────────────────

class _LignesTab extends StatefulWidget {
  const _LignesTab();
  @override
  State<_LignesTab> createState() => _LignesTabState();
}

class _LignesTabState extends State<_LignesTab> {
  List<FavoriStop> _favoris = [];

  @override
  void initState() {
    super.initState();
    _loadFavoris();
  }

  Future<void> _loadFavoris() async {
    final favs = await FavoriService.getAll();
    if (mounted) setState(() => _favoris = favs);
  }

  Future<void> _refresh() async {
    await _loadFavoris();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.greenLight,
      backgroundColor: const Color(0xFF0A2729),
      child: ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // ── Section Favoris ──
        if (_favoris.isNotEmpty) ...[
          _sectionHeader(Icons.star_rounded, Colors.amber,
              "Mes arrêts favoris", "Glisse à gauche pour supprimer"),
          ..._favoris.map((f) => _FavoriCard(fav: f, onChanged: _loadFavoris)),
          const SizedBox(height: 8),
        ],
        _sectionHeader(Icons.directions_bus_filled, const Color(0xFF008E8C),
            "Lignes de Trélazé", "Passent par Trélazé · données disponibles"),
        ..._lignesTrelaze.map((l) => _LigneTile(ligne: l)),
        const SizedBox(height: 8),
        _sectionHeader(Icons.directions_bus, AppTheme.greenLight,
            "Réseau Irigo — Angers", "Toutes les lignes du réseau"),
        ..._lignesAngers.map((l) => _LigneTile(ligne: l)),
      ],
    ),  // ListView
    );  // RefreshIndicator
  }

  Widget _sectionHeader(IconData icon, Color color, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            Text(sub, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
          ],
        )),
      ]),
    );
  }
}

// ─── Carte favori ─────────────────────────────────────────────────────────────

class _FavoriCard extends StatefulWidget {
  final FavoriStop fav;
  final VoidCallback onChanged;
  const _FavoriCard({required this.fav, required this.onChanged});
  @override
  State<_FavoriCard> createState() => _FavoriCardState();
}

class _FavoriCardState extends State<_FavoriCard> {
  List<Map<String, dynamic>> _passages = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await IrigoService.getPassagesByStopAndRoute(
        widget.fav.stopId, '${widget.fav.lineNum}_${widget.fav.dir}');
    if (mounted) setState(() { _passages = data; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final fav = widget.fav;
    final color = Color(fav.lineColor);
    final dirLabel = fav.dir == 0 ? 'Aller' : 'Retour';
    final ligne = _lignesTrelaze.firstWhere(
        (l) => l.routeNum == fav.lineNum, orElse: () => _lignesTrelaze.first);

    return Dismissible(
      key: Key(fav.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red.shade800, borderRadius: BorderRadius.circular(14)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      ),
      onDismissed: (_) async {
        await FavoriService.remove(fav.key);
        widget.onChanged();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF122020),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => HorairesPage(ligne: ligne))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Badge ligne
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(fav.lineNum,
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 14))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fav.stopName,
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 14, color: Colors.white)),
                Text('Ligne ${fav.lineNum} · $dirLabel',
                  style: TextStyle(fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4))),
                const SizedBox(height: 7),
                // Prochains passages
                if (!_loaded)
                  SizedBox(height: 14, width: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: color))
                else if (_passages.isEmpty)
                  Text('Aucun passage prévu',
                    style: TextStyle(fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.3)))
                else
                  Row(children: _passages.take(4).map((p) {
                    final isRT = !(p['theorique'] as bool? ?? true);
                    final tc = isRT ? Colors.greenAccent : color;
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: tc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tc.withValues(alpha: 0.3)),
                      ),
                      child: Text(p['heure'] as String? ?? '--:--',
                        style: TextStyle(fontSize: 11, color: tc,
                            fontWeight: FontWeight.w700)),
                    );
                  }).toList()),
              ])),
              const Icon(Icons.chevron_right, size: 16, color: Colors.white24),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LigneTile extends StatelessWidget {
  final _Ligne ligne;
  const _LigneTile({required this.ligne});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF122020),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3A3A)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: ligne.hasData
            ? () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => HorairesPage(ligne: ligne)))
            : () => _showInfoSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            // Badge couleur ligne
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: ligne.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(ligne.num,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 14),
            // Infos
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ligne.label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(ligne.terminus1,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(Icons.swap_horiz, size: 13, color: Colors.white24),
                  ),
                  Flexible(child: Text(ligne.terminus2,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
                    overflow: TextOverflow.ellipsis)),
                ]),
              ],
            )),
            // Action
            if (ligne.hasData)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ligne.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.schedule, size: 12, color: ligne.color),
                  const SizedBox(width: 5),
                  Text("Horaires",
                    style: TextStyle(fontSize: 11, color: ligne.color, fontWeight: FontWeight.w700)),
                ]),
              )
            else
              Icon(Icons.chevron_right, size: 18, color: Colors.white24),
          ]),
        ),
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF122020),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(color: ligne.color, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(ligne.num,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ligne.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              Text(ligne.trajet, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
            ])),
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.lightBlueAccent, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text(
                "Les horaires de cette ligne sont disponibles sur le site Irigo ou dans l'appli Irigo.",
                style: TextStyle(fontSize: 13, height: 1.4, color: Colors.white70))),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

// ─── PAGE HORAIRES (plein écran) ──────────────────────────────────────────────

class HorairesPage extends StatefulWidget {
  final _Ligne ligne;
  const HorairesPage({super.key, required this.ligne});
  @override
  State<HorairesPage> createState() => _HorairesPageState();
}

class _HorairesPageState extends State<HorairesPage> {
  int _dir = 0;                          // 0 = aller, 1 = retour
  String? _selectedStopId;
  List<Map<String, dynamic>> _passages = [];
  bool _loading = false;
  bool _locating = false;
  bool _isFavori = false;
  String? _nearestStopId;
  Timer? _refreshTimer;

  // Barre de recherche arrêts
  final _searchCtrl = TextEditingController();
  String _query = '';

  _Ligne get _l => widget.ligne;

  List<IrigoStop> get _allStops => IrigoService.getStops(_l.routeNum, _dir);

  List<IrigoStop> get _filteredStops {
    if (_query.isEmpty) return _allStops;
    return _allStops.where((s) =>
        s.name.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  String get _terminus1 => _l.terminus1;
  String get _terminus2 => _l.terminus2;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
    _initStop();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _charger());
  }

  Future<void> _checkFavori() async {
    if (_selectedStopId == null) return;
    final key = '${_l.routeNum}_${_dir}_$_selectedStopId';
    final isFav = await FavoriService.isFavori(key);
    if (mounted) setState(() => _isFavori = isFav);
  }

  Future<void> _toggleFavori() async {
    if (_selectedStopId == null) return;
    final stopName = _allStops
        .firstWhere((s) => s.id == _selectedStopId,
            orElse: () => const IrigoStop(id: '', name: ''))
        .name;
    await FavoriService.toggle(FavoriStop(
      lineNum: _l.routeNum,
      dir: _dir,
      stopId: _selectedStopId!,
      stopName: stopName,
      lineColor: _l.color.toARGB32(),
    ));
    if (mounted) setState(() => _isFavori = !_isFavori);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _initStop() {
    final stops = IrigoService.getStops(_l.routeNum, _dir);
    if (stops.isNotEmpty) {
      _selectedStopId = stops.first.id;
      _charger();
      _checkFavori();
    }
  }

  void _changeDir(int d) {
    setState(() {
      _dir = d;
      _selectedStopId = null;
      _passages = [];
      _nearestStopId = null;
      _isFavori = false;
      _query = '';
      _searchCtrl.clear();
    });
    _initStop();
  }

  void _selectStop(String id) {
    setState(() { _selectedStopId = id; _passages = []; });
    _charger();
    _checkFavori();
  }

  Future<void> _charger() async {
    if (_selectedStopId == null) return;
    setState(() => _loading = true);
    final data = await IrigoService.getPassagesByStopAndRoute(
        _selectedStopId!, '${_l.routeNum}_$_dir');
    if (mounted) setState(() { _passages = data; _loading = false; });
  }

  Future<void> _geolocate() async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1. GPS activé ?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        messenger.showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.location_off, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Activez la localisation dans les paramètres du téléphone')),
          ]),
          backgroundColor: Colors.orange.shade700,
          action: SnackBarAction(
            label: 'Paramètres',
            textColor: Colors.white,
            onPressed: Geolocator.openLocationSettings,
          ),
          duration: const Duration(seconds: 5),
        ));
        return;
      }

      // 2. Permission accordée ?
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        messenger.showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.lock, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Permission refusée définitivement — modifiez dans les réglages')),
          ]),
          backgroundColor: Colors.red.shade700,
          action: SnackBarAction(
            label: 'Réglages',
            textColor: Colors.white,
            onPressed: Geolocator.openAppSettings,
          ),
          duration: const Duration(seconds: 5),
        ));
        return;
      }
      if (perm == LocationPermission.denied) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Permission de localisation refusée'),
          backgroundColor: Colors.grey,
        ));
        return;
      }

      // 3. Position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userPos = LatLng(pos.latitude, pos.longitude);
      final stops = _allStops;
      double bestDist = double.infinity;
      IrigoStop? nearest;
      for (final s in stops) {
        final coord = _stopCoords[s.id];
        if (coord == null) continue;
        final d = _distanceM(userPos, coord);
        if (d < bestDist) { bestDist = d; nearest = s; }
      }
      if (nearest != null && mounted) {
        setState(() => _nearestStopId = nearest!.id);
        _selectStop(nearest.id);
        final dist = bestDist < 1000
            ? '${bestDist.round()} m'
            : '${(bestDist / 1000).toStringAsFixed(1)} km';
        messenger.showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.my_location, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Arrêt le plus proche : ${nearest.name} ($dist)')),
          ]),
          backgroundColor: _l.color,
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erreur de localisation : $e'),
        backgroundColor: Colors.grey.shade700,
      ));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _l.color;
    final isScolaire = ['112', '163', '172'].contains(_l.num);
    final stops = _filteredStops;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_l.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(_l.trajet,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            overflow: TextOverflow.ellipsis)),
        ]),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFavori ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavori ? Colors.amber : Colors.white70,
            ),
            tooltip: _isFavori ? 'Retirer des favoris' : 'Ajouter aux favoris',
            onPressed: _toggleFavori,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _charger,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D1F1F),
      body: Column(children: [

        // ── Bloc supérieur ─────────────────────────────────────────────────
        Container(
          color: const Color(0xFF0A2729),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(children: [

            // ── Sélecteur direction (vertical) ─────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF122020),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E3A3A)),
              ),
              child: Column(children: [
                // Aller
                _DirRow(
                  label: 'Aller',
                  from: _terminus1,
                  to: _terminus2,
                  selected: _dir == 0,
                  color: color,
                  isFirst: true,
                  onTap: () => _changeDir(0),
                ),
                Divider(height: 1, color: color.withValues(alpha: 0.15)),
                // Retour
                _DirRow(
                  label: 'Retour',
                  from: _terminus2,
                  to: _terminus1,
                  selected: _dir == 1,
                  color: color,
                  isFirst: false,
                  onTap: () => _changeDir(1),
                ),
              ]),
            ),

            const SizedBox(height: 12),

            // Bouton GPS
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _geolocate,
                icon: _locating
                    ? SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: color))
                    : const Icon(Icons.my_location, size: 16),
                label: Text(_locating ? 'Localisation…' : 'Arrêt le plus proche'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withValues(alpha: 0.7)),
                  backgroundColor: color.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Barre de recherche arrêt
            TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher un arrêt…',
                hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.35)),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.white.withValues(alpha: 0.4)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                        onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: const Color(0xFF1A3535),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2A4545)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2A4545)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
            ),
          ]),
        ),

        // ── Chips arrêts ───────────────────────────────────────────────────
        if (stops.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Aucun arrêt trouvé',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
          )
        else
          Container(
            height: 44,
            color: const Color(0xFF0F2828),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              itemCount: stops.length,
              itemBuilder: (_, i) {
                final stop = stops[i];
                final sel = stop.id == _selectedStopId;
                final isNearest = stop.id == _nearestStopId;
                return GestureDetector(
                  onTap: () => _selectStop(stop.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? color : const Color(0xFF1A3535),
                      borderRadius: BorderRadius.circular(20),
                      border: isNearest && !sel
                          ? Border.all(color: color, width: 1.5)
                          : Border.all(color: const Color(0xFF2A4545)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (isNearest) ...[
                        Icon(Icons.my_location, size: 11,
                          color: sel ? Colors.white : color),
                        const SizedBox(width: 4),
                      ],
                      Text(stop.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white
                              : isNearest ? color
                              : Colors.white54)),
                    ]),
                  ),
                );
              },
            ),
          ),

        if (isScolaire)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
            ),
            child: const Row(children: [
              Icon(Icons.school, size: 14, color: Colors.orange),
              SizedBox(width: 8),
              Flexible(child: Text(
                "Ligne scolaire — horaires variables selon le calendrier scolaire",
                style: TextStyle(fontSize: 11, color: Colors.orange))),
            ]),
          ),

        const Divider(height: 1, color: Color(0xFF1A3030)),

        // ── Heure de référence ─────────────────────────────────────────────
        if (!_loading && _passages.isNotEmpty)
          Builder(builder: (_) {
            final now = DateTime.now();
            final t = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
              child: Row(children: [
                const Icon(Icons.access_time, size: 11, color: Colors.white24),
                const SizedBox(width: 4),
                Text('Horaires à partir de $t · actualisation auto 60s',
                  style: const TextStyle(fontSize: 10, color: Colors.white24)),
              ]),
            );
          }),

        // ── Passages ──────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: color))
              : _passages.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 56, color: Colors.white.withValues(alpha: 0.12)),
                        const SizedBox(height: 12),
                        Text("Service terminé pour aujourd'hui",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15)),
                        const SizedBox(height: 6),
                        Text("Aucun passage prévu sur cet arrêt",
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
                      ]))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _passages.length,
                      separatorBuilder: (_, __) => const SizedBox.shrink(),
                      itemBuilder: (_, i) {
                        final p = _passages[i];
                        final heure = p['heure'] as String? ?? '--:--';
                        final mins = p['minutesRestantes'] as int? ?? -1;
                        final pColor = p['color'] as Color? ?? color;
                        final isRealtime = !(p['theorique'] as bool? ?? true);
                        final stopName = _allStops
                            .firstWhere((s) => s.id == _selectedStopId,
                                orElse: () => const IrigoStop(id: '', name: ''))
                            .name;

                        // Countdown label
                        final String countdownLabel;
                        final Color countdownColor;
                        if (mins <= 0) {
                          countdownLabel = "À l'arrêt";
                          countdownColor = Colors.orange;
                        } else if (mins == 1) {
                          countdownLabel = '1 min';
                          countdownColor = Colors.orange;
                        } else if (mins <= 5) {
                          countdownLabel = '$mins min';
                          countdownColor = Colors.orangeAccent;
                        } else if (mins < 60) {
                          countdownLabel = '$mins min';
                          countdownColor = Colors.greenAccent;
                        } else {
                          final h = mins ~/ 60;
                          final m = mins % 60;
                          countdownLabel = m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2,'0')}';
                          countdownColor = Colors.white54;
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: pColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: pColor.withValues(alpha: mins <= 5 ? 0.4 : 0.15)),
                          ),
                          child: Row(children: [
                            // Badge ligne
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                  color: pColor, borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(p['ligne'] ?? _l.num,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            ),
                            const SizedBox(width: 14),
                            // Destination + countdown
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('vers ${_dir == 0 ? _terminus2 : _terminus1}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.45),
                                      fontWeight: FontWeight.w500)),
                                const SizedBox(height: 3),
                                Text(stopName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 13,
                                      color: Colors.white)),
                                const SizedBox(height: 6),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: countdownColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: countdownColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(countdownLabel,
                                      style: TextStyle(
                                          fontSize: 11, color: countdownColor,
                                          fontWeight: FontWeight.w700)),
                                  ),
                                  if (isRealtime) ...[
                                    const SizedBox(width: 7),
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      Container(width: 5, height: 5,
                                        decoration: const BoxDecoration(
                                            color: Colors.greenAccent, shape: BoxShape.circle)),
                                      const SizedBox(width: 4),
                                      const Text('Temps réel',
                                        style: TextStyle(fontSize: 9, color: Colors.greenAccent,
                                            fontWeight: FontWeight.w600)),
                                    ]),
                                  ],
                                ]),
                              ],
                            )),
                            // Heure grande
                            Text(heure,
                              style: TextStyle(
                                  fontSize: 30, fontWeight: FontWeight.w900,
                                  color: mins <= 5
                                      ? countdownColor
                                      : isRealtime ? Colors.greenAccent : Colors.white,
                                  letterSpacing: -1,
                                  height: 1)),
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ─── Ligne de direction Aller / Retour ───────────────────────────────────────

class _DirRow extends StatelessWidget {
  final String label;
  final String from;
  final String to;
  final bool selected;
  final Color color;
  final bool isFirst;
  final VoidCallback onTap;
  const _DirRow({
    required this.label, required this.from, required this.to,
    required this.selected, required this.color,
    required this.isFirst, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isFirst
        ? const BorderRadius.vertical(top: Radius.circular(14))
        : const BorderRadius.vertical(bottom: Radius.circular(14));
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.13) : Colors.transparent,
          borderRadius: radius,
          border: selected
              ? Border(
                  left: BorderSide(color: color, width: 3),
                )
              : null,
        ),
        child: Row(children: [
          // Indicateur radio
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color : Colors.transparent,
              border: Border.all(
                color: selected ? color : Colors.white24,
                width: selected ? 0 : 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          // Texte
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.white54)),
              const SizedBox(height: 2),
              Row(children: [
                Text(from,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.white30),
                  overflow: TextOverflow.ellipsis),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.arrow_forward_rounded,
                    size: 11,
                    color: selected
                        ? color.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.2)),
                ),
                Flexible(child: Text(to,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.white30),
                  overflow: TextOverflow.ellipsis)),
              ]),
            ],
          )),
          // Chevron si non sélectionné
          if (!selected)
            Icon(Icons.radio_button_unchecked,
              size: 16, color: Colors.white.withValues(alpha: 0.15)),
        ]),
      ),
    );
  }
}

// ─── ONGLET PLANIFICATEUR ─────────────────────────────────────────────────────

class _PlanifierTab extends StatefulWidget {
  const _PlanifierTab();
  @override
  State<_PlanifierTab> createState() => _PlanifierTabState();
}

class _PlanifierTabState extends State<_PlanifierTab> {
  String? _fromName;
  String? _toName;
  List<TripResult> _resultsAller = [];
  List<TripResult> _resultsRetour = [];
  bool _searched = false;

  void _swap() {
    setState(() {
      final tmp = _fromName;
      _fromName = _toName;
      _toName = tmp;
    });
    if (_fromName != null && _toName != null) _search();
  }

  void _search() {
    if (_fromName == null || _toName == null) return;
    setState(() {
      _resultsAller = IrigoService.planTrip(_fromName!, _toName!);
      _resultsRetour = IrigoService.planTrip(_toName!, _fromName!);
      _searched = true;
    });
  }

  Future<void> _pickStop(bool isFrom) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0D1F1F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _StopPickerSheet(
        title: isFrom ? 'Choisir le départ' : 'Choisir l\'arrivée',
        exclude: isFrom ? _toName : _fromName,
        fromStop: isFrom ? null : _fromName,
      ),
    );
    if (name != null) {
      setState(() {
        if (isFrom) { _fromName = name; } else { _toName = name; }
      });
      if (_fromName != null && _toName != null) _search();
    }
  }

  Widget _sectionHeader(String label, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 10),
        Text('$count trajet${count > 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const Spacer(),
        Text('Horaires indicatifs',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noAller = _searched && _resultsAller.isEmpty;
    final noRetour = _searched && _resultsRetour.isEmpty;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildPlanner()),

        // ── Aucun résultat du tout ──
        if (noAller && noRetour)
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.route, size: 56, color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 14),
              Text('Aucun trajet direct trouvé',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15)),
              const SizedBox(height: 6),
              Text('Essaie un autre arrêt ou une autre ligne',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
            ]),
          )),

        // ── Section ALLER ──
        if (_resultsAller.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _sectionHeader('ALLER  $_fromName → $_toName',
                Icons.arrow_forward, Colors.greenAccent, _resultsAller.length)),
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _TripResultCard(result: _resultsAller[i]),
            childCount: _resultsAller.length,
          )),
        ],

        // ── Section RETOUR ──
        if (_resultsRetour.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _sectionHeader('RETOUR  $_toName → $_fromName',
                Icons.arrow_back, Colors.orangeAccent, _resultsRetour.length)),
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => _TripResultCard(result: _resultsRetour[i]),
            childCount: _resultsRetour.length,
          )),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildPlanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF122020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A3A)),
      ),
      child: Column(children: [
        // Départ
        _StopField(
          icon: Icons.circle_outlined,
          iconColor: Colors.greenAccent,
          hint: 'Arrêt de départ',
          value: _fromName,
          onTap: () => _pickStop(true),
          onClear: () => setState(() { _fromName = null; _resultsAller = []; _resultsRetour = []; _searched = false; }),
        ),
        // Séparateur + swap
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            const SizedBox(width: 11),
            Container(width: 1.5, height: 22, color: const Color(0xFF2A4545)),
            const Spacer(),
            GestureDetector(
              onTap: _swap,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3535),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A4545)),
                ),
                child: const Icon(Icons.swap_vert, color: Colors.white70, size: 18),
              ),
            ),
          ]),
        ),
        // Arrivée
        _StopField(
          icon: Icons.location_on,
          iconColor: Colors.redAccent,
          hint: 'Arrêt d\'arrivée',
          value: _toName,
          onTap: () => _pickStop(false),
          onClear: () => setState(() { _toName = null; _resultsAller = []; _resultsRetour = []; _searched = false; }),
        ),
        // Bouton si les deux champs sont vides
        if (_fromName == null && _toName == null) ...[
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.info_outline, size: 13, color: Colors.white24),
            const SizedBox(width: 7),
            Text('Touche un champ pour choisir un arrêt',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.3))),
          ]),
        ],
      ]),
    );
  }
}

// ─── Champ arrêt ──────────────────────────────────────────────────────────────

class _StopField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String hint;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _StopField({required this.icon, required this.iconColor, required this.hint,
      required this.value, required this.onTap, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2828),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(
            value ?? hint,
            style: TextStyle(
              color: value != null ? Colors.white : Colors.white38,
              fontSize: 14,
              fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
            ),
          )),
          if (value != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 16, color: Colors.white38),
            ),
        ]),
      ),
    );
  }
}

// ─── Sélecteur d'arrêt (bottom sheet) ─────────────────────────────────────────

class _StopPickerSheet extends StatefulWidget {
  final String title;
  final String? exclude;
  final String? fromStop; // si défini → trie les arrêts compatibles en premier
  const _StopPickerSheet({required this.title, this.exclude, this.fromStop});
  @override
  State<_StopPickerSheet> createState() => _StopPickerSheetState();
}

class _StopPickerSheetState extends State<_StopPickerSheet> {
  final _ctrl = TextEditingController();
  String _query = '';
  late final List<String> _allStops;
  late final Map<String, List<String>> _lineInfo;
  late final Set<String> _compatible;

  @override
  void initState() {
    super.initState();
    _lineInfo = IrigoService.getStopLineInfo();
    if (widget.fromStop != null) {
      final ordered = IrigoService.getCompatibleArrivals(widget.fromStop!);
      _allStops = ordered.where((s) => s != widget.exclude).toList();
      // Les arrêts compatibles sont ceux qui partagent au moins une ligne avec le départ
      final fromLines = _lineInfo[widget.fromStop!] ?? [];
      _compatible = _allStops
          .where((s) => (_lineInfo[s] ?? []).any((l) => fromLines.contains(l)))
          .toSet();
    } else {
      _allStops = IrigoService.getAllPlannerStopNames()
          .where((s) => s != widget.exclude).toList();
      _compatible = {};
    }
    _ctrl.addListener(() => setState(() => _query = _ctrl.text));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<String> get _filtered {
    if (_query.trim().isEmpty) return _allStops;
    final q = _query.toLowerCase();
    return _allStops.where((s) => s.toLowerCase().contains(q)).toList();
  }

  Color _lineColor(String label) {
    switch (label) {
      case 'L1':   return const Color(0xFF008E8C);
      case 'L8':   return const Color(0xFFE50076);
      case 'L10':  return const Color(0xFF7263A9);
      default:     return const Color(0xFF484F54);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    // Séparer compatibles et autres dans la liste filtrée
    final compatibles = filtered.where((s) => _compatible.contains(s)).toList();
    final others = filtered.where((s) => !_compatible.contains(s)).toList();
    final hasCompat = widget.fromStop != null && compatibles.isNotEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
            if (widget.fromStop != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 12, color: Colors.white38),
                  const SizedBox(width: 5),
                  Text('Les arrêts en vert sont atteignables depuis ${widget.fromStop}',
                    style: const TextStyle(fontSize: 11, color: Colors.white38)),
                ]),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher un arrêt…',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: Colors.white38),
                      onPressed: _ctrl.clear)
                  : null,
              filled: true,
              fillColor: const Color(0xFF1A3535),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            controller: scrollCtrl,
            children: [
              if (hasCompat) ...[
                _sectionLabel('Arrêts accessibles directement', Colors.greenAccent),
                ...compatibles.map((stop) => _stopTile(stop, true)),
                _sectionLabel('Autres arrêts', Colors.white38),
                ...others.map((stop) => _stopTile(stop, false)),
              ] else
                ...filtered.map((stop) => _stopTile(stop, false)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _stopTile(String stop, bool isCompat) {
    final lines = _lineInfo[stop] ?? [];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isCompat
              ? Colors.greenAccent.withValues(alpha: 0.15)
              : const Color(0xFF1A3535),
          borderRadius: BorderRadius.circular(8),
          border: isCompat
              ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.4))
              : null,
        ),
        child: Icon(Icons.directions_bus,
          color: isCompat ? Colors.greenAccent : Colors.white38, size: 16),
      ),
      title: Text(stop,
        style: TextStyle(
          color: isCompat ? Colors.white : Colors.white70,
          fontSize: 14,
          fontWeight: isCompat ? FontWeight.w600 : FontWeight.normal,
        )),
      subtitle: lines.isNotEmpty
          ? Wrap(
              spacing: 4,
              children: lines.map((l) => Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _lineColor(l).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _lineColor(l).withValues(alpha: 0.5)),
                ),
                child: Text(l,
                  style: TextStyle(fontSize: 9, color: _lineColor(l),
                      fontWeight: FontWeight.w700)),
              )).toList(),
            )
          : null,
      onTap: () => Navigator.pop(context, stop),
    );
  }
}

// ─── Carte résultat de trajet ──────────────────────────────────────────────────

class _TripResultCard extends StatefulWidget {
  final TripResult result;
  const _TripResultCard({required this.result});
  @override
  State<_TripResultCard> createState() => _TripResultCardState();
}

class _TripResultCardState extends State<_TripResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final wait = r.waitMinutes;
    final waitText = wait == 0 ? "À l'arrêt" : wait == 1 ? '1 min' : '$wait min';
    final waitColor = wait <= 2 ? Colors.orange : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF122020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A3A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── En-tête cliquable ──
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Badge ligne
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: r.lineColor, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(r.lineNum,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 14))),
              ),
              const SizedBox(width: 14),
              // Horaires + chips
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                  Text(r.departureTime,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 24, height: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: Colors.white.withValues(alpha: 0.3), size: 16)),
                  Text(r.arrivalTime,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 24, height: 1)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _Chip(Icons.timer_outlined, '${r.durationMin} min', r.lineColor),
                  _Chip(Icons.place_outlined, '${r.stops.length} arrêts', Colors.white38),
                  _Chip(Icons.schedule, waitText, waitColor),
                ]),
              ])),
              // Chevron
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more, color: Colors.white38, size: 22),
              ),
            ]),
          ),
        ),
        // Direction
        Padding(
          padding: const EdgeInsets.fromLTRB(76, 0, 16, 14),
          child: Row(children: [
            Text('Direction ', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.35))),
            Flexible(child: Text(r.terminus,
              style: TextStyle(fontSize: 12, color: r.lineColor, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
          ]),
        ),
        // ── Détail arrêts ──
        if (_expanded) ...[
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Column(children: r.stops.asMap().entries.map((e) {
              final isFirst = e.key == 0;
              final isLast = e.key == r.stops.length - 1;
              return _StopRow(
                stop: e.value, isFirst: isFirst, isLast: isLast, lineColor: r.lineColor);
            }).toList()),
          ),
        ],
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Ligne de la timeline d'arrêts ────────────────────────────────────────────

class _StopRow extends StatelessWidget {
  final StopTime stop;
  final bool isFirst;
  final bool isLast;
  final Color lineColor;
  const _StopRow({required this.stop, required this.isFirst,
      required this.isLast, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    final prominent = isFirst || isLast;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Timeline
        SizedBox(width: 20, child: Column(children: [
          Container(
            width: prominent ? 12 : 8,
            height: prominent ? 12 : 8,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: prominent ? lineColor : Colors.transparent,
              border: Border.all(
                  color: prominent ? lineColor : lineColor.withValues(alpha: 0.4),
                  width: prominent ? 0 : 1.5),
            ),
          ),
          if (!isLast)
            Expanded(child: Center(
              child: Container(width: 2,
                  color: lineColor.withValues(alpha: prominent ? 0.5 : 0.25)),
            )),
        ])),
        const SizedBox(width: 12),
        // Nom + heure
        Expanded(child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(children: [
            Expanded(child: Text(stop.stopName,
              style: TextStyle(
                fontSize: prominent ? 14 : 12,
                color: prominent ? Colors.white : Colors.white.withValues(alpha: 0.55),
                fontWeight: prominent ? FontWeight.w700 : FontWeight.normal,
              ))),
            Text(stop.time,
              style: TextStyle(
                fontSize: prominent ? 14 : 12,
                color: prominent ? Colors.white : Colors.white.withValues(alpha: 0.45),
                fontWeight: prominent ? FontWeight.w700 : FontWeight.normal,
              )),
          ]),
        )),
      ]),
    );
  }
}

// ─── ONGLET CARTE ─────────────────────────────────────────────────────────────

class _CarteTab extends StatefulWidget {
  const _CarteTab();
  @override
  State<_CarteTab> createState() => _CarteTabState();
}

class _CarteTabState extends State<_CarteTab> with TickerProviderStateMixin {
  int _idx = 0;
  final MapController _mapController = MapController();
  String? _tappedStop;
  bool _satellite = false;
  bool _followMe = false;
  LatLng? _userPos;
  StreamSubscription<Position>? _positionSub;
  List<Map<String, dynamic>> _stopBuses = [];
  bool _loadingBuses = false;
  late AnimationController _pulseCtrl;

  // ── Itinéraire ─────────────────────────────────────────────────────────────
  bool _itineraryOpen = false;
  String? _tripFrom;
  String? _tripTo;
  List<TripResult> _tripResults = [];
  TripResult? _selectedTrip;
  bool _searchingTrip = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    // Délai pour laisser le premier frame se rendre avant de démarrer le GPS
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTracking());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) { return; }
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _userPos = LatLng(pos.latitude, pos.longitude));
      if (_followMe) {
        _mapController.move(_userPos!, _mapController.camera.zoom);
      }
    });
  }

  void _toggleFollow() {
    setState(() => _followMe = !_followMe);
    if (_followMe && _userPos != null) {
      _mapController.move(_userPos!, 15);
    } else if (_followMe) {
      _locateOnce();
    }
  }

  Future<void> _locateOnce() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() => _userPos = p);
      _mapController.move(p, 15);
    } catch (_) {}
  }

  Future<void> _tapStop(String stopName) async {
    setState(() {
      _tappedStop = stopName;
      _stopBuses = [];
      _loadingBuses = true;
    });
    final rawNum = (_lignes[_idx]['num'] as String).replaceAll('L', '');
    final routeNum = rawNum.length == 1 ? '0$rawNum' : rawNum;
    IrigoStop? found;
    int foundDir = 0;
    for (final dir in [0, 1]) {
      final list = IrigoService.getStops(routeNum, dir);
      final match = list.where((s) => s.name == stopName).firstOrNull;
      if (match != null) { found = match; foundDir = dir; break; }
    }
    if (found != null && found.id.isNotEmpty) {
      final buses = await IrigoService.getPassagesByStopAndRoute(
          found.id, '${routeNum}_$foundDir');
      if (mounted) setState(() { _stopBuses = buses; _loadingBuses = false; });
    } else {
      if (mounted) setState(() => _loadingBuses = false);
    }
  }

  double _bearing(LatLng a, LatLng b) =>
      atan2(b.longitude - a.longitude, b.latitude - a.latitude);

  // ── Itinéraire ─────────────────────────────────────────────────────────────

  LatLng? _stopCoordsByName(String name) {
    for (final l in _lignes) {
      for (final s in (l['stops'] as List)) {
        if (s['name'] == name) {
          return LatLng(s['lat'] as double, s['lng'] as double);
        }
      }
    }
    return null;
  }

  String? _nearestStopToUser() {
    if (_userPos == null) return null;
    double bestD2 = double.infinity;
    String? best;
    for (final l in _lignes) {
      for (final s in (l['stops'] as List)) {
        final dlat = _userPos!.latitude  - (s['lat'] as double);
        final dlng = _userPos!.longitude - (s['lng'] as double);
        final d2 = dlat * dlat + dlng * dlng;
        if (d2 < bestD2) { bestD2 = d2; best = s['name'] as String; }
      }
    }
    return best;
  }

  int _ligneIdxFor(String routeNum) {
    final n = int.tryParse(routeNum) ?? 0;
    return _lignes.indexWhere((l) {
      final x = (l['num'] as String).replaceAll('L', '');
      return int.tryParse(x) == n;
    });
  }

  void _openItinerary() {
    setState(() {
      _itineraryOpen = true;
      _tripFrom = _nearestStopToUser();
      _selectedTrip = null;
      _tripResults = [];
    });
  }

  void _closeItinerary() {
    setState(() {
      _itineraryOpen = false;
      _selectedTrip = null;
      _tripResults = [];
      _tripFrom = null;
      _tripTo = null;
    });
  }

  Future<void> _pickTripStop({required bool isFrom}) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0D1F1F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _StopPickerSheet(
        title: isFrom ? 'Arrêt de départ' : 'Arrêt d\'arrivée',
        exclude: isFrom ? _tripTo : _tripFrom,
      ),
    );
    if (name == null || !mounted) { return; }
    setState(() {
      if (isFrom) { _tripFrom = name; } else { _tripTo = name; }
    });
    if (_tripFrom != null && _tripTo != null) await _runTripSearch();
  }

  Future<void> _runTripSearch() async {
    if (_tripFrom == null || _tripTo == null) return;
    setState(() {
      _searchingTrip = true;
      _tripResults = [];
      _selectedTrip = null;
    });
    // Exécute planTrip hors du thread UI pour éviter le freeze
    final from = _tripFrom!;
    final to   = _tripTo!;
    final results = await Future.microtask(
        () => IrigoService.planTrip(from, to));
    if (!mounted) return;
    setState(() { _tripResults = results; _searchingTrip = false; });
    if (results.isNotEmpty) _onTripSelected(results.first);
  }

  void _onTripSelected(TripResult trip) {
    setState(() => _selectedTrip = trip);
    final idx = _ligneIdxFor(trip.lineNum);
    if (idx >= 0) setState(() => _idx = idx);
    final pts = trip.stops
        .map((s) => _stopCoordsByName(s.stopName))
        .whereType<LatLng>()
        .toList();
    if (pts.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pts),
          padding: const EdgeInsets.fromLTRB(40, 60, 40, 340),
        ));
      } catch (_) {}
    });
  }

  static const _lignes = [
    {
      'num': 'L1', 'color': Color(0xFF008E8C),
      'stops': [
        {'name': 'Quantinière',       'lat': 47.4588, 'lng': -0.4744, 't': true},
        {'name': 'Malraux',           'lat': 47.4575, 'lng': -0.4735, 't': true},
        {'name': 'Mauriac',           'lat': 47.4553, 'lng': -0.4716, 't': true},
        {'name': 'Trélazé Gare',      'lat': 47.4530, 'lng': -0.4680, 't': true},
        {'name': 'Trélazé Cimetière', 'lat': 47.4490, 'lng': -0.4665, 't': true},
        {'name': 'Trélazé Église',    'lat': 47.4482, 'lng': -0.4672, 't': true},
        {'name': 'Trélazé Mairie',    'lat': 47.4478, 'lng': -0.4680, 't': true},
        {'name': 'Monthibert',        'lat': 47.4455, 'lng': -0.4745, 't': true},
        {'name': 'Arena Loire',       'lat': 47.4435, 'lng': -0.4787, 't': true},
        {'name': 'Buisson',           'lat': 47.4420, 'lng': -0.4840, 't': true},
        {'name': 'Morlong',           'lat': 47.4405, 'lng': -0.4920, 't': false},
        {'name': 'Bourse',            'lat': 47.4440, 'lng': -0.5020, 't': false},
        {'name': 'Ménard',            'lat': 47.4450, 'lng': -0.4970, 't': false},
        {'name': 'Chouteau',          'lat': 47.4460, 'lng': -0.4950, 't': false},
        {'name': 'Fresnaies',         'lat': 47.4480, 'lng': -0.4920, 't': false},
        {'name': 'Marais',            'lat': 47.4500, 'lng': -0.5044, 't': false},
        {'name': 'Bellevue',          'lat': 47.4490, 'lng': -0.5010, 't': false},
        {'name': 'Léo Lagrange',      'lat': 47.4478, 'lng': -0.5099, 't': false},
        {'name': 'Allumettes',        'lat': 47.4535, 'lng': -0.5220, 't': false},
        {'name': 'Lefèvre',           'lat': 47.4550, 'lng': -0.5260, 't': false},
        {'name': 'Jean Vilar',        'lat': 47.4685, 'lng': -0.5449, 't': false},
        {'name': 'Ralliement',        'lat': 47.4730, 'lng': -0.5530, 't': false},
        {'name': 'Lorraine',          'lat': 47.4695, 'lng': -0.5697, 't': false},
      ],
    },
    {
      'num': 'L8', 'color': Color(0xFFE50076),
      'stops': [
        {'name': 'Ste-Gemmes',     'lat': 47.4375, 'lng': -0.5543, 't': false},
        {'name': 'Madeleine',      'lat': 47.4598, 'lng': -0.5474, 't': false},
        {'name': 'Marais',         'lat': 47.4500, 'lng': -0.5044, 't': false},
        {'name': 'Léo Lagrange',   'lat': 47.4478, 'lng': -0.5099, 't': false},
        {'name': 'Allumettes',     'lat': 47.4535, 'lng': -0.5220, 't': false},
        {'name': 'Floriloire',     'lat': 47.4400, 'lng': -0.5558, 't': false},
      ],
    },
    {
      'num': 'L10', 'color': Color(0xFF7263A9),
      'stops': [
        {'name': 'St-Lézin',       'lat': 47.4310, 'lng': -0.4590, 't': false},
        {'name': 'Trélazé Gare',   'lat': 47.4530, 'lng': -0.4680, 't': true},
        {'name': 'Buisson',        'lat': 47.4420, 'lng': -0.4840, 't': true},
        {'name': 'Morlong',        'lat': 47.4405, 'lng': -0.4920, 't': true},
        {'name': 'Léo Lagrange',   'lat': 47.4478, 'lng': -0.5099, 't': false},
        {'name': 'Allumettes',     'lat': 47.4535, 'lng': -0.5220, 't': false},
        {'name': 'Provins',        'lat': 47.4640, 'lng': -0.5244, 't': false},
      ],
    },
    {
      'num': 'L112', 'color': Color(0xFF484F54),
      'stops': [
        {'name': 'Quantinière',    'lat': 47.4588, 'lng': -0.4744, 't': true},
        {'name': 'Malraux',        'lat': 47.4575, 'lng': -0.4735, 't': true},
        {'name': 'Mauriac',        'lat': 47.4553, 'lng': -0.4716, 't': true},
        {'name': '08-mai',         'lat': 47.4560, 'lng': -0.4700, 't': true},
      ],
    },
    {
      'num': 'L163', 'color': Color(0xFF2E7D32),
      'stops': [
        {'name': 'Buisson',        'lat': 47.4420, 'lng': -0.4840, 't': true},
        {'name': 'Morlong',        'lat': 47.4405, 'lng': -0.4920, 't': true},
        {'name': 'Bourse',         'lat': 47.4440, 'lng': -0.5020, 't': false},
        {'name': 'Ménard',         'lat': 47.4450, 'lng': -0.4970, 't': false},
        {'name': 'Chouteau',       'lat': 47.4460, 'lng': -0.4950, 't': false},
        {'name': 'Fresnaies',      'lat': 47.4480, 'lng': -0.4920, 't': false},
        {'name': 'Marais',         'lat': 47.4500, 'lng': -0.5044, 't': false},
        {'name': 'Bellevue',       'lat': 47.4490, 'lng': -0.5010, 't': false},
        {'name': 'Léo Lagrange',   'lat': 47.4478, 'lng': -0.5099, 't': true},
      ],
    },
    {
      'num': 'L172', 'color': Color(0xFF1565C0),
      'stops': [
        {'name': 'Quantinière',    'lat': 47.4588, 'lng': -0.4744, 't': true},
        {'name': 'Malraux',        'lat': 47.4575, 'lng': -0.4735, 't': false},
        {'name': 'Mauriac',        'lat': 47.4553, 'lng': -0.4716, 't': false},
        {'name': '08-mai',         'lat': 47.4560, 'lng': -0.4700, 't': false},
        {'name': 'Trélazé Mairie', 'lat': 47.4478, 'lng': -0.4680, 't': true},
        {'name': 'Monthibert',     'lat': 47.4455, 'lng': -0.4745, 't': false},
        {'name': 'Buisson',        'lat': 47.4420, 'lng': -0.4840, 't': true},
        {'name': 'Morlong',        'lat': 47.4405, 'lng': -0.4920, 't': false},
        {'name': 'Marais',         'lat': 47.4500, 'lng': -0.5044, 't': false},
        {'name': 'Léo Lagrange',   'lat': 47.4478, 'lng': -0.5099, 't': true},
      ],
    },
  ];

  void _selectLigne(int idx) {
    setState(() { _idx = idx; _tappedStop = null; });
    final stops = (_lignes[idx]['stops'] as List);
    if (stops.isEmpty) return;
    final points = stops
        .map((s) => LatLng(s['lat'] as double, s['lng'] as double))
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
          ),
        );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final ligne = _lignes[_idx];
    final color = ligne['color'] as Color;
    final stops = ligne['stops'] as List;
    final points = stops
        .map((s) => LatLng(s['lat'] as double, s['lng'] as double))
        .toList();

    return Stack(children: [

      // ── Carte ──────────────────────────────────────────────────────────────
      FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(47.4500, -0.4900),
          initialZoom: 12.5,
        ),
        children: [
          TileLayer(
            urlTemplate: _satellite
                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'fr.my_trelaze.my_trelaze',
          ),
          // Tracé ligne
          PolylineLayer(polylines: [
            Polyline(points: points, color: color,
                strokeWidth: 4.5, strokeCap: StrokeCap.round),
          ]),
          // Flèches de direction sur le trajet
          if (points.length >= 2)
            MarkerLayer(
              markers: List.generate(points.length - 1, (i) {
                final mid = LatLng(
                  (points[i].latitude  + points[i + 1].latitude)  / 2,
                  (points[i].longitude + points[i + 1].longitude) / 2,
                );
                return Marker(
                  point: mid, width: 20, height: 20,
                  child: Transform.rotate(
                    angle: _bearing(points[i], points[i + 1]),
                    child: Icon(Icons.arrow_upward,
                        color: color.withValues(alpha: 0.75), size: 14),
                  ),
                );
              }),
            ),
          // Arrêts
          MarkerLayer(
            markers: stops.asMap().entries.map((e) {
              final s         = e.value;
              final isTrel    = s['t'] as bool;
              final stopName  = s['name'] as String;
              final isFirst   = e.key == 0;
              final isLast    = e.key == stops.length - 1;
              final isTerminus = isFirst || isLast;
              final isSelected = stopName == _tappedStop;
              return Marker(
                point: LatLng(s['lat'] as double, s['lng'] as double),
                width: 130, height: isTerminus ? 54 : 44,
                child: GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      setState(() { _tappedStop = null; _stopBuses = []; });
                    } else {
                      _tapStop(stopName);
                    }
                  },
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white
                            : (isTrel ? AppTheme.primary : color),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(
                              alpha: isSelected ? 0.35 : 0.2),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2))],
                        border: (isSelected || isTerminus) ? Border.all(
                            color: isSelected ? color : Colors.white,
                            width: 1.5) : null,
                      ),
                      child: Text(stopName,
                        style: TextStyle(
                          color: isSelected ? color : Colors.white,
                          fontSize: isTerminus ? 10 : 9,
                          fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      width: isTerminus ? 10 : 7,
                      height: isTerminus ? 10 : 7,
                      decoration: BoxDecoration(
                        color: isTrel ? AppTheme.primary : color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white,
                            width: isTerminus ? 2 : 1.5),
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
          // ── Surbrillance itinéraire sélectionné ──────────────────────────
          if (_selectedTrip != null) ...[
            PolylineLayer(polylines: [
              Polyline(
                points: _selectedTrip!.stops
                    .map((s) => _stopCoordsByName(s.stopName))
                    .whereType<LatLng>().toList(),
                color: _selectedTrip!.lineColor,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
              ),
            ]),
            MarkerLayer(markers: [
              if (_stopCoordsByName(_selectedTrip!.stops.first.stopName) != null)
                Marker(
                  point: _stopCoordsByName(_selectedTrip!.stops.first.stopName)!,
                  width: 36, height: 44,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.circle, color: Colors.white, size: 10)),
                    Container(width: 3, height: 10, color: Colors.green.shade600),
                  ]),
                ),
              if (_stopCoordsByName(_selectedTrip!.stops.last.stopName) != null)
                Marker(
                  point: _stopCoordsByName(_selectedTrip!.stops.last.stopName)!,
                  width: 36, height: 44,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 13)),
                    Container(width: 3, height: 10, color: Colors.red.shade600),
                  ]),
                ),
            ]),
          ],
          // Point GPS utilisateur (dot bleu pulsé)
          if (_userPos != null)
            MarkerLayer(markers: [
              Marker(
                point: _userPos!, width: 32, height: 32,
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context2, child2) => Stack(alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 1 + _pulseCtrl.value * 1.8,
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(
                                alpha: (1 - _pulseCtrl.value) * 0.35),
                            shape: BoxShape.circle),
                        ),
                      ),
                      Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.5),
                            blurRadius: 8)],
                        ),
                      ),
                    ]),
                ),
              ),
            ]),
        ],
      ),

      // ── Sélecteur de ligne (scroll horizontal) ──────────────────────────────
      Positioned(top: 12, left: 0, right: 0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(_lignes.length, (i) {
              final l = _lignes[i];
              final c = l['color'] as Color;
              final sel = i == _idx;
              return GestureDetector(
                onTap: () => _selectLigne(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? c : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c, width: sel ? 0 : 2),
                    boxShadow: [BoxShadow(
                      color: sel ? c.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.12),
                      blurRadius: sel ? 8 : 4,
                      offset: const Offset(0, 2))],
                  ),
                  child: Text(l['num'] as String,
                    style: TextStyle(
                      color: sel ? Colors.white : c,
                      fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              );
            }),
          ),
        ),
      ),

      // ── Boussole Nord ───────────────────────────────────────────────────────
      Positioned(top: 66, right: 16,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
          ),
          child: const Center(
            child: Text('N',
              style: TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 13, color: Colors.red)),
          ),
        ),
      ),

      // ── Zoom +/− ────────────────────────────────────────────────────────────
      Positioned(top: 112, right: 16,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              onTap: () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 1),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10)),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.add, size: 20,
                    color: Color(0xFF0A2729)),
              ),
            ),
            Container(height: 1,
                color: Colors.grey.shade300),
            InkWell(
              onTap: () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 1),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10)),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.remove, size: 20,
                    color: Color(0xFF0A2729)),
              ),
            ),
          ]),
        ),
      ),

      // ── Panneau infos arrêt (prochains bus) ─────────────────────────────────
      if (_tappedStop != null)
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A2729),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.directions_bus,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tappedStop!,
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 16, color: Colors.white)),
                      Text('Ligne ${ligne['num']}',
                        style: TextStyle(fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.45))),
                    ],
                  )),
                  GestureDetector(
                    onTap: () => setState(() {
                      _tappedStop = null; _stopBuses = [];
                    }),
                    child: Icon(Icons.close,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 20),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              if (_loadingBuses)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white54)),
                )
              else if (_stopBuses.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(children: [
                    Icon(Icons.schedule, size: 14,
                        color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 8),
                    Text('Aucun passage dans les 2h',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13)),
                  ]),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Wrap(spacing: 8, runSpacing: 8,
                    children: _stopBuses.take(6).map((b) {
                      final isRT = !(b['theorique'] as bool? ?? true);
                      final tc = isRT ? Colors.greenAccent : color;
                      final mins = b['minutesRestantes'] as int? ?? -1;
                      final label = mins == 0
                          ? "À l'arrêt"
                          : mins > 0 ? '$mins min' : '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: tc.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: tc.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, children: [
                          if (isRT)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 6, height: 6,
                                decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              const Text('Direct',
                                style: TextStyle(fontSize: 9,
                                    color: Colors.greenAccent)),
                            ]),
                          Text(b['heure'] as String? ?? '--:--',
                            style: TextStyle(color: tc,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                          if (label.isNotEmpty)
                            Text(label,
                              style: TextStyle(
                                  color: tc.withValues(alpha: 0.7),
                                  fontSize: 10)),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
            ]),
          ),
        ),

      // ── Boutons actions (droite bas) ─────────────────────────────────────────
      Positioned(bottom: 16, right: 16,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Itinéraire
          _MapFab(
            heroTag: 'map_itin',
            icon: _itineraryOpen ? Icons.close : Icons.alt_route,
            active: _itineraryOpen,
            activeColor: Colors.deepOrange,
            onTap: _itineraryOpen ? _closeItinerary : _openItinerary,
          ),
          const SizedBox(height: 8),
          // Satellite
          _MapFab(
            heroTag: 'map_sat',
            icon: _satellite ? Icons.map : Icons.satellite_alt,
            active: _satellite,
            activeColor: color,
            onTap: () => setState(() => _satellite = !_satellite),
          ),
          const SizedBox(height: 8),
          // Suivre ma position
          _MapFab(
            heroTag: 'map_follow',
            icon: _followMe
                ? Icons.navigation
                : Icons.navigation_outlined,
            active: _followMe,
            activeColor: Colors.blue,
            onTap: _toggleFollow,
          ),
          const SizedBox(height: 8),
          // Centrer sur ma position
          _MapFab(
            heroTag: 'map_locate',
            icon: Icons.my_location,
            active: false,
            activeColor: color,
            onTap: _locateOnce,
          ),
        ]),
      ),

      // ── Panneau itinéraire ──────────────────────────────────────────────────
      if (_itineraryOpen)
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _ItineraryPanel(
            fromName: _tripFrom,
            toName: _tripTo,
            results: _tripResults,
            searching: _searchingTrip,
            selected: _selectedTrip,
            onFromTap: () => _pickTripStop(isFrom: true),
            onToTap:   () => _pickTripStop(isFrom: false),
            onSwap: () {
              setState(() {
                final tmp = _tripFrom;
                _tripFrom = _tripTo;
                _tripTo = tmp;
              });
              if (_tripFrom != null && _tripTo != null) _runTripSearch();
            },
            onSelect: _onTripSelected,
            onClose: _closeItinerary,
          ),
        ),

      // ── Légende ─────────────────────────────────────────────────────────────
      if (_tappedStop == null && !_itineraryOpen)
        Positioned(bottom: 16, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2729).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendDot(color: AppTheme.primary, label: 'Arrêt Trélazé'),
                const SizedBox(height: 4),
                _LegendDot(color: color, label: 'Arrêt réseau'),
                const SizedBox(height: 4),
                _LegendDot(color: Colors.blue, label: 'Ma position'),
              ],
            ),
          ),
        ),
    ]);
  }
}

// ── Bouton flottant carte ──────────────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;
  const _MapFab({
    required this.heroTag, required this.icon,
    required this.active, required this.activeColor, required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: onTap,
      backgroundColor: active ? activeColor : const Color(0xFF0A2729),
      elevation: 4,
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

// ── Panneau itinéraire ─────────────────────────────────────────────────────────

class _ItineraryPanel extends StatelessWidget {
  final String? fromName;
  final String? toName;
  final List<TripResult> results;
  final bool searching;
  final TripResult? selected;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onSwap;
  final ValueChanged<TripResult> onSelect;
  final VoidCallback onClose;

  const _ItineraryPanel({
    required this.fromName, required this.toName,
    required this.results, required this.searching,
    required this.selected,
    required this.onFromTap, required this.onToTap,
    required this.onSwap, required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55),
      decoration: const BoxDecoration(
        color: Color(0xFF0A2729),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 20)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 14),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2)),
        ),

        // ── Champs départ/arrivée ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            // Ligne verticale + icônes
            Column(children: [
              const Icon(Icons.circle_outlined,
                  color: Colors.greenAccent, size: 14),
              Container(width: 2, height: 18,
                  color: Colors.white24),
              const Icon(Icons.location_on,
                  color: Colors.redAccent, size: 14),
            ]),
            const SizedBox(width: 10),
            // Champs
            Expanded(child: Column(children: [
              _ItinField(
                hint: 'Départ (arrêt le plus proche)',
                value: fromName,
                onTap: onFromTap,
              ),
              const SizedBox(height: 6),
              _ItinField(
                hint: 'Arrivée — choisir un arrêt',
                value: toName,
                onTap: onToTap,
              ),
            ])),
            const SizedBox(width: 8),
            // Swap
            GestureDetector(
              onTap: onSwap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3535),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A4545)),
                ),
                child: const Icon(Icons.swap_vert,
                    color: Colors.white70, size: 20),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Résultats ──────────────────────────────────────────────────────
        if (searching)
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white54),
          )
        else if (fromName != null && toName != null && results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text('Aucun trajet direct trouvé',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13)),
          )
        else if (results.isNotEmpty)
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: results.length,
              itemBuilder: (_, i) {
                final r = results[i];
                final isSelected = selected?.departureTime == r.departureTime
                    && selected?.lineNum == r.lineNum;
                final wait = r.waitMinutes;
                final waitLabel = wait == 0
                    ? "À l'arrêt"
                    : wait == 1 ? 'Dans 1 min' : 'Dans $wait min';

                return GestureDetector(
                  onTap: () => onSelect(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? r.lineColor.withValues(alpha: 0.18)
                          : const Color(0xFF122020),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? r.lineColor
                            : const Color(0xFF1E3A3A),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      // Badge ligne
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: r.lineColor,
                          borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(r.lineNum,
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14))),
                      ),
                      const SizedBox(width: 12),
                      // Infos
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Horaires
                          Row(children: [
                            Text(r.departureTime,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20, height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  size: 14)),
                            Text(r.arrivalTime,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20, height: 1)),
                          ]),
                          const SizedBox(height: 6),
                          // Chips
                          Wrap(spacing: 6, runSpacing: 4, children: [
                            _IChip(Icons.timer_outlined,
                                '${r.durationMin} min',
                                r.lineColor),
                            _IChip(Icons.place_outlined,
                                '${r.stops.length} arrêts',
                                Colors.white38),
                            _IChip(Icons.schedule, waitLabel,
                                wait <= 3 ? Colors.orange : Colors.greenAccent),
                          ]),
                          const SizedBox(height: 4),
                          Text('→ ${r.terminus}',
                            style: TextStyle(fontSize: 11,
                                color: r.lineColor,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        ],
                      )),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: r.lineColor, size: 20),
                    ]),
                  ),
                );
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 16),
            child: Row(children: [
              const Icon(Icons.touch_app,
                  size: 14, color: Colors.white24),
              const SizedBox(width: 8),
              Text('Choisissez départ et arrivée',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12)),
            ]),
          ),
      ]),
    );
  }
}

class _ItinField extends StatelessWidget {
  final String hint;
  final String? value;
  final VoidCallback onTap;
  const _ItinField(
      {required this.hint, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF122020),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A4545)),
        ),
        child: Row(children: [
          Expanded(
            child: Text(value ?? hint,
              style: TextStyle(
                color: value != null ? Colors.white : Colors.white38,
                fontSize: 13,
                fontWeight: value != null
                    ? FontWeight.w600 : FontWeight.normal),
              overflow: TextOverflow.ellipsis),
          ),
          Icon(Icons.chevron_right,
              size: 16,
              color: Colors.white.withValues(alpha: 0.2)),
        ]),
      ),
    );
  }
}

class _IChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _IChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, color: color,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Légende ────────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1)),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]);
  }
}
