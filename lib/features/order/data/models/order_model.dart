class OrderModel {
  final int id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final String? deliveryProofPhoto;
  final String? receivedBy;
  final List<OrderItemModel> items;
  final String? assignedBy;
  final double? distance;
  final DateTime? deadline;
  final String orderSource; // Added: 'app', 'web', 'shopee', 'tokopedia', 'tiktok', 'manual'
  final String deliveryType; // 'instant', 'sameday', 'scheduled'
  final bool isUrgent;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.pickedUpAt,
    this.deliveredAt,
    this.deliveryProofPhoto,
    this.receivedBy,
    required this.items,
    this.assignedBy,
    this.distance,
    this.deadline,
    this.orderSource = 'app', // Default value
    this.deliveryType = 'sameday',
    this.isUrgent = false,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerAddress: json['customer_address'] ?? '',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      status: json['status'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      pickedUpAt: json['picked_up_at'] != null ? DateTime.tryParse(json['picked_up_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.tryParse(json['delivered_at']) : null,
      deliveryProofPhoto: json['delivery_proof_photo'],
      receivedBy: json['recipient_name'],
      assignedBy: json['assigned_by'],
      distance: json['distance'] != null ? double.tryParse(json['distance'].toString()) : null,
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      items: (json['items'] as List?)?.map((i) => OrderItemModel.fromJson(i)).toList() ?? [],
      orderSource: json['order_source'] ?? 'app',
      deliveryType: json['delivery_type'] ?? 'sameday',
      isUrgent: json['is_urgent'] == true || json['is_urgent'] == 1,
    );
  }
}

class OrderItemModel {
  final int id;
  final int quantity;
  final double price;
  final double subtotal;
  final String productName;
  final String productSku;

  OrderItemModel({
    required this.id,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.productName,
    required this.productSku,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    return OrderItemModel(
      id: json['id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      productName: product['name'] ?? '',
      productSku: product['sku'] ?? '',
    );
  }
}
