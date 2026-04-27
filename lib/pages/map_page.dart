import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n.dart';

// ─── Modèle POI ───────────────────────────────────────────────────────────────

class _Poi {
  final String name;
  final String category;
  final double lat;
  final double lng;
  final IconData icon;
  final Color color;
  final String? phone;
  const _Poi({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.icon,
    required this.color,
    this.phone,
  });
}

const _pois = [
  _Poi(name: 'Mairie',            category: 'Services',       lat: 47.4480, lng: -0.4680, icon: Icons.location_city,  color: AppTheme.primary,          phone: '0241338000'),
  _Poi(name: 'Médiathèque',       category: 'Culture',        lat: 47.4472, lng: -0.4695, icon: Icons.library_books,  color: Color(0xFF7263A9)),
  _Poi(name: 'Salle omnisports',  category: 'Sport',          lat: 47.4465, lng: -0.4710, icon: Icons.sports_soccer,  color: Color(0xFFE8A020)),
  _Poi(name: 'Piscine municipale',category: 'Sport',          lat: 47.4458, lng: -0.4720, icon: Icons.pool,           color: Color(0xFF00AEEF)),
  _Poi(name: 'Arena Loire',       category: 'Culture',        lat: 47.4435, lng: -0.4787, icon: Icons.stadium,        color: Color(0xFF5b3db5)),
  _Poi(name: 'École Jules Ferry', category: 'Éducation',      lat: 47.4490, lng: -0.4660, icon: Icons.school,         color: Color(0xFF388E3C)),
  _Poi(name: 'Parc de la Mairie', category: 'Espaces verts',  lat: 47.4478, lng: -0.4670, icon: Icons.park,           color: Color(0xFF388E3C)),
  _Poi(name: 'Parc des Ardoisières', category: 'Espaces verts', lat: 47.4510, lng: -0.4630, icon: Icons.park,         color: Color(0xFF388E3C)),
  _Poi(name: 'Trélazé Gare (L1)',  category: 'Bus',           lat: 47.4530, lng: -0.4680, icon: Icons.directions_bus, color: Color(0xFF008E8C)),
  _Poi(name: 'Arena Loire (L1)',   category: 'Bus',           lat: 47.4435, lng: -0.4787, icon: Icons.directions_bus, color: Color(0xFF008E8C)),
  _Poi(name: 'Mairie (L1)',        category: 'Bus',           lat: 47.4485, lng: -0.4685, icon: Icons.directions_bus, color: Color(0xFF008E8C)),
  _Poi(name: 'SD Kebab',          category: 'Restaurant',     lat: 47.4505, lng: -0.4715, icon: Icons.kebab_dining,   color: Color(0xFF388E3C)),
  _Poi(name: "McDonald's",        category: 'Restaurant',     lat: 47.4540, lng: -0.4640, icon: Icons.fastfood,       color: Color(0xFFFFC107)),
  _Poi(name: 'Pizza Tempo',       category: 'Restaurant',     lat: 47.4495, lng: -0.4700, icon: Icons.local_pizza,    color: Color(0xFFE8401C)),
  _Poi(name: 'MG Tacos',          category: 'Restaurant',     lat: 47.4520, lng: -0.4660, icon: Icons.fastfood,       color: Color(0xFFE8A020)),
];

