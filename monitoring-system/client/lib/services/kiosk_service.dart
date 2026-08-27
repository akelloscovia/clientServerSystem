import '../models/program.dart';
import '../models/channel.dart';
import 'api_service.dart';

/// Public, no-login API calls used by the reception kiosk screens.
class KioskService {
  static final KioskService _instance = KioskService._internal();
  factory KioskService() => _instance;
  KioskService._internal();

  final ApiService _api = ApiService();

  Future<List<Program>> getPrograms({String? day}) async {
    final query = <String, String>{if (day != null) 'day': day};
    final path = Uri(path: '/programs/', queryParameters: query).toString();
    final resp = await _api.get(path);
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return (data['programs'] as List<dynamic>)
        .map((e) => Program.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Channel>> getChannels() async {
    final resp = await _api.get('/channels/');
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    return (data['channels'] as List<dynamic>)
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
