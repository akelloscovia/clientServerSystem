class Advertisement {
  final int id;
  final String title;
  final String description;
  final String imageData;
  final String linkUrl;

  const Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageData,
    required this.linkUrl,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageData: json['image_data'] as String? ?? '',
      linkUrl: json['link_url'] as String? ?? '',
    );
  }
}
