import '../models/program.dart';
import 'api_service.dart';

/// Staff CRUD for the ministry programme schedule (`/api/programs`).
/// Listing is public; create / edit / delete require an admin or secretary.
class ProgramService {
  static final ProgramService _instance = ProgramService._internal();
  factory ProgramService() => _instance;
  ProgramService._internal();

  final ApiService _api = ApiService();

  /// All programmes, including inactive ones (for the management view).
  Future<List<Program>> list({bool includeInactive = true}) async {
    final path = includeInactive ? '/programs/?all=1' : '/programs/';
    final resp = await _api.get(path);
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return (data['programs'] as List<dynamic>)
        .map((e) => Program.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Program> create(Map<String, dynamic> body) async {
    final resp = await _api.post('/programs/', body);
    ApiService.checkError(resp);
    return Program.fromJson(
        ApiService.decodeJson(resp)['program'] as Map<String, dynamic>);
  }

  Future<Program> update(int id, Map<String, dynamic> body) async {
    final resp = await _api.put('/programs/$id', body);
    ApiService.checkError(resp);
    return Program.fromJson(
        ApiService.decodeJson(resp)['program'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final resp = await _api.delete('/programs/$id');
    ApiService.checkError(resp);
  }
}
