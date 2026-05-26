import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  AuthProvider(this.apiClient) {
    _tryAutoLogin();
  }

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('driver_token') || !prefs.containsKey('driver_user')) {
      return;
    }
    _token = prefs.getString('driver_token');
    _user = jsonDecode(prefs.getString('driver_user')!);
    
    if (_token != null) {
      apiClient.setToken(_token!);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(AppConstants.login, body: {
        'email': email,
        'password': password,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _token = data['token'];
        _user = data['user'];
        
        apiClient.setToken(_token!);

        // Persist token and user profile
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('driver_token', _token!);
        await prefs.setString('driver_user', jsonEncode(_user));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Login gagal. Silakan coba lagi.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    apiClient.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('driver_token');
    await prefs.remove('driver_user');

    notifyListeners();
  }
}
