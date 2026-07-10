import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/watermark_util.dart';
import '../../../order/presentation/provider/order_provider.dart';
import '../../../order/data/models/order_model.dart';

class CodManagementPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const CodManagementPage({super.key, this.onOpenDrawer});

  @override
  State<CodManagementPage> createState() => _CodManagementPageState();
}

class _CodManagementPageState extends State<CodManagementPage> {
  File? _qrisPaymentProof;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchDeliveringOrders();
      context.read<OrderProvider>().fetchCompletedOrders();
    });
  }


  void _showQrisModal(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scan QRIS Deposusu',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 10),
                    
                    // QRIS Logo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'QRIS GPN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mock QR Image Canvas using CustomPaint
                    Container(
                      width: 180,
                      height: 180,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: CustomPaint(
                        painter: _MockQrCodePainter(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(order.totalAmount),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Resi: ${order.orderNumber} • ${order.customerName}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _takeQrisPaymentProof(order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 46),
                        elevation: 0,
                      ),
                      child: const Text('Konfirmasi & Foto Bukti Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _takeQrisPaymentProof(OrderModel order) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        if (context.mounted) {
          final File watermarkedFile = await WatermarkUtil.addDeliveryWatermark(
            imageFile: File(pickedFile.path),
            orderId: order.orderNumber,
            driverId: 'DRV-001',
            status: 'PAID (QRIS)',
          );
          setState(() {
            _qrisPaymentProof = watermarkedFile;
          });
          _confirmQrisPayment(order);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto bukti pembayaran QRIS bersifat WAJIB. Silakan ambil foto struk / notifikasi.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error kamera: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _confirmQrisPayment(OrderModel order) {
    context.read<OrderProvider>().simulateQrisPayment(order.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _qrisPaymentProof != null
                    ? 'QRIS LUNAS ✓ Bukti foto tersimpan!'
                    : 'Pembayaran QRIS ${order.orderNumber} DIKONFIRMASI!',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final delivering = orderProvider.deliveringOrders;
    final completed = orderProvider.completedOrders;
    
    // Combine both to find all COD orders for today for stats calculation
    final allOrders = [...delivering, ...completed];

    // Stats calculation
    final List<OrderModel> _allCodOrders = allOrders.where((o) => o.paymentStatus.toUpperCase() == 'UNPAID' || o.paymentStatus.toUpperCase() == 'PAID_QRIS' || o.paymentStatus.toUpperCase() == 'PAID_CASH' || o.orderNumber == 'TRX-104').toList();
    
    double _collectedCod = 0.0;
    double _pendingCod = 0.0;
    for (var o in _allCodOrders) {
      if (o.paymentStatus.toUpperCase() == 'PAID_QRIS' || o.paymentStatus.toUpperCase() == 'PAID_CASH') {
        _collectedCod += o.totalAmount;
      } else if (o.paymentStatus.toUpperCase() == 'UNPAID') {
        _pendingCod += o.totalAmount;
      }
    }

    // List to display in UI (only active ones)
    final List<OrderModel> _codOrders = delivering.where((o) => o.paymentStatus.toUpperCase() == 'UNPAID' || o.paymentStatus.toUpperCase() == 'PAID_QRIS' || o.paymentStatus.toUpperCase() == 'PAID_CASH' || o.orderNumber == 'TRX-104').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Balance Summary Card (Strictly Cashless Glassmorphism layout)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFEFF6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'TOTAL SALDO QRIS DIKUMPULKAN',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(_collectedCod),
                    style: const TextStyle(
                      color: Color(0xFF10B981), // Emerald green representing cashless success
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Non-Tunai Saja (Enforced QRIS Only)',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tagihan QRIS Pending', style: TextStyle(color: Color(0xFF475569), fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_pendingCod),
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 14),
                            SizedBox(width: 6),
                            Text('Aman', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. COD Orders List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ANTREAN PEMBAYARAN',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  '${_codOrders.length} COD Aktif',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_codOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'Tidak ada paket pembayaran COD aktif.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _codOrders.length,
                itemBuilder: (context, index) {
                  final order = _codOrders[index];
                  final isPaid = order.paymentStatus.toUpperCase().startsWith('PAID');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.orderNumber,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaid 
                                    ? const Color(0xFFD1FAE5) 
                                    : const Color(0xFFFFEDD5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPaid ? 'LUNAS (QRIS)' : 'BELUM BAYAR (COD)',
                                style: TextStyle(
                                  color: isPaid ? const Color(0xFF059669) : const Color(0xFFD97706),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              order.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order.customerAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Tagihan', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(order.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                            if (!isPaid)
                              ElevatedButton.icon(
                                onPressed: () => _showQrisModal(order),
                                icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 16),
                                label: const Text('Bayar via QRIS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  elevation: 0,
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final pickedFile = await _picker.pickImage(
                                      source: ImageSource.camera,
                                      imageQuality: 75,
                                    );
                                    if (pickedFile != null && context.mounted) {
                                      final File watermarkedFile = await WatermarkUtil.addDeliveryWatermark(
                                        imageFile: File(pickedFile.path),
                                        orderId: order.orderNumber,
                                        driverId: 'DRV-001',
                                        status: 'DELIVERED',
                                      );
                                      final success = await context.read<OrderProvider>().finishOrder(order.id, watermarkedFile, receivedBy: order.customerName);
                                      if (success && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Delivery Selesai!'), backgroundColor: AppColors.success),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                label: const Text('Serahkan Barang & Selesai', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  elevation: 0,
                                ),
                              )
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _MockQrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double step = size.width / 15.0;
    final paintDark = Paint()..color = Colors.black;

    // Draw standard QR code boundaries block elements manually
    // Top-Left corner finder pattern
    canvas.drawRect(Rect.fromLTWH(0, 0, step * 4, step * 4), paintDark);
    canvas.drawRect(Rect.fromLTWH(step, step, step * 2, step * 2), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(step * 1.5, step * 1.5, step, step), paintDark);

    // Top-Right corner finder pattern
    canvas.drawRect(Rect.fromLTWH(size.width - step * 4, 0, step * 4, step * 4), paintDark);
    canvas.drawRect(Rect.fromLTWH(size.width - step * 3, step, step * 2, step * 2), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(size.width - step * 2.5, step * 1.5, step, step), paintDark);

    // Bottom-Left corner finder pattern
    canvas.drawRect(Rect.fromLTWH(0, size.height - step * 4, step * 4, step * 4), paintDark);
    canvas.drawRect(Rect.fromLTWH(step, size.height - step * 3, step * 2, step * 2), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(step * 1.5, size.height - step * 2.5, step, step), paintDark);

    // Draw some random abstract QR blocks inside the center
    final randomPositions = [
      Offset(step * 5, step * 5), Offset(step * 6, step * 5), Offset(step * 8, step * 5),
      Offset(step * 5, step * 7), Offset(step * 7, step * 7), Offset(step * 9, step * 7),
      Offset(step * 6, step * 8), Offset(step * 8, step * 8), Offset(step * 10, step * 8),
      Offset(step * 11, step * 5), Offset(step * 12, step * 6), Offset(step * 11, step * 7),
      Offset(step * 5, step * 11), Offset(step * 6, step * 12), Offset(step * 7, step * 11),
      Offset(step * 9, step * 10), Offset(step * 10, step * 11), Offset(step * 12, step * 12),
    ];

    for (var pos in randomPositions) {
      canvas.drawRect(Rect.fromLTWH(pos.dx, pos.dy, step * 1.2, step * 1.2), paintDark);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
