import 'dart:convert';

import 'package:edtech_app/models/user.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isInitialized => _initialized;
  String? get error => _error;

  final ApiService _api = ApiService();

  /// Load persisted auth state from local storage. Call once before runApp.
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token != null && userJson != null) {
      try {
        _token = token;
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        // Corrupted persisted state: clear it.
        await clearPersisted();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_token == null || _user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
  }

  Future<void> clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.login(phone: phone, password: password);
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      _token = data['token'] as String;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String phone,
    required String email,
    required String displayName,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.register(
        phone: phone,
        email: email,
        displayName: displayName,
        password: password,
        role: role,
      );
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      _token = data['token'] as String;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendSmsCode({
    required String phone,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _api.sendSmsCode(phone: phone);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifySmsCode({
    required String phone,
    required String code,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.verifySmsCode(phone: phone, code: code);
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      _token = data['token'] as String;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> getMe({
    required String token,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _api.getMe(token: token);
      _user = User.fromJson(data['user'] as Map<String, dynamic>);
      _token = token;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _error = null;
    await clearPersisted();
    notifyListeners();
  }

  void clearError() {
    _error = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
