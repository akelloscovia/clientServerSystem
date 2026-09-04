/// A walk-in visitor sign-in record (mirrors the server `VisitorLog`).
class Visitor {
  final int id;
  final String name;
  final String? company;
  final String? visitDate; // YYYY-MM-DD
  final String? timeIn; // HH:MM
  final String reasonForVisit;
  final String? description;
  final String status; // pending | assigned | attended | closed
  final int? assignedTo;
  final String? assignee;
  final String? createdAt;
  final List<VisitorReply> replies;

  const Visitor({
    required this.id,
    required this.name,
    this.company,
    this.visitDate,
    this.timeIn,
    required this.reasonForVisit,
    this.description,
    required this.status,
    this.assignedTo,
    this.assignee,
    this.createdAt,
    this.replies = const [],
  });

  factory Visitor.fromJson(Map<String, dynamic> json) => Visitor(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        company: json['company'] as String?,
        visitDate: json['visit_date'] as String?,
        timeIn: json['time_in'] as String?,
        reasonForVisit: json['reason_for_visit'] as String? ?? '',
        description: json['description'] as String?,
        status: json['status'] as String? ?? 'pending',
        assignedTo: json['assigned_to'] as int?,
        assignee: json['assignee'] as String?,
        createdAt: json['created_at'] as String?,
        replies: (json['replies'] as List<dynamic>? ?? [])
            .map((e) => VisitorReply.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static const statuses = ['pending', 'assigned', 'attended', 'closed'];
}

class VisitorReply {
  final int id;
  final String? responder;
  final String message;
  final String? createdAt;

  const VisitorReply({
    required this.id,
    this.responder,
    required this.message,
    this.createdAt,
  });

  factory VisitorReply.fromJson(Map<String, dynamic> json) => VisitorReply(
        id: json['id'] as int,
        responder: json['responder'] as String?,
        message: json['message'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );
}
