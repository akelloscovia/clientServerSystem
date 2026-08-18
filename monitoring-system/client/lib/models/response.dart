/// Response data model — admin/secretary replies on a submission.
class SubmissionResponse {
  final int id;
  final int submissionId;
  final int responderId;
  final String? responder;
  final String? responderRole;
  final String message;
  final String? createdAt;

  const SubmissionResponse({
    required this.id,
    required this.submissionId,
    required this.responderId,
    this.responder,
    this.responderRole,
    required this.message,
    this.createdAt,
  });

  factory SubmissionResponse.fromJson(Map<String, dynamic> json) =>
      SubmissionResponse(
        id:            json['id'] as int,
        submissionId:  json['submission_id'] as int,
        responderId:   json['responder_id'] as int,
        responder:     json['responder'] as String?,
        responderRole: json['responder_role'] as String?,
        message:       json['message'] as String,
        createdAt:     json['created_at'] as String?,
      );
}
