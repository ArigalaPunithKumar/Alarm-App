import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm.dart';

class StorageService {
  static const String _alarmsKey = 'alarms';

  Future<List<Alarm>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList(_alarmsKey) ?? [];
    return alarmsJson
        .map((jsonStr) => Alarm.fromJson(jsonDecode(jsonStr)))
        .toList();
  }

  Future<void> saveAlarm(Alarm alarm) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((a) => a.id == alarm.id);
    if (index >= 0) {
      alarms[index] = alarm;
    } else {
      alarms.add(alarm);
    }
    await _saveAll(alarms);
  }

  Future<void> deleteAlarm(String id) async {
    final alarms = await getAlarms();
    alarms.removeWhere((a) => a.id == id);
    await _saveAll(alarms);
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((a) => a.id == id);
    if (index >= 0) {
      alarms[index].enabled = enabled;
      await _saveAll(alarms);
    }
  }

  Future<void> _saveAll(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_alarmsKey, alarmsJson);
  }

  // Settings
  Future<int> getPreAlarmMins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('preAlarmMins') ?? 0;
  }

  Future<void> setPreAlarmMins(int mins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preAlarmMins', mins);
  }

  Future<bool> getGestureStop() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('gestureStop') ?? false;
  }

  Future<void> setGestureStop(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gestureStop', enabled);
  }
}
