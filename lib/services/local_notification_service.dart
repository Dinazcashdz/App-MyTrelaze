import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _androidDechets = AndroidNotificationDetails(
  'dechets_channel', 'Rappels collecte',
  channelDescription: 'Rappels la veille de la collecte',
  importance: Importance.high,
  priority: Priority.high,
);

const _androidAgenda = AndroidNotificationDetails(
  'agenda_channel', 'Rappels agenda',
  channelDescription: 'Rappels 1h avant un rendez-vous',
  importance: Importance.high,
  priority: Priority.high,
);

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    _initialized = true;
  }

  // ─── Notifications déchets ───────────────────────────────────────────────
  // Planifie un rappel hebdomadaire la veille de chaque jour de collecte à 19h.
  static Future<void> planifierRappelsDechets({
    required int id,
    required String titre,
    required String corps,
    required List<int> joursEnSemaine,
  }) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    for (final jour in joursEnSemaine) {
      final veille = jour == 1 ? 7 : jour - 1;
      final scheduled = _prochainJour(now, veille, 19, 0);
      await _plugin.zonedSchedule(
        id + jour,
        titre,
        corps,
        scheduled,
        const NotificationDetails(android: _androidDechets, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static Future<void> annulerRappelsDechets(int id, List<int> jours) async {
    for (final j in jours) { await _plugin.cancel(id + j); }
  }

  // ─── Rappels agenda ──────────────────────────────────────────────────────
  static Future<void> planifierRappelRdv({
    required int id,
    required String titre,
    required String note,
    required DateTime rdvDateTime,
  }) async {
    await initialize();
    final rappelAt = rdvDateTime.subtract(const Duration(hours: 1));
    if (rappelAt.isBefore(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id,
      '⏰ Rappel : $titre',
      note.isNotEmpty ? note : 'Dans 1 heure',
      tz.TZDateTime.from(rappelAt, tz.local),
      const NotificationDetails(android: _androidAgenda, iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> annulerRappelRdv(int id) async => _plugin.cancel(id);

  // ─── Helper ──────────────────────────────────────────────────────────────
  static tz.TZDateTime _prochainJour(
      tz.TZDateTime depuis, int weekday, int heure, int minute) {
    var dt = tz.TZDateTime(tz.local, depuis.year, depuis.month, depuis.day, heure, minute);
    while (dt.weekday != weekday || dt.isBefore(depuis)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }
}
