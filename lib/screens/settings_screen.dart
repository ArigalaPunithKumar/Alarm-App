import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  int _preAlarmMins = 0;
  static const platform = MethodChannel('com.example.new_app/battery');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final preMins = await _storageService.getPreAlarmMins();
    setState(() {
      _preAlarmMins = preMins;
    });
  }

  Future<void> _requestBatteryOptimization() async {
    try {
      final bool? result = await platform.invokeMethod('requestIgnoreBatteryOptimizations');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == true ? 'Requested Background Permission' : 'Permission already granted/failed'),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: '${e.message}'.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Settings', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
        child: ListView(
          padding: const EdgeInsets.only(top: 100, bottom: 40),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('ALARM BEHAVIOR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: const Icon(Icons.notifications_active_outlined, color: Colors.deepPurple),
                title: const Text('Notify before ringing', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_preAlarmMins == 0 ? 'Off' : '$_preAlarmMins minutes before', style: TextStyle(color: Colors.grey.shade600)),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    dropdownColor: Colors.white,
                    value: _preAlarmMins,
                    style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 14),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Off')),
                      DropdownMenuItem(value: 5, child: Text('5 mins')),
                      DropdownMenuItem(value: 10, child: Text('10 mins')),
                      DropdownMenuItem(value: 15, child: Text('15 mins')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _preAlarmMins = val);
                        _storageService.setPreAlarmMins(val);
                      }
                    },
                  ),
                ),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 8),
              child: Text('SYSTEM & BACKGROUND', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: const Icon(Icons.battery_charging_full_outlined, color: Colors.deepPurple),
                title: const Text('Background Execution', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Prevent OS from killing alarms', style: TextStyle(color: Colors.grey.shade600)),
                trailing: const Icon(Icons.chevron_right, color: Colors.deepPurple),
                onTap: _requestBatteryOptimization,
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 8),
              child: Text('ABOUT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    leading: Icon(Icons.info_outline, color: Colors.deepPurple),
                    title: Text('Version', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('1.0.0', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                  ),
                  Divider(height: 1, indent: 60, color: Colors.grey.shade200),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    leading: const Icon(Icons.privacy_tip_outlined, color: Colors.deepPurple),
                    title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.deepPurple),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Privacy Policy', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                          content: const Text('All alarms and data are stored locally on your device. We do not collect or share any personal information.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context), 
                              child: const Text('Close', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold))
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
