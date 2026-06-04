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
  bool _mockInitialized = false;

  List<OrderModel> _pendingOrders = [];
  List<OrderModel> _deliveringOrders = [];
  List<OrderModel> _completedOrders = [];
  OrderModel? _currentOrderDetail;
  
  // Track verified/scanned order IDs in the current active batch
  final List<int> _verifiedOrderIds = [];

  OrderProvider(this.apiClient);

  List<int> get verifiedOrderIds => List.unmodifiable(_verifiedOrderIds);

  void verifyOrder(int id) {
    if (!_verifiedOrderIds.contains(id)) {
      _verifiedOrderIds.add(id);
      notifyListeners();
    }
  }

  void clearVerifiedOrders() {
    _verifiedOrderIds.clear();
    notifyListeners();
  }

  void _initMockData() {
    // Mock data disabled to use actual data only
  }

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
        final List ordersJson = data['data']['data'] ?? [];
        _pendingOrders = ordersJson.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Gagal memuat pesanan');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _pendingOrders = [];
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
        final List ordersJson = data['data']['data'] ?? [];
        _deliveringOrders = ordersJson.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Gagal memuat pesanan');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _deliveringOrders = [];
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
        final List ordersJson = data['data']['data'] ?? [];
        _completedOrders = ordersJson.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Gagal memuat pesanan');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _completedOrders = [];
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
        throw Exception(data['message'] ?? 'Gagal memuat detail pesanan');
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> pickupOrder(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(AppConstants.pickupOrder(id), body: {
        'latitude': 0.0, // Should be actual GPS
        'longitude': 0.0,
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final updatedOrder = OrderModel.fromJson(data['data']);
        
        // Refresh local lists
        _pendingOrders.removeWhere((o) => o.id == id);
        _deliveringOrders.add(updatedOrder);
        _currentOrderDetail = updatedOrder;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil tugas');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectOrder(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post('${AppConstants.orders}/$id/reject', body: {});
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _pendingOrders.removeWhere((o) => o.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(data['message'] ?? 'Gagal menolak penawaran');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> finishOrder(int id, File photo, {String receivedBy = ''}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.postMultipart(
        endpoint: AppConstants.finishOrder(id),
        fields: {
          'recipient_name': receivedBy.isNotEmpty ? receivedBy : 'Penerima',
          'recipient_signature': 'base64_signature_here',
          'latitude': '0.0',
          'longitude': '0.0',
        },
        file: photo,
        fileField: 'photo',
      );

      final respBody = await response.stream.bytesToString();
      final data = jsonDecode(respBody);

      if (response.statusCode == 200 && data['success'] == true) {
        final updatedOrder = OrderModel.fromJson(data['data']);
        
        _deliveringOrders.removeWhere((o) => o.id == id);
        _completedOrders.insert(0, updatedOrder);
        _currentOrderDetail = updatedOrder;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(data['message'] ?? 'Gagal menyelesaikan pengiriman');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> failOrder(int id, {required String actionType, required String reason, String? rescheduleDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post('${AppConstants.orders}/$id/fail', body: {
        'action_type': actionType, // 'reschedule' or 'return'
        'reason': reason,
        'reschedule_date': rescheduleDate ?? '',
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final updatedOrder = OrderModel.fromJson(data['data']);
        
        _deliveringOrders.removeWhere((o) => o.id == id);
        if (actionType == 'reschedule') {
          _pendingOrders.add(updatedOrder);
        } else {
          _completedOrders.insert(0, updatedOrder);
        }
        _currentOrderDetail = updatedOrder;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(data['message'] ?? 'Gagal memproses kegagalan pengiriman');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void simulateQrisPayment(int id) {
    // Update in delivering orders
    final delIdx = _deliveringOrders.indexWhere((o) => o.id == id);
    if (delIdx != -1) {
      final order = _deliveringOrders[delIdx];
      _deliveringOrders[delIdx] = OrderModel(
        id: order.id,
        orderNumber: order.orderNumber,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        customerAddress: order.customerAddress,
        totalAmount: order.totalAmount,
        status: order.status,
        paymentStatus: 'PAID_QRIS',
        pickedUpAt: order.pickedUpAt,
        items: order.items,
        distance: order.distance,
        deadline: order.deadline,
        assignedBy: order.assignedBy,
      );
    }

    // Update in pending orders if any
    final pendIdx = _pendingOrders.indexWhere((o) => o.id == id);
    if (pendIdx != -1) {
      final order = _pendingOrders[pendIdx];
      _pendingOrders[pendIdx] = OrderModel(
        id: order.id,
        orderNumber: order.orderNumber,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        customerAddress: order.customerAddress,
        totalAmount: order.totalAmount,
        status: order.status,
        paymentStatus: 'PAID_QRIS',
        pickedUpAt: order.pickedUpAt,
        items: order.items,
        distance: order.distance,
        deadline: order.deadline,
        assignedBy: order.assignedBy,
      );
    }

    // Update in current detail
    if (_currentOrderDetail != null && _currentOrderDetail!.id == id) {
      final order = _currentOrderDetail!;
      _currentOrderDetail = OrderModel(
        id: order.id,
        orderNumber: order.orderNumber,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        customerAddress: order.customerAddress,
        totalAmount: order.totalAmount,
        status: order.status,
        paymentStatus: 'PAID',
        pickedUpAt: order.pickedUpAt,
        items: order.items,
        distance: order.distance,
        deadline: order.deadline,
        assignedBy: order.assignedBy,
      );
    }

    notifyListeners();
  }

  void setDeliveringOrders(List<OrderModel> orders) {
    _deliveringOrders = orders;
    notifyListeners();
  }
}
