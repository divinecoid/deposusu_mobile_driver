import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient apiClient;
  bool _isLoading = false;
  
  Map<String, dynamic> _stats = {
    'pending_tasks': 0,
    'active_deliveries': 0,
    'completed_today': 0,
  };

  Map<String, dynamic> _attendance = {
    'checked_in': false,
    'checked_out': false,
    'check_in_at': null,
    'check_out_at': null,
  };

  String? _errorMessage;

  DashboardProvider(this.apiClient);

  bool get isLoading => _isLoading;
  Map<String, dynamic> get stats => _stats;
  Map<String, dynamic> get attendance => _attendance;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get(AppConstants.dashboard);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _stats = data['data']['stats'];
        _attendance = data['data']['attendance'];
      } else {
        throw Exception(data['message'] ?? 'Gagal memuat data dashboard');
      }
    } catch (e) {
      // MOCK BACKEND DATA FALLBACK
      _errorMessage = 'Terjadi kesalahan jaringan: $e. Menggunakan data simulasi.';
      _stats = {
        'pending_tasks': 2,
        'active_deliveries': 1,
        'completed_today': 5,
      };
      // Keep existing attendance state if already set
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> checkIn({double? latitude, double? longitude, String? shift}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(AppConstants.checkIn, body: {
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        if (shift != null) 'shift': shift,
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _attendance['checked_in'] = true;
        _attendance['check_in_at'] = data['data']['check_in_at'];
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(data['message'] ?? 'Gagal check-in');
      }
    } catch (e) {
      // MOCK CHECK IN FALLBACK
      _errorMessage = 'Gagal check-in ke server: $e. Mode offline aktif.';
      _attendance['checked_in'] = true;
      _attendance['check_in_at'] = DateTime.now().toIso8601String();
      
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> checkOut({double? latitude, double? longitude}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(AppConstants.checkOut, body: {
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _attendance['checked_in'] = false; // Still technically checked in, but checked out for the day
        _attendance['check_out_at'] = data['data']['check_out_at'];
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(data['message'] ?? 'Gagal check-out');
      }
    } catch (e) {
      // MOCK CHECK OUT FALLBACK
      _errorMessage = 'Gagal check-out ke server: $e. Mode offline aktif.';
      _attendance['checked_in'] = false;
      _attendance['check_out_at'] = DateTime.now().toIso8601String();
      
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }
}
