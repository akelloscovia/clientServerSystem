/// A single scheduled item in the ministry's daily program.
class Program {
  final int id;
  final String title;
  final String? description;
  final String day;
  final String startTime; // "HH:MM"
  final String endTime; // "HH:MM"
  final String? location;
  final bool isActive;

  const Program({
    required this.id,
    required this.title,
    this.description,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.isActive,
  });

  factory Program.fromJson(Map<String, dynamic> json) => Program(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String?,
    day: json['day'] as String? ?? 'daily',
    startTime: json['start_time'] as String? ?? '00:00',
    endTime: json['end_time'] as String? ?? '00:00',
    location: json['location'] as String?,
    isActive: json['is_active'] as bool? ?? true,
  );

  /// Minutes since midnight, for sorting/comparison against the clock.
  int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return h * 60 + m;
  }

  int get startMinutes => _minutes(startTime);
  int get endMinutes => _minutes(endTime);

  bool isHappeningNow(DateTime now) {
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }
}
