class SncfDeparture {
  final String trainNumber;
  final String direction;
  final DateTime scheduledTime;
  final DateTime? realTime;
  final bool isCancelled;

  const SncfDeparture({
    required this.trainNumber,
    required this.direction,
    required this.scheduledTime,
    this.realTime,
    this.isCancelled = false,
  });

  int get delayMinutes {
    if (realTime == null) return 0;
    return realTime!.difference(scheduledTime).inMinutes;
  }

  bool get isOnTime => !isCancelled && delayMinutes <= 0;
  bool get isDelayed => !isCancelled && delayMinutes > 0;
  DateTime get displayTime => realTime ?? scheduledTime;

  bool get isPast =>
      displayTime.isBefore(DateTime.now().subtract(const Duration(minutes: 1)));
}

class SncfService {
  // Horaires TER typiques Trélazé (ligne Angers ↔ Le Mans)
  static const _angersMinutes = [
    368, 408, 441, 472, 508, 545, 582, 618, 665, 708, 745, 792, 832, 868,
    905, 948, 985, 1032, 1072, 1108, 1145, 1182, 1218, 1265, 1328,
  ];
  static const _leMansMinutes = [
    382, 425, 462, 498, 545, 582, 625, 672, 708, 752, 788, 832, 868, 912,
    948, 992, 1028, 1072, 1112, 1148, 1192, 1228, 1272, 1325,
  ];

  static List<SncfDeparture> _buildSchedule() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final departures = <SncfDeparture>[];

    for (int i = 0; i < _angersMinutes.length; i++) {
      final dt = base.add(Duration(minutes: _angersMinutes[i]));
      departures.add(SncfDeparture(
        trainNumber: 'TER 174${(i + 1).toString().padLeft(2, '0')}',
        direction: 'Angers Saint-Laud',
        scheduledTime: dt,
        // Simulate occasional 3-5 min delay on some trains
        realTime: (i % 7 == 3) ? dt.add(const Duration(minutes: 4)) : null,
      ));
    }
    for (int i = 0; i < _leMansMinutes.length; i++) {
      final dt = base.add(Duration(minutes: _leMansMinutes[i]));
      departures.add(SncfDeparture(
        trainNumber: 'TER 175${(i + 1).toString().padLeft(2, '0')}',
        direction: 'Le Mans',
        scheduledTime: dt,
        isCancelled: (i % 11 == 8), // Simulate occasional cancellation
      ));
    }

    departures.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return departures;
  }

  static List<SncfDeparture> getDepartures() => _buildSchedule();

  static SncfDeparture? getNextDeparture() {
    final now = DateTime.now();
    return _buildSchedule()
        .where((d) => !d.isCancelled && d.displayTime.isAfter(now))
        .firstOrNull;
  }

  // Durées de trajet indicatives depuis Trélazé
  static const List<(String, String, String)> journeyTimes = [
    ('Angers Saint-Laud', '~5 min', 'TER Pays de la Loire'),
    ('Le Mans', '~45 min', 'TER Pays de la Loire'),
    ('Paris Montparnasse', '~1h30', 'TGV via Angers'),
    ('Nantes', '~1h15', 'TER + correspondance'),
    ('Tours', '~1h05', 'TER + correspondance'),
  ];
}
