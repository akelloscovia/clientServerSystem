import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Handles auth: login, register, logout, token persistence.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _api = ApiService();

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<User> login(String email, String password) async {
    final resp = await _api.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    await _saveSession(data);
    _currentUser = User.fromJson(data['user'] as Map<String, dynamic>);
    return _currentUser!;
  }

  Future<User> register(String name, String email, String password) async {
    final resp = await _api.post('/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
    ApiService.checkError(resp);
    final data = ApiService.decodeJson(resp);
    await _saveSession(data);
    _currentUser = User.fromJson(data['user'] as Map<String, dynamic>);
    return _currentUser!;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshKey);
    await prefs.remove(AppConstants.userKey);
    _currentUser = null;
  }

  Future<User?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    try {
      _currentUser = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey,  data['access_token']  as String);
    await prefs.setString(AppConstants.refreshKey, data['refresh_token'] as String);
    await prefs.setString(AppConstants.userKey,
      jsonEncode(data['user']));
  }
}
