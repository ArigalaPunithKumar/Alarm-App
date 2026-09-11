import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/notification_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/alarm_ringing_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

  String? launchPayload;
  try {
    final ns = NotificationService();
    await ns.init();
    final details = await ns.plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      launchPayload = details?.notificationResponse?.payload;
    }
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  runApp(AlarmApp(launchPayload: launchPayload));
}

class AlarmApp extends StatelessWidget {
  final String? launchPayload;
  const AlarmApp({super.key, this.launchPayload});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'My Alarms',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: launchPayload != null 
          ? AlarmRingingScreen(payload: launchPayload!) 
          : const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
