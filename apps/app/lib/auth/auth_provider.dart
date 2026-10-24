import 'package:edtech_app/models/user.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null && _token != null;
  String? get error => _error;

  final ApiService _api = ApiService();

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
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _user = null;
    _token = null;
    _error = null;
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
