class Alarm {
  final String id;
  final String date;
  final String time;
  final String timezone;
  final String reason;
  bool enabled;
  final DateTime scheduledDateTime;
  final String tone;

  Alarm({
    required this.id,
    required this.date,
    required this.time,
    this.timezone = 'Asia/Kolkata',
    required this.reason,
    this.enabled = true,
    required this.scheduledDateTime,
    this.tone = 'Default',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'time': time,
        'timezone': timezone,
        'reason': reason,
        'enabled': enabled,
        'scheduledDateTime': scheduledDateTime.toIso8601String(),
        'tone': tone,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'],
        date: json['date'],
        time: json['time'],
        timezone: json['timezone'] ?? 'Asia/Kolkata',
        reason: json['reason'],
        enabled: json['enabled'],
        scheduledDateTime: DateTime.parse(json['scheduledDateTime']),
        tone: json['tone'] ?? 'Default',
      );

  Alarm copyWith({
    String? id,
    String? date,
    String? time,
    String? timezone,
    String? reason,
    bool? enabled,
    DateTime? scheduledDateTime,
    String? tone,
  }) {
    return Alarm(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      timezone: timezone ?? this.timezone,
      reason: reason ?? this.reason,
      enabled: enabled ?? this.enabled,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      tone: tone ?? this.tone,
    );
  }
}
