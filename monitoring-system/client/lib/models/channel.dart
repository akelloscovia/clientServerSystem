/// A TV channel the reception kiosk can switch to.
class Channel {
  final int id;
  final String name;
  final String streamUrl;
  final String? logoUrl;
  final String streamType; // hls | youtube | mp4 | other
  final int sortOrder;
  final bool isActive;

  const Channel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logoUrl,
    required this.streamType,
    required this.sortOrder,
    required this.isActive,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
    id: json['id'] as int,
    name: json['name'] as String,
    streamUrl: json['stream_url'] as String,
    logoUrl: json['logo_url'] as String?,
    streamType: json['stream_type'] as String? ?? 'hls',
    sortOrder: json['sort_order'] as int? ?? 0,
    isActive: json['is_active'] as bool? ?? true,
  );

  bool get playsInWebView => streamType == 'youtube' || streamType == 'other';
}
