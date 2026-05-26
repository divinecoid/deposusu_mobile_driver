import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final ApiClient apiClient;
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> _pendingOrders = [];
  List<OrderModel> _deliveringOrders = [];
  List<OrderModel> _completedOrders = [];
  OrderModel? _currentOrderDetail;

  OrderProvider(this.apiClient);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<OrderModel> get pendingOrders => _pendingOrders;
  List<OrderModel> get deliveringOrders => _deliveringOrders;
  List<OrderModel> get completedOrders => _completedOrders;
  OrderModel? get currentOrderDetail => _currentOrderDetail;

  Future<void> fetchPendingOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('${AppConstants.orders}?status=pending');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final list = data['data']['data'] as List;
        _pendingOrders = list.map((o) => OrderModel.fromJson(o)).toList();
      } else {
        _errorMessage = data['message'] ?? 'Gagal memuat tugas baru.';
      }
    } catch (e) {
      _errorMessage = 'Kesalahan jaringan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDeliveringOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('${AppConstants.orders}?status=delivering');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final list = data['data']['data'] as List;
        _deliveringOrders = list.map((o) => OrderModel.fromJson(o)).toList();
      } else {
        _errorMessage = data['message'] ?? 'Gagal memuat pengiriman aktif.';
      }
    } catch (e) {
      _errorMessage = 'Kesalahan jaringan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCompletedOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('${AppConstants.orders}?status=completed');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final list = data['data']['data'] as List;
        _completedOrders = list.map((o) => OrderModel.fromJson(o)).toList();
      } else {
        _errorMessage = data['message'] ?? 'Gagal memuat histori tugas.';
      }
    } catch (e) {
      _errorMessage = 'Kesalahan jaringan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOrderDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _currentOrderDetail = null;
    notifyListeners();

    try {
      final response = await apiClient.get(AppConstants.showOrder(id));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _currentOrderDetail = OrderModel.fromJson(data['data']);
      } else {
        _errorMessage = data['message'] ?? 'Gagal memuat detail pesanan.';
      }
    } catch (e) {
      _errorMessage = 'Kesalahan jaringan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> pickupOrder(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(AppConstants.pickupOrder(id));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _isLoading = false;
        await fetchPendingOrders();
        await fetchDeliveringOrders();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Gagal mengambil tugas.';
      }
    } catch (e) {
      _errorMessage = 'Gagal mengambil tugas: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> finishOrder(int id, File photo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final streamedResponse = await apiClient.postMultipart(
        endpoint: AppConstants.finishOrder(id),
        fields: {},
        file: photo,
        fileField: 'photo',
      );

      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _isLoading = false;
        await fetchDeliveringOrders();
        await fetchCompletedOrders();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Gagal menyelesaikan pengiriman.';
      }
    } catch (e) {
      _errorMessage = 'Gagal menyelesaikan pengiriman: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
