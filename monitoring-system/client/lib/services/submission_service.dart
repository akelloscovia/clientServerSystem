import '../models/submission.dart';
import '../models/response.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Service for all submission-related API calls.
class SubmissionService {
  static final SubmissionService _instance = SubmissionService._internal();
  factory SubmissionService() => _instance;
  SubmissionService._internal();

  final ApiService _api = ApiService();

  /// Create a new submission.
  Future<Submission> createSubmission({
    required String title,
    required String description,
    required String category,
    required String priority,
  }) async {
    final resp = await _api.post('/submissions', {
      'title':       title.trim(),
      'description': description.trim(),
      'category':    category,
      'priority':    priority,
    });
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return Submission.fromJson(data['submission'] as Map<String, dynamic>);
  }

  /// List user's own submissions.
  Future<List<Submission>> getMySubmissions({
    int page = 1,
    String? status,
  }) async {
    var path = '/submissions?page=$page&per_page=20';
    if (status != null && status.isNotEmpty) path += '&status=$status';
    final resp = await _api.get(path);
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    final items = data['submissions'] as List<dynamic>;
    return items.map((e) => Submission.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get a single submission with responses.
  Future<Submission> getSubmission(int id) async {
    final resp = await _api.get('/submissions/$id');
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return Submission.fromJson(data['submission'] as Map<String, dynamic>);
  }

  /// Get all responses for a submission.
  Future<List<SubmissionResponse>> getResponses(int submissionId) async {
    final resp = await _api.get('/responses/$submissionId');
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    final items = data['responses'] as List<dynamic>;
    return items
        .map((e) => SubmissionResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get notifications for the logged-in user.
  Future<Map<String, dynamic>> getNotifications() async {
    final resp = await _api.get('/monitoring/notifications');
    ApiService.checkError(resp);
    return ApiService.decodeJson(resp);
  }

  /// Mark a notification as read.
  Future<void> markNotificationRead(int id) async {
    await _api.patch('/monitoring/notifications/$id/read', {});
  }
}
