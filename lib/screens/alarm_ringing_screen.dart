import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  final String payload;
  const AlarmRingingScreen({super.key, required this.payload});

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> with SingleTickerProviderStateMixin {
  Alarm? _alarm;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _loadAlarm();
  }

  Future<void> _loadAlarm() async {
    final storage = StorageService();
    final alarms = await storage.getAlarms();
    try {
      final alarm = alarms.firstWhere((a) => a.id == widget.payload);
      setState(() {
        _alarm = alarm;
      });
    } catch (e) {
      // Alarm not found in storage by payload, might be a test or deleted
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _stopAlarm() async {
    final ns = NotificationService();
    // Cancel the ringing notification (stops the sound)
    await ns.cancelAlarm(widget.payload);
    
    // Toggle off in storage if it's a one-time alarm
    if (_alarm != null) {
      final storage = StorageService();
      await storage.toggleAlarm(_alarm!.id, false);
    }
    
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _snoozeAlarm() async {
    final ns = NotificationService();
    await ns.cancelAlarm(widget.payload);
    
    if (_alarm != null) {
      // Schedule 10 mins from now
      final snoozedDate = DateTime.now().add(const Duration(minutes: 10));
      final snoozedAlarm = Alarm(
        id: _alarm!.id, // Keep same ID so it overwrites
        time: DateFormat('hh:mm a').format(snoozedDate),
        date: DateFormat('dd MMM yyyy').format(snoozedDate),
        reason: 'Snoozed: ${_alarm!.reason}',
        scheduledDateTime: snoozedDate,
        tone: _alarm!.tone,
      );
      await ns.scheduleAlarm(snoozedAlarm);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm snoozed for 10 minutes')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A148C), Color(0xFF1A237E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text(
                    'ALARM',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _alarm != null ? _alarm!.time : DateFormat('hh:mm a').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _alarm != null ? _alarm!.reason : 'Wake up!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              
              // Animated Bell
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animController.value * 0.2 - 0.1,
                    child: const Icon(
                      Icons.alarm_on,
                      size: 120,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _stopAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 8,
                        ),
                        child: const Text(
                          'STOP ALARM',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _snoozeAlarm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SNOOZE (10 MIN)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
