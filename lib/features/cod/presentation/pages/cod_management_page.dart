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
  }


  void _showQrisModal(OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(height: 16),
                    const SizedBox(height: 10),
                    
                    // QRIS Logo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
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
                        border: Border.all(color: Colors.grey[300]!),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Resi: ${order.orderNumber} • ${order.customerName}',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11),
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
                        minimumSize: const Size(double.infinity, 44),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final border = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : Colors.black87),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: Text(
          'Pembayaran',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
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
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SALDO',
                    style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(_collectedCod),
                    style: const TextStyle(
                      color: Color(0xFF10B981), // Emerald green representing 0 cash held
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Strictly Cashless (Enforced QRIS Only)',
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tagihan QRIS Pending', style: TextStyle(color: Colors.white54, fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_pendingCod),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.secondary, size: 14),
                            SizedBox(width: 6),
                            Text('Secure', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
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
                Text(
                  'ANTREAN PEMBAYARAN',
                  style: TextStyle(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  '${_codOrders.length} COD Active',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_codOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: const Center(
                  child: Text(
                    'Tidak ada paket pembayaran COD aktif.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
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
                  final isPaid = order.paymentStatus.toUpperCase().contains('PAID');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.orderNumber,
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaid 
                                    ? AppColors.success.withValues(alpha: 0.1) 
                                    : Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPaid ? 'LUNAS (QRIS)' : 'BELUM BAYAR (COD)',
                                style: TextStyle(
                                  color: isPaid ? AppColors.success : Colors.orange,
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
                            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              order.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                order.customerAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Tagihan', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id_ID',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(order.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            if (!isPaid)
                              ElevatedButton.icon(
                                onPressed: () => _showQrisModal(order),
                                icon: const Icon(Icons.qr_code_2_rounded, color: Colors.black, size: 16),
                                label: const Text('Bayar via QRIS', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                        // State will automatically update via OrderProvider
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
