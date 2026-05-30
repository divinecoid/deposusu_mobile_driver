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

  OrderProvider(this.apiClient);

  void _initMockData() {
    if (_mockInitialized) return;
    _mockInitialized = true;
    _pendingOrders = [
      OrderModel(
        id: 101,
        orderNumber: 'TRX-101',
        customerName: 'Ahmad Pelanggan',
        customerPhone: '08111222333',
        customerAddress: 'Jl. Sudirman No. 10, Jakarta',
        status: 'prepared',
        paymentStatus: 'paid',
        totalAmount: 150000,
        distance: 2.5,
        deadline: DateTime.now().add(const Duration(hours: 1)),
        items: [
          OrderItemModel(id: 1, quantity: 2, price: 50000, subtotal: 100000, productName: 'Susu Murni', productSku: 'SM-01'),
          OrderItemModel(id: 2, quantity: 1, price: 50000, subtotal: 50000, productName: 'Susu Coklat', productSku: 'SC-01'),
        ],
      ),
      OrderModel(
        id: 102,
        orderNumber: 'TRX-102',
        customerName: 'Siti Pembeli',
        customerPhone: '08999888777',
        customerAddress: 'Jl. Thamrin No. 5, Jakarta',
        status: 'prepared',
        paymentStatus: 'unpaid',
        totalAmount: 200000,
        distance: 5.1,
        deadline: DateTime.now().add(const Duration(minutes: 30)),
        items: [
          OrderItemModel(id: 3, quantity: 4, price: 50000, subtotal: 200000, productName: 'Susu Strawberry', productSku: 'ST-01'),
        ],
      ),
    ];
    _deliveringOrders = [
      OrderModel(
        id: 100,
        orderNumber: 'TRX-100',
        customerName: 'Bapak Budi',
        customerPhone: '08555444333',
        customerAddress: 'Komp. Polri, Pasar Minggu',
        status: 'ondelivery',
        paymentStatus: 'paid',
        totalAmount: 75000,
        distance: 4.5,
        deadline: DateTime.now().add(const Duration(minutes: 120)),
        pickedUpAt: DateTime.now().subtract(const Duration(minutes: 15)),
        items: [
          OrderItemModel(id: 4, quantity: 1, price: 75000, subtotal: 75000, productName: 'Paket Susu Mix', productSku: 'PM-01'),
        ],
      ),
      OrderModel(
        id: 103,
        orderNumber: 'TRX-103',
        customerName: 'Ibu Ratna Susu',
        customerPhone: '08777666555',
        customerAddress: 'Jl. Kemang Raya No. 12, Mampang',
        status: 'ondelivery',
        paymentStatus: 'paid',
        totalAmount: 120000,
        distance: 1.2,
        deadline: DateTime.now().add(const Duration(minutes: 40)),
        pickedUpAt: DateTime.now().subtract(const Duration(minutes: 10)),
        items: [
          OrderItemModel(id: 5, quantity: 2, price: 60000, subtotal: 120000, productName: 'Susu Premium Pasteur (Frozen)', productSku: 'SP-pasteur'),
        ],
      ),
      OrderModel(
        id: 104,
        orderNumber: 'TRX-104',
        customerName: 'Mas Danu',
        customerPhone: '081234567890',
        customerAddress: 'Jl. Fatmawati Raya No. 88, Cilandak',
        status: 'ondelivery',
        paymentStatus: 'unpaid',
        totalAmount: 95000,
        distance: 2.8,
        deadline: DateTime.now().add(const Duration(minutes: 60)),
        pickedUpAt: DateTime.now().subtract(const Duration(minutes: 5)),
        items: [
          OrderItemModel(id: 6, quantity: 1, price: 95000, subtotal: 95000, productName: 'Paket Susu Segar XL', productSku: 'PS-XL'),
        ],
      ),
      OrderModel(
        id: 105,
        orderNumber: 'TRX-105',
        customerName: 'Mbak Dita',
        customerPhone: '081234567895',
        customerAddress: 'Jl. Wijaya Timur No. 4, Kebayoran Baru',
        status: 'ondelivery',
        paymentStatus: 'paid',
        totalAmount: 180000,
        distance: 3.5,
        deadline: DateTime.now().add(const Duration(minutes: 15)),
        pickedUpAt: DateTime.now().subtract(const Duration(minutes: 2)),
        items: [
          OrderItemModel(id: 7, quantity: 3, price: 60000, subtotal: 180000, productName: 'Susu UHT Full Cream (Instant)', productSku: 'SU-FC'),
        ],
      ),
      OrderModel(
        id: 106,
        orderNumber: 'TRX-106',
        customerName: 'Pak Andi',
        customerPhone: '081234567899',
        customerAddress: 'Jl. Melawai Raya No. 45, Kebayoran Baru',
        status: 'ondelivery',
        paymentStatus: 'paid',
        totalAmount: 110000,
        distance: 2.0,
        deadline: DateTime.now().add(const Duration(minutes: 90)),
        pickedUpAt: DateTime.now().subtract(const Duration(minutes: 8)),
        items: [
          OrderItemModel(id: 8, quantity: 2, price: 55000, subtotal: 110000, productName: 'Susu Yogurt Pack (Same Day)', productSku: 'SY-SD'),
        ],
      ),
    ];
    _completedOrders = [
      OrderModel(
        id: 99,
        orderNumber: 'TRX-099',
        customerName: 'Ibu Ratna',
        customerPhone: '08777666555',
        customerAddress: 'Jl. Mangga Dua Raya',
        status: 'completed',
        paymentStatus: 'paid',
        totalAmount: 320000,
        pickedUpAt: DateTime.now().subtract(const Duration(hours: 3)),
        deliveredAt: DateTime.now().subtract(const Duration(hours: 2)),
        items: [],
      ),
    ];
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
      _errorMessage = 'Mode Offline: $e';
      _initMockData();
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
      _errorMessage = 'Mode Offline: $e';
      _initMockData();
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
      _errorMessage = 'Mode Offline: $e';
      _initMockData();
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
      _errorMessage = 'Mode Offline: $e';
      // MOCK FALLBACK
      final allOrders = [..._pendingOrders, ..._deliveringOrders, ..._completedOrders];
      _currentOrderDetail = allOrders.firstWhere(
        (o) => o.id == id,
        orElse: () => OrderModel(
          id: id,
          orderNumber: 'TRX-$id',
          customerName: 'Customer $id',
          customerPhone: '0812345678',
          customerAddress: 'Alamat Tujuan $id',
          status: 'prepared',
          paymentStatus: 'paid',
          totalAmount: 100000,
          items: [],
        ),
      );
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
      _errorMessage = 'Mode Offline: $e';
      // MOCK FALLBACK
      final idx = _pendingOrders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        final order = _pendingOrders.removeAt(idx);
        final updatedOrder = OrderModel(
          id: order.id,
          orderNumber: order.orderNumber,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
          customerAddress: order.customerAddress,
          status: 'ondelivery',
          paymentStatus: order.paymentStatus,
          totalAmount: order.totalAmount,
          pickedUpAt: DateTime.now(),
          items: order.items,
        );
        _deliveringOrders.add(updatedOrder);
        _currentOrderDetail = updatedOrder;
      }
      
      _isLoading = false;
      notifyListeners();
      return true; // Still return true for mock flow
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
      _errorMessage = 'Mode Offline: $e';
      // MOCK FALLBACK
      final idx = _deliveringOrders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        final order = _deliveringOrders.removeAt(idx);
        final updatedOrder = OrderModel(
          id: order.id,
          orderNumber: order.orderNumber,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
          customerAddress: order.customerAddress,
          status: 'completed',
          paymentStatus: order.paymentStatus.toUpperCase() == 'UNPAID' ? 'PAID_CASH' : order.paymentStatus,
          totalAmount: order.totalAmount,
          pickedUpAt: order.pickedUpAt,
          deliveredAt: DateTime.now(),
          deliveryProofPhoto: photo.path,
          receivedBy: receivedBy.isNotEmpty ? receivedBy : null,
          items: order.items,
        );
        _completedOrders.insert(0, updatedOrder);
        _currentOrderDetail = updatedOrder;
      }

      _isLoading = false;
      notifyListeners();
      return true;
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
      _errorMessage = 'Mode Offline: $e';
      // MOCK FALLBACK
      final idx = _deliveringOrders.indexWhere((o) => o.id == id);
      if (idx != -1) {
        final order = _deliveringOrders.removeAt(idx);
        final updatedOrder = OrderModel(
          id: order.id,
          orderNumber: order.orderNumber,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
          customerAddress: order.customerAddress,
          status: actionType == 'reschedule' ? 'failed_reschedule' : 'failed_returned',
          paymentStatus: order.paymentStatus,
          totalAmount: order.totalAmount,
          pickedUpAt: order.pickedUpAt,
          items: order.items,
          distance: order.distance,
          deadline: order.deadline,
          assignedBy: order.assignedBy,
        );

        if (actionType == 'reschedule') {
          _pendingOrders.add(updatedOrder);
        } else {
          _completedOrders.insert(0, updatedOrder);
        }
        _currentOrderDetail = updatedOrder;
      }

      _isLoading = false;
      notifyListeners();
      return true;
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
}
