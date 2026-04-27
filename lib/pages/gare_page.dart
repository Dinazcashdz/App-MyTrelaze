import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sncf_service.dart';
import '../theme.dart';

class GarePage extends StatefulWidget {
  const GarePage({super.key});
  @override
  State<GarePage> createState() => _GarePageState();
}

class _GarePageState extends State<GarePage> {
  List<SncfDeparture> _departures = [];
  String _filter = 'tous';
  DateTime _now = DateTime.now();
  Timer? _refreshTimer;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _departures = SncfService.getDepartures();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _departures = SncfService.getDepartures());
    });
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  List<SncfDeparture> get _filtered {
    final upcoming = _departures.where((d) => !d.isPast).toList();
    if (_filter == 'angers') {
      return upcoming.where((d) => d.direction.toLowerCase().contains('angers')).toList();
    }
    if (_filter == 'le mans') {
      return upcoming.where((d) => d.direction.toLowerCase().contains('mans')).toList();
    }
    return upcoming;
  }

  SncfDeparture? get _nextTrain =>
      _filtered.where((d) => !d.isCancelled && d.displayTime.isAfter(_now)).firstOrNull;

  String _countdown(DateTime target) {
    final diff = target.difference(_now);
    if (diff.inSeconds < 0) return 'En gare';
    if (diff.inSeconds < 60) return 'Imminent';
    if (diff.inHours >= 1) {
      return '${diff.inHours}h${(diff.inMinutes % 60).toString().padLeft(2, '0')}';
    }
    return '${diff.inMinutes} min';
  }

  String _hm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final next = _nextTrain;
    final list = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F1F),
      appBar: AppBar(
        title: const Text('Gare de Trélazé'),
        backgroundColor: const Color(0xFF0A2729),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => setState(() => _departures = SncfService.getDepartures()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _departures = SncfService.getDepartures()),
        color: AppTheme.greenLight,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(next)),
            SliverToBoxAdapter(child: _buildFilters()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'PROCHAINS DÉPARTS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            if (list.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _DepartureCard(
                    dep: list[i],
                    hm: _hm,
                    countdown: _countdown,
                    isNext: i == 0 && !list[i].isCancelled,
                  ),
                  childCount: list.length,
                ),
              ),
            SliverToBoxAdapter(child: _buildJourneyTimes()),
            SliverToBoxAdapter(child: _buildInfo()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(SncfDeparture? next) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A2729), Color(0xFF1A4040)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.train, color: AppTheme.greenLight, size: 18),
            const SizedBox(width: 8),
            Text(
              'SNCF · TER Pays de la Loire',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
            ),
            const Spacer(),
            _LiveBadge(),
          ]),
          const SizedBox(height: 22),
          if (next != null) ...[
            Text(
              'PROCHAIN DÉPART',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Text(
                _countdown(next.displayTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '→ ${next.direction}',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    next.trainNumber,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Départ prévu : ${_hm(next.scheduledTime)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ]),
              ),
            ]),
            if (next.isDelayed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Retard de ${next.delayMinutes} min · Nouvel horaire : ${_hm(next.realTime!)}',
                    style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ],
          ] else ...[
            Text(
              'Aucun prochain départ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final items = [
      ('tous', 'Tous', Icons.swap_horiz),
      ('angers', '→ Angers', Icons.arrow_back),
      ('le mans', '→ Le Mans', Icons.arrow_forward),
    ];
    return Container(
      color: const Color(0xFF0F2828),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) {
            final sel = _filter == item.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : const Color(0xFF1A3030),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppTheme.primary : const Color(0xFF2A4040),
                    ),
                  ),
                  child: Row(children: [
                    Icon(item.$3, color: sel ? Colors.white : Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: sel ? Colors.white : Colors.white54,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.train_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text(
          'Aucun départ disponible\npour cette direction',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
        ),
      ]),
    );
  }

  Widget _buildJourneyTimes() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF122020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A3A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.schedule, color: AppTheme.greenLight, size: 18),
          const SizedBox(width: 8),
          const Text('Temps de trajet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        const SizedBox(height: 14),
        ...SncfService.journeyTimes.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            const Icon(Icons.train, color: AppTheme.greenLight, size: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.$1, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(t.$3, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(t.$2, style: const TextStyle(color: AppTheme.greenLight, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _buildInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A3030)),
      ),
      child: Column(children: [
        _InfoRow(icon: Icons.location_on_outlined, text: 'Route de la Gare, 49800 Trélazé'),
        const SizedBox(height: 6),
        _InfoRow(icon: Icons.access_time_outlined, text: 'Guichet : Lun–Ven 6h30–20h · Sam 8h–19h · Dim 9h–20h'),
        const SizedBox(height: 6),
        _InfoRow(icon: Icons.info_outline, text: 'Horaires indicatifs — données réelles disponibles avec clé API SNCF'),
      ]),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, c) => Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.4 + _ctrl.value * 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text('Temps réel', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _DepartureCard extends StatelessWidget {
  final SncfDeparture dep;
  final String Function(DateTime) hm;
  final String Function(DateTime) countdown;
  final bool isNext;

  const _DepartureCard({required this.dep, required this.hm, required this.countdown, required this.isNext});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    if (dep.isCancelled) {
      statusColor = Colors.red;
      statusText = 'Supprimé';
    } else if (dep.isDelayed) {
      statusColor = Colors.orange;
      statusText = '+${dep.delayMinutes} min';
    } else {
      statusColor = Colors.greenAccent;
      statusText = 'À l\'heure';
    }

    final isAngers = dep.direction.contains('Angers');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFF1A3535) : const Color(0xFF122020),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNext ? AppTheme.primary.withValues(alpha: 0.7) : const Color(0xFF1E3A3A),
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Heure
          SizedBox(
            width: 68,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                dep.isCancelled ? '--:--' : hm(dep.scheduledTime),
                style: TextStyle(
                  color: dep.isCancelled ? Colors.red.shade300 : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  decoration: dep.isDelayed ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.orange.shade300,
                  decorationThickness: 2,
                ),
              ),
              if (dep.isDelayed)
                Text(hm(dep.realTime!),
                    style: const TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(
                dep.isCancelled ? '🚫' : countdown(dep.displayTime),
                style: TextStyle(
                  color: isNext ? AppTheme.greenLight : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          // Direction icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isAngers
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAngers ? Icons.arrow_back : Icons.arrow_forward,
              color: isAngers ? Colors.lightBlueAccent : Colors.purpleAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Direction + train
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                dep.direction,
                style: TextStyle(
                  color: dep.isCancelled ? Colors.white38 : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: dep.isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                dep.trainNumber,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
              ),
            ]),
          ),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 0.5),
            ),
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Colors.white38, size: 14),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
      ),
    ]);
  }
}