const _categories = [
  'Tous', 'Services', 'Bus', 'Restaurant',
  'Sport', 'Culture', 'Éducation', 'Espaces verts',
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  String _filtreCategorie = 'Tous';
  bool _satellite = false;
  final MapController _mapCtrl = MapController();
  LatLng? _userPos;
  StreamSubscription<Position>? _posSub;
  late AnimationController _pulseCtrl;

  List<_Poi> get _poisFiltres => _filtreCategorie == 'Tous'
      ? _pois
      : _pois.where((p) => p.category == _filtreCategorie).toList();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTracking());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) { return; }
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      if (mounted) setState(() => _userPos = LatLng(pos.latitude, pos.longitude));
    });
  }

  Future<void> _centerOnUser() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) { return; }
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() => _userPos = p);
      _mapCtrl.move(p, 16);
    } catch (_) {}
  }

  // ── Actions Maps externes ──────────────────────────────────────────────────

  Future<void> _openMaps(_Poi poi) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${poi.lat},${poi.lng}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openStreetView(_Poi poi) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${poi.lat},${poi.lng}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openItinerary(_Poi poi) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${poi.lat},${poi.lng}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppL10n.of(context).pageMap)),
      body: Stack(children: [

        // ── Carte ────────────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapCtrl,
          options: const MapOptions(
            initialCenter: LatLng(47.4488, -0.4680),
            initialZoom: 14.5,
            minZoom: 12.0,
            maxZoom: 19.0,
          ),
          children: [
            TileLayer(
              urlTemplate: _satellite
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'fr.my_trelaze.my_trelaze',
            ),
            // POI markers
            MarkerLayer(
              markers: _poisFiltres.map((poi) => Marker(
                point: LatLng(poi.lat, poi.lng),
                width: 140, height: 60,
                child: GestureDetector(
                  onTap: () => _showPoiDetail(poi),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: poi.color,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(
                          color: poi.color.withValues(alpha: 0.4),
                          blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(poi.icon, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Flexible(child: Text(poi.name,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                    Container(width: 2, height: 8, color: poi.color),
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: poi.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5)),
                    ),
                  ]),
                ),
              )).toList(),
            ),
            // Dot GPS utilisateur
            if (_userPos != null)
              MarkerLayer(markers: [
                Marker(
                  point: _userPos!, width: 32, height: 32,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (ctx, child) => Stack(
                      alignment: Alignment.center,
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
                      ],
                    ),
                  ),
                ),
              ]),
          ],
        ),

        // ── Filtres catégories ────────────────────────────────────────────────
        Positioned(top: 12, left: 12, right: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final sel = cat == _filtreCategorie;
                return GestureDetector(
                  onTap: () => setState(() => _filtreCategorie = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Text(cat,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppTheme.textMain)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Boussole ─────────────────────────────────────────────────────────
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
              child: Text('N', style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
            ),
          ),
        ),

        // ── Zoom +/− ──────────────────────────────────────────────────────────
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
                onTap: () => _mapCtrl.move(
                    _mapCtrl.camera.center, _mapCtrl.camera.zoom + 1),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10)),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.add, size: 20, color: Color(0xFF0A2729)),
                ),
              ),
              Container(height: 1, color: Colors.grey.shade300),
              InkWell(
                onTap: () => _mapCtrl.move(
                    _mapCtrl.camera.center, _mapCtrl.camera.zoom - 1),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10)),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.remove, size: 20, color: Color(0xFF0A2729)),
                ),
              ),
            ]),
          ),
        ),

        // ── Compteur lieux ────────────────────────────────────────────────────
        Positioned(bottom: 16, left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
            ),
            child: Text(
              '${_poisFiltres.length} lieu${_poisFiltres.length > 1 ? 'x' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),

        // ── Boutons actions ───────────────────────────────────────────────────
        Positioned(bottom: 16, right: 16,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Satellite
            _Fab(
              heroTag: 'map_sat',
              icon: _satellite ? Icons.map : Icons.satellite_alt,
              active: _satellite,
              onTap: () => setState(() => _satellite = !_satellite),
            ),
            const SizedBox(height: 8),
            // Ma position
            _Fab(
              heroTag: 'map_loc',
              icon: Icons.my_location,
              active: false,
              onTap: _centerOnUser,
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Fiche détail POI ───────────────────────────────────────────────────────

  void _showPoiDetail(_Poi poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 12,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
          // En-tête
          Row(children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: poi.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14)),
              child: Icon(poi.icon, color: poi.color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(poi.name, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: poi.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(poi.category, style: TextStyle(
                    fontSize: 11, color: poi.color,
                    fontWeight: FontWeight.w600)),
              ),
            ])),
          ]),
          const SizedBox(height: 20),

          // Actions
          _ActionRow(children: [
            // Street View
            _ActionBtn(
              icon: Icons.streetview,
              label: 'Street View',
              color: Colors.blue.shade700,
              onTap: () { Navigator.pop(sheetCtx); _openStreetView(poi); },
            ),
            // Itinéraire
            _ActionBtn(
              icon: Icons.directions,
              label: 'Itinéraire',
              color: Colors.green.shade700,
              onTap: () { Navigator.pop(sheetCtx); _openItinerary(poi); },
            ),
            // Ouvrir dans Maps
            _ActionBtn(
              icon: Icons.open_in_new,
              label: 'Google Maps',
              color: Colors.orange.shade700,
              onTap: () { Navigator.pop(sheetCtx); _openMaps(poi); },
            ),
          ]),

          // Téléphone si dispo
          if (poi.phone != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:${poi.phone}')),
                icon: const Icon(Icons.call),
                label: Text(_formatTel(poi.phone!)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: poi.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  static String _formatTel(String tel) {
    if (tel.length == 10) {
      return List.generate(5, (i) => tel.substring(i * 2, i * 2 + 2))
          .join(' ');
    }
    return tel;
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _Fab extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _Fab({required this.heroTag, required this.icon,
      required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: onTap,
      backgroundColor: active ? AppTheme.primary : const Color(0xFF0A2729),
      elevation: 4,
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final List<Widget> children;
  const _ActionRow({required this.children});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: children.map((c) => Expanded(child: c)).toList(),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 11, color: color,
              fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
