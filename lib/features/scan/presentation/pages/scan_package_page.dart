import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../order/presentation/provider/order_provider.dart';
import '../../../order/data/models/order_model.dart';
import '../../../order/presentation/pages/route_optimization_page.dart';

class ScanPackagePage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onNavigateTab;

  const ScanPackagePage({super.key, this.onOpenDrawer, this.onNavigateTab});

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

  void _showAllVerifiedCongratsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final provider = context.read<OrderProvider>();
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.success,
                  child: Icon(Icons.verified_rounded, color: Colors.white, size: 48),
                ),
                 const SizedBox(height: 20),
                const Text(
                  'Semua Paket Terverifikasi! 🎉',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bagus! Semua paket telah berhasil dipindai dan dicocokkan dengan manifes sistem. Rute pengiriman optimal Anda telah disiapkan secara otomatis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close congrats dialog
                      widget.onNavigateTab?.call(2); // Switch to Navigasi tab (index 2)
                    },
                    icon: const Icon(Icons.directions_car_rounded, color: Colors.white),
                    label: const Text('Mulai Pengantaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

    // Wait 1.5 seconds for animation and then proceed to verify order
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    final provider = context.read<OrderProvider>();
    provider.verifyOrder(order.id);
    const success = true;

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFF1E293B),
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
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paket ${order.orderNumber} atas nama ${order.customerName} telah berhasil dipindai dan dicocokkan.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _isScanned = false;
                        _scannedCode = null;
                      });
                      
                      final delivering = provider.deliveringOrders;
                      final allScanned = delivering.isNotEmpty && delivering.every((o) => provider.verifiedOrderIds.contains(o.id));
                      if (allScanned) {
                        _showAllVerifiedCongratsDialog();
                      }
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
    final code = _manualCodeController.text.trim().toUpperCase().replaceAll('#', '');
    if (code.isEmpty) return;

    final provider = context.read<OrderProvider>();
    final delivering = provider.deliveringOrders;
    final unverifiedDelivering = delivering.where((o) => !provider.verifiedOrderIds.contains(o.id)).toList();

    final matchingOrder = unverifiedDelivering.firstWhere(
      (o) => o.orderNumber.toUpperCase().replaceAll('#', '') == code,
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
          content: Text('Nomor resi "$code" tidak ditemukan dalam antrean scan aktif.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProgressStepper(int currentStep) {
    final steps = [
      {'title': 'Terima Tugas', 'icon': Icons.assignment_turned_in_rounded},
      {'title': 'Scan Paket', 'icon': Icons.qr_code_scanner_rounded},
      {'title': 'Optimasi Rute', 'icon': Icons.insights_rounded},
      {'title': 'Antar Paket', 'icon': Icons.explore_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIdx = (index - 1) ~/ 2;
            final isCompleted = stepIdx < currentStep - 1;
            return Expanded(
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : Colors.white10,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          // Step Node
          final stepIdx = index ~/ 2;
          final stepNum = stepIdx + 1;
          final step = steps[stepIdx];
          final isActive = stepNum == currentStep;
          final isCompleted = stepNum < currentStep;

          Color nodeBgColor;
          Color nodeBorderColor;
          Color textColor;
          Widget nodeIcon;

          if (isCompleted) {
            nodeBgColor = AppColors.success.withValues(alpha: 0.15);
            nodeBorderColor = AppColors.success;
            textColor = AppColors.success;
            nodeIcon = const Icon(Icons.check, color: AppColors.success, size: 13);
          } else if (isActive) {
            nodeBgColor = AppColors.primary.withValues(alpha: 0.18);
            nodeBorderColor = AppColors.secondary;
            textColor = Colors.white;
            nodeIcon = Icon(step['icon'] as IconData, color: AppColors.secondary, size: 13);
          } else {
            nodeBgColor = Colors.white.withValues(alpha: 0.03);
            nodeBorderColor = Colors.white10;
            textColor = Colors.white30;
            nodeIcon = Text(
              '$stepNum',
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: nodeBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeBorderColor, width: 1.5),
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ] : null,
                ),
                child: Center(child: nodeIcon),
              ),
              const SizedBox(height: 6),
              Text(
                step['title'] as String,
                style: TextStyle(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final delivering = orderProvider.deliveringOrders;
    final unverifiedDelivering = delivering.where((o) => !orderProvider.verifiedOrderIds.contains(o.id)).toList();

    int currentStep = 2;
    if (delivering.isNotEmpty) {
      final allScanned = delivering.every((o) => orderProvider.verifiedOrderIds.contains(o.id));
      currentStep = allScanned ? 3 : 2;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: const Text(
          'Scan Paket Kurir',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.amber : Colors.white70,
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
            // Stepper Header
            _buildProgressStepper(currentStep),

            // 1. Camera View Finder Simulation box
            GestureDetector(
              onTap: () {
                if (unverifiedDelivering.isNotEmpty) {
                  setState(() {
                    _manualCodeController.text = unverifiedDelivering.first.orderNumber;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Simulasi Scan: Kode ${unverifiedDelivering.first.orderNumber} terbaca!'),
                      backgroundColor: Colors.blue[600],
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                height: 260,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 120,
                        color: Colors.white.withValues(alpha: _flashOn ? 0.08 : 0.03),
                      ),
                    ),

                    // Overlay Scan Frame with laser
                    Center(
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isScanned ? Colors.green : AppColors.secondary,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isScanned
                            ? const Center(
                                child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                              )
                            : AnimatedBuilder(
                                animation: _laserAnimation,
                                builder: (context, child) {
                                  return Stack(
                                    children: [
                                      Positioned(
                                        top: _laserAnimation.value * 160,
                                        left: 8,
                                        right: 8,
                                        child: Container(
                                          height: 3.5,
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.secondary.withValues(alpha: 0.8),
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
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                            color: _isScanned ? Colors.greenAccent : AppColors.secondary,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualCodeController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Input Kode Resi Manual (e.g. ORD-001)',
                        hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _submitManualCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Kirim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // 3. List of Active Packages waiting to be scanned
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ANTREAN VERIFIKASI PAKET',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${unverifiedDelivering.length} Belum Discan',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (delivering.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'Tidak ada paket aktif untuk dikirim.\nAmbil tugas baru terlebih dahulu di menu Kirim.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
                        ),
                      ),
                    )
                  else if (unverifiedDelivering.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Semua Paket Terverifikasi! 🎉',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Semua paket telah berhasil dipindai. Rute optimal pengiriman Anda sudah disiapkan otomatis.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 44,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: AppColors.primaryGradient,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                widget.onNavigateTab?.call(2); // Auto switch to Navigasi tab (index 2)
                              },
                              icon: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 16),
                              label: const Text('Mulai Pengantaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: unverifiedDelivering.length,
                      itemBuilder: (context, index) {
                        final order = unverifiedDelivering[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          order.orderNumber,
                                          style: const TextStyle(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '⚠️ Belum Discan',
                                            style: TextStyle(color: Colors.orange, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      order.customerName,
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      order.customerAddress,
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _triggerScanSimulation(order),
                                icon: const Icon(Icons.flash_on, size: 12, color: Colors.black),
                                label: const Text('Simulasi Scan', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
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
