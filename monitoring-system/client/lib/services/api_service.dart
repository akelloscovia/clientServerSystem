import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Base HTTP service — attaches the JWT, transparently refreshes it once on a
/// 401 and retries, then decodes responses.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Map<String, String>> _headers() async {
    final token = (await _prefs).getString(AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('${AppConstants.baseUrl}$path');

  Future<http.Response> get(String path) => _send('GET', path);
  Future<http.Response> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body);
  Future<http.Response> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body);
  Future<http.Response> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body);
  Future<http.Response> delete(String path) => _send('DELETE', path);

  Future<http.Response> _send(String method, String path,
      [Map<String, dynamic>? body]) async {
    var resp = await _raw(method, path, body);
    if (resp.statusCode == 401 && await _refresh()) {
      resp = await _raw(method, path, body);
    }
    return resp;
  }

  Future<http.Response> _raw(
      String method, String path, Map<String, dynamic>? body) async {
    final uri = _uri(path);
    final headers = await _headers();
    final payload = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: payload);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: payload);
      case 'PUT':
        return http.put(uri, headers: headers, body: payload);
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported method $method');
    }
  }

  bool _refreshing = false;

  /// Exchange the stored refresh token for a fresh access token. Returns
  /// false (and leaves the session as-is) if there's no refresh token or the
  /// server rejects it.
  Future<bool> _refresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final prefs = await _prefs;
      final refreshToken = prefs.getString(AppConstants.refreshKey);
      if (refreshToken == null) return false;
      final resp = await http.post(
        _uri('/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );
      if (resp.statusCode != 200) return false;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token == null) return false;
      await prefs.setString(AppConstants.tokenKey, token);
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  /// Decode JSON response body.
  static Map<String, dynamic> decodeJson(http.Response resp) {
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Throw a readable error if status code is not 2xx.
  static void checkError(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final msg = body['error'] ??
        body['message'] ??
        'Request failed (${resp.statusCode})';
    throw Exception(msg.toString());
  }
}
