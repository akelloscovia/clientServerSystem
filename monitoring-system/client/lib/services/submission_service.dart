import '../models/submission.dart';
import '../models/response.dart';
import '../models/user.dart';
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
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'priority': priority,
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
    final query = <String, String>{
      'page': '$page',
      'per_page': '20',
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final path = Uri(path: '/submissions/', queryParameters: query).toString();
    final resp = await _api.get(path);
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    final items = data['submissions'] as List<dynamic>;
    return items
        .map((e) => Submission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Submission>> getStaffSubmissions({
    int page = 1,
    String? status,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'per_page': '100',
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final path = Uri(path: '/submissions/', queryParameters: query).toString();
    final resp = await _api.get(path);
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return (data['submissions'] as List<dynamic>)
        .map((item) => Submission.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(int id, String status) async {
    final resp =
        await _api.patch('/submissions/$id/status', {'status': status});
    ApiService.checkError(resp);
  }

  Future<void> assignSubmission(int id, int secretaryId,
      {String notes = ''}) async {
    final resp = await _api.post('/submissions/assign', {
      'submission_id': id,
      'assigned_to': secretaryId,
      'notes': notes,
    });
    ApiService.checkError(resp);
  }

  Future<void> addResponse(int submissionId, String message) async {
    final resp = await _api.post('/responses/', {
      'submission_id': submissionId,
      'message': message,
    });
    ApiService.checkError(resp);
  }

  Future<Map<String, dynamic>> getStats() async {
    final resp = await _api.get('/monitoring/stats');
    ApiService.checkError(resp);
    return ApiService.decodeJson(resp);
  }

  Future<List<User>> getUsers() async {
    final resp = await _api.get('/users/');
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return (data['users'] as List<dynamic>)
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<User>> getSecretaries() async {
    final resp = await _api.get('/users/secretaries');
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return (data['secretaries'] as List<dynamic>)
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<User> updateUserRole(int userId, String role) async {
    final resp = await _api.patch('/users/$userId/role', {'role': role});
    ApiService.checkError(resp);
    return User.fromJson(
        ApiService.decodeJson(resp)['user'] as Map<String, dynamic>);
  }

  Future<User> toggleUserActive(int userId) async {
    final resp = await _api.patch('/users/$userId/toggle-active', {});
    ApiService.checkError(resp);
    return User.fromJson(
        ApiService.decodeJson(resp)['user'] as Map<String, dynamic>);
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
