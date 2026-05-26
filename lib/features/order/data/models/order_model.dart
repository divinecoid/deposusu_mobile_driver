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
  final List<OrderItemModel> items;

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
    required this.items,
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
      items: (json['items'] as List?)?.map((i) => OrderItemModel.fromJson(i)).toList() ?? [],
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
