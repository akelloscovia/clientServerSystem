/// Submission data model.
class Submission {
  final int id;
  final int userId;
  final String? submitter;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  const Submission({
    required this.id,
    required this.userId,
    this.submitter,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) => Submission(
    id:          json['id'] as int,
    userId:      json['user_id'] as int,
    submitter:   json['submitter'] as String?,
    title:       json['title'] as String,
    description: json['description'] as String,
    category:    json['category'] as String,
    priority:    json['priority'] as String,
    status:      json['status'] as String,
    createdAt:   json['created_at'] as String?,
    updatedAt:   json['updated_at'] as String?,
  );
}
