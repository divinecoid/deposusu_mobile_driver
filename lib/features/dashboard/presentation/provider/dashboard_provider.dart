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
        _errorMessage = data['message'] ?? 'Gagal memuat data dashboard.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan jaringan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> checkIn({double? latitude, double? longitude}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(AppConstants.checkIn, body: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _isLoading = false;
        await fetchDashboardData(); // Refresh stats/attendance
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Gagal melakukan check-in.';
      }
    } catch (e) {
      _errorMessage = 'Gagal check-in: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> checkOut({double? latitude, double? longitude}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(AppConstants.checkOut, body: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _isLoading = false;
        await fetchDashboardData(); // Refresh stats/attendance
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Gagal melakukan check-out.';
      }
    } catch (e) {
      _errorMessage = 'Gagal check-out: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
