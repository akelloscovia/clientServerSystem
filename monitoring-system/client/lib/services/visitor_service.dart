import '../models/visitor.dart';
import 'api_service.dart';

/// Visitor sign-in: a public create endpoint plus staff-only management.
class VisitorService {
  static final VisitorService _instance = VisitorService._internal();
  factory VisitorService() => _instance;
  VisitorService._internal();

  final ApiService _api = ApiService();

  /// Log a visitor. [visitDate] must be `YYYY-MM-DD`, [timeIn] must be `HH:MM`.
  Future<String> createVisitor({
    required String name,
    String company = '',
    required String visitDate,
    required String timeIn,
    required String reasonForVisit,
    String description = '',
  }) async {
    final resp = await _api.post('/visitors/', {
      'name': name.trim(),
      'company': company.trim(),
      'visit_date': visitDate,
      'time_in': timeIn,
      'reason_for_visit': reasonForVisit.trim(),
      'description': description.trim(),
    });
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return (data['message'] as String?) ?? 'Your visit has been logged.';
  }

  // ---- staff-only ----

  Future<List<Visitor>> list({String? status}) async {
    final query = <String, String>{
      'per_page': '100',
      if (status != null && status.isNotEmpty) 'status': status,
    };
    final path = Uri(path: '/visitors/', queryParameters: query).toString();
    final resp = await _api.get(path);
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return (data['visitors'] as List<dynamic>)
        .map((e) => Visitor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(int id, String status) async {
    final resp = await _api.patch('/visitors/$id/status', {'status': status});
    ApiService.checkError(resp);
  }

  Future<void> reply(int id, String message) async {
    final resp = await _api.post('/visitors/$id/replies', {'message': message});
    ApiService.checkError(resp);
  }

  Future<void> assign(int id, int staffId) async {
    final resp = await _api.post('/visitors/$id/assign', {'assigned_to': staffId});
    ApiService.checkError(resp);
  }

  Future<void> delete(int id) async {
    final resp = await _api.delete('/visitors/$id');
    ApiService.checkError(resp);
  }
}
