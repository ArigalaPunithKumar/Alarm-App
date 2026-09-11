import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class CreateAlarmScreen extends StatefulWidget {
  final Alarm? existingAlarm;
  const CreateAlarmScreen({super.key, this.existingAlarm});

  @override
  State<CreateAlarmScreen> createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends State<CreateAlarmScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _reasonController = TextEditingController();
  String _selectedTone = 'Default';

  final List<String> _tones = [
    'Default',
    'Digital',
    'Bells',
    'Rooster',
    'Marimba',
  ];

  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    if (widget.existingAlarm != null) {
      _selectedDate = widget.existingAlarm!.scheduledDateTime;
      _selectedTime = TimeOfDay(
        hour: widget.existingAlarm!.scheduledDateTime.hour,
        minute: widget.existingAlarm!.scheduledDateTime.minute,
      );
      _reasonController.text = widget.existingAlarm!.reason;
      _selectedTone = _tones.contains(widget.existingAlarm!.tone)
          ? widget.existingAlarm!.tone
          : 'Default';
    }
  }

  Future<void> _pickDate() async {
    final DateTime today = DateTime.now();
    final DateTime maxDate =
        DateTime(today.year + 1, today.month, today.day);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _saveAlarm() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for the alarm')),
      );
      return;
    }

    final DateTime scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot schedule an alarm in the past')),
      );
      return;
    }

    final String timeString = _selectedTime.format(context);
    final String dateString =
        DateFormat('dd MMM yyyy').format(_selectedDate);

    final alarm = Alarm(
      id: widget.existingAlarm?.id ?? const Uuid().v4(),
      date: dateString,
      time: timeString,
      reason: _reasonController.text.trim(),
      scheduledDateTime: scheduledDateTime,
      tone: _selectedTone,
    );

    await _storageService.saveAlarm(alarm);
    await _notificationService.scheduleAlarm(alarm);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingAlarm != null 
              ? 'Alarm updated for $timeString'
              : 'Alarm set for $timeString on $dateString'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('New Alarm', style: TextStyle(fontSize: 16)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time picker card
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3))
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedTime.format(context),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to change time',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date picker button
            ElevatedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text(
                DateFormat('dd MMM yyyy').format(_selectedDate),
                style: const TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Tone selector
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: Colors.white,
                  value: _selectedTone,
                  isExpanded: true,
                  icon: const Icon(Icons.music_note,
                      color: Colors.deepPurple, size: 18),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTone = newValue;
                      });
                    }
                  },
                  items: _tones
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('🔔 $value'),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reason text field
            TextField(
              controller: _reasonController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Pay electricity bill',
                labelText: 'Reason',
                labelStyle: const TextStyle(fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.edit_note,
                    color: Colors.deepPurple, size: 20),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 28),

            // Save button
            ElevatedButton(
              onPressed: _saveAlarm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              child: const Text(
                'Save Alarm',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
