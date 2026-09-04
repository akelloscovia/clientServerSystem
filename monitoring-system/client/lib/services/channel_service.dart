import '../models/channel.dart';
import 'api_service.dart';

/// Admin CRUD for reception TV channels (`/api/channels`).
class ChannelService {
  static final ChannelService _instance = ChannelService._internal();
  factory ChannelService() => _instance;
  ChannelService._internal();

  final ApiService _api = ApiService();

  Future<List<Channel>> list({bool includeInactive = true}) async {
    final path = includeInactive ? '/channels/?all=1' : '/channels/';
    final resp = await _api.get(path);
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    final channels = (data['channels'] as List<dynamic>)
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList();
    channels.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return channels;
  }

  Future<Channel> create(Map<String, dynamic> body) async {
    final resp = await _api.post('/channels/', body);
    ApiService.checkError(resp);
    return Channel.fromJson(
        ApiService.decodeJson(resp)['channel'] as Map<String, dynamic>);
  }

  Future<Channel> update(int id, Map<String, dynamic> body) async {
    final resp = await _api.put('/channels/$id', body);
    ApiService.checkError(resp);
    return Channel.fromJson(
        ApiService.decodeJson(resp)['channel'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final resp = await _api.delete('/channels/$id');
    ApiService.checkError(resp);
  }
}
