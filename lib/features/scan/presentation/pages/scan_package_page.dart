import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../order/presentation/provider/order_provider.dart';
import '../../../order/data/models/order_model.dart';

class ScanPackagePage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const ScanPackagePage({super.key, this.onOpenDrawer});

  @override
  State<ScanPackagePage> createState() => _ScanPackagePageState();
}

class _ScanPackagePageState extends State<ScanPackagePage> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;
  bool _isScanned = false;
  String? _scannedCode;
  final TextEditingController _manualCodeController = TextEditingController();
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // Refresh pending orders list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchPendingOrders();
    });
  }

  @override
  void dispose() {
    _laserController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _triggerScanSimulation(OrderModel order) async {
    if (_isScanned) return;

    setState(() {
      _isScanned = true;
      _scannedCode = order.orderNumber;
    });

    // Sound buzz simulation via Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('BEEP! Resi ${order.orderNumber} terdeteksi!'),
          ],
        ),
        backgroundColor: Colors.blue[600],
        duration: const Duration(milliseconds: 600),
      ),
    );

    // Wait 1.5 seconds for animation and then proceed to pickup order
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    final provider = context.read<OrderProvider>();
    final success = await provider.pickupOrder(order.id);

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Scan Paket Sukses!',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paket ${order.orderNumber} atas nama ${order.customerName} telah berhasil dimasukkan ke antrean Dalam Pengantaran.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isScanned = false;
                        _scannedCode = null;
                      });
                      provider.fetchPendingOrders();
                      provider.fetchDeliveringOrders();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Lanjutkan Memindai', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Gagal memproses scan paket.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isScanned = false;
          _scannedCode = null;
        });
      }
    }
  }

  void _submitManualCode() {
    final code = _manualCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final provider = context.read<OrderProvider>();
    final pending = provider.pendingOrders;

    final matchingOrder = pending.firstWhere(
      (o) => o.orderNumber == code,
      orElse: () => OrderModel(
        id: -1,
        orderNumber: '',
        customerName: '',
        customerPhone: '',
        customerAddress: '',
        totalAmount: 0,
        status: '',
        paymentStatus: '',
        items: [],
      ),
    );

    if (matchingOrder.id != -1) {
      _manualCodeController.clear();
      _triggerScanSimulation(matchingOrder);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nomor resi "$code" tidak ditemukan dalam daftar siap ambil.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final pending = orderProvider.pendingOrders;

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
          'Scan Paket Siap Kirim',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.amber : const Color(0xFF64748B),
            ),
            onPressed: () {
              setState(() {
                _flashOn = !_flashOn;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Camera View Finder Simulation box
            GestureDetector(
              onTap: () {
                if (pending.isNotEmpty) {
                  setState(() {
                    _manualCodeController.text = pending.first.orderNumber;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Simulasi Scan: Kode ${pending.first.orderNumber} terbaca!'),
                      backgroundColor: Colors.blue[600],
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                height: 260,
                color: Colors.black,
                child: Stack(
                  children: [
                    // Camera simulation background dark gray
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFF0F172A),
                        child: Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            size: 120,
                            color: Colors.white.withOpacity(_flashOn ? 0.08 : 0.03),
                          ),
                        ),
                      ),
                    ),

                    // Overlay Scan Frame with laser
                    Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isScanned ? Colors.green : AppColors.primary,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isScanned
                            ? const Center(
                                child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 70),
                              )
                            : AnimatedBuilder(
                                animation: _laserAnimation,
                                builder: (context, child) {
                                  return Stack(
                                    children: [
                                      Positioned(
                                        top: _laserAnimation.value * 170,
                                        left: 8,
                                        right: 8,
                                        child: Container(
                                          height: 3.5,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary,
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),

                    // Flash active overlay indicator
                    if (_flashOn)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),

                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          _isScanned ? 'Centang Sukses! Memproses...' : 'Arahkan kamera ke barcode resi paket',
                          style: TextStyle(
                            color: _isScanned ? Colors.greenAccent : AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Manual Resi Entry Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualCodeController,
                      style: const TextStyle(color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Input Kode Resi Manual (e.g. TRX-101)',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _submitManualCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: const Text('Kirim', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // 3. List of Prepared Packages waiting to be scanned
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ANTREAN PAKET',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${pending.length} Paket',
                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (pending.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'Semua paket telah di-scan dan siap dikirim!',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pending.length,
                      itemBuilder: (context, index) {
                        final order = pending[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.orderNumber,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.customerName,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      order.customerAddress,
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _triggerScanSimulation(order),
                                icon: const Icon(Icons.flash_on, size: 12, color: Colors.white),
                                label: const Text('Simulasi Scan', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
