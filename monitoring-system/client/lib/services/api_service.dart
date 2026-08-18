import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Base HTTP service — attaches JWT, handles 401 refresh, decodes responses.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    final resp = await http.get(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
    );
    return resp;
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return resp;
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    final resp = await http.patch(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return resp;
  }

  Future<http.Response> delete(String path) async {
    final resp = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
    );
    return resp;
  }

  /// Decode JSON response body.
  static Map<String, dynamic> decodeJson(http.Response resp) {
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Throw a readable error if status code is not 2xx.
  static void checkError(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final msg = body['error'] ?? body['message'] ?? 'Request failed (${resp.statusCode})';
    throw Exception(msg.toString());
  }
}
