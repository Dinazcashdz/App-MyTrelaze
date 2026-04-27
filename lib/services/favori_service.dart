import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriStop {
  final String lineNum;
  final int dir;
  final String stopId;
  final String stopName;
  final int lineColor; // Color.value pour JSON

  const FavoriStop({
    required this.lineNum,
    required this.dir,
    required this.stopId,
    required this.stopName,
    required this.lineColor,
  });

  Map<String, dynamic> toJson() => {
    'lineNum': lineNum, 'dir': dir, 'stopId': stopId,
    'stopName': stopName, 'lineColor': lineColor,
  };

  factory FavoriStop.fromJson(Map<String, dynamic> j) => FavoriStop(
    lineNum: j['lineNum'] as String,
    dir: j['dir'] as int,
    stopId: j['stopId'] as String,
    stopName: j['stopName'] as String,
    lineColor: j['lineColor'] as int,
  );

  String get key => '${lineNum}_${dir}_$stopId';

  @override
  bool operator ==(Object other) => other is FavoriStop && other.key == key;
  @override
  int get hashCode => key.hashCode;
}

class FavoriService {
  static const _prefsKey = 'bus_favoris';

  static Future<List<FavoriStop>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => FavoriStop.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<bool> isFavori(String key) async {
    final all = await getAll();
    return all.any((f) => f.key == key);
  }

  static Future<void> toggle(FavoriStop stop) async {
    final all = await getAll();
    final exists = all.any((f) => f.key == stop.key);
    if (exists) {
      all.removeWhere((f) => f.key == stop.key);
    } else {
      all.add(stop);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(all.map((f) => f.toJson()).toList()));
  }

  static Future<void> remove(String key) async {
    final all = await getAll();
    all.removeWhere((f) => f.key == key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(all.map((f) => f.toJson()).toList()));
  }
}
