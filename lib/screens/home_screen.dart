import 'package:flutter/material.dart';
import '../models/alarm.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'create_alarm_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  List<Alarm> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await _storageService.getAlarms();
    alarms.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    setState(() {
      _alarms = alarms;
    });
  }

  Future<void> _toggleAlarm(Alarm alarm, bool enabled) async {
    await _storageService.toggleAlarm(alarm.id, enabled);
    if (enabled) {
      await _notificationService.scheduleAlarm(alarm);
    } else {
      await _notificationService.cancelAlarm(alarm.id);
    }
    _loadAlarms();
  }

  Future<void> _deleteAlarm(Alarm alarm) async {
    await _storageService.deleteAlarm(alarm.id);
    await _notificationService.cancelAlarm(alarm.id);
    _loadAlarms();
  }

  void _testAlarmSound() async {
    await _notificationService.testNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent! Check your notification panel.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Alarms',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 22),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white, size: 22),
            tooltip: 'Test Alarm Sound',
            onPressed: _testAlarmSound,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A148C), Color(0xFF7C4DFF)],
          ),
        ),
        child: _alarms.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm_off,
                        size: 56, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No alarms yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to create your first alarm',
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.only(top: 90, bottom: 80),
                itemCount: _alarms.length,
                itemBuilder: (context, index) {
                  final alarm = _alarms[index];
                  return Dismissible(
                    key: Key(alarm.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16.0),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete,
                          color: Colors.white, size: 22),
                    ),
                    onDismissed: (direction) => _deleteAlarm(alarm),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateAlarmScreen(existingAlarm: alarm),
                          ),
                        );
                        _loadAlarms();
                      },
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: alarm.enabled
                                  ? [Colors.white, const Color(0xFFEDE7F6)]
                                  : [Colors.grey.shade200, Colors.grey.shade300],
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              // Time circle
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: alarm.enabled
                                      ? Colors.deepPurple.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.alarm,
                                    size: 24,
                                    color: alarm.enabled
                                        ? Colors.deepPurple
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Alarm details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alarm.time,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: alarm.enabled
                                            ? Colors.deepPurple
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      alarm.date,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: alarm.enabled
                                            ? Colors.deepPurpleAccent
                                            : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      alarm.reason,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: alarm.enabled
                                            ? Colors.black87
                                            : Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (alarm.tone != 'Default')
                                      Row(
                                        children: [
                                          Icon(Icons.music_note,
                                              size: 11,
                                              color: Colors.grey.shade500),
                                          const SizedBox(width: 2),
                                          Text(
                                            alarm.tone,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              // Toggle switch
                              Transform.scale(
                                scale: 0.85,
                                child: Switch(
                                  value: alarm.enabled,
                                  activeColor: Colors.deepPurple,
                                  onChanged: (value) =>
                                      _toggleAlarm(alarm, value),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAlarmScreen(),
            ),
          );
          _loadAlarms();
        },
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
