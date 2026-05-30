import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../order/presentation/provider/order_provider.dart';
import '../../../order/data/models/order_model.dart';
import '../../../order/presentation/pages/route_optimization_page.dart';

class MapsNavigationPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const MapsNavigationPage({super.key, this.onOpenDrawer});

  @override
  State<MapsNavigationPage> createState() => _MapsNavigationPageState();
}

class _MapsNavigationPageState extends State<MapsNavigationPage> {
  bool _isGpsActive = true;
  double _vehicleSpeed = 38.0;
  String _activeStopsInfo = 'Memuat Rute...';
  List<OrderModel> _currentRoute = [];
  Timer? _gpsPulseTimer;
  double _gpsPulseValue = 1.0;

  @override
  void initState() {
    super.initState();
    _loadDeliveringOrders();
    _startGpsPulse();
  }

  @override
  void dispose() {
    _gpsPulseTimer?.cancel();
    super.dispose();
  }

  void _loadDeliveringOrders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orders = context.read<OrderProvider>().deliveringOrders;
      setState(() {
        _currentRoute = List.from(orders);
        _activeStopsInfo = 'Terdeteksi ${_currentRoute.length} paket siap diantarkan.';
      });
    });
  }

  void _startGpsPulse() {
    _gpsPulseTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted) {
        setState(() {
          _gpsPulseValue = _gpsPulseValue == 1.0 ? 0.3 : 1.0;
          _vehicleSpeed = 35.0 + (5.0 * (DateTime.now().second % 3));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final delivering = orderProvider.deliveringOrders;
    
    // Fallback if list changes
    if (_currentRoute.isEmpty && delivering.isNotEmpty) {
      _currentRoute = List.from(delivering);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Peta Navigasi Cerdas',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGpsActive ? Icons.gps_fixed : Icons.gps_off,
              color: _isGpsActive ? AppColors.success : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isGpsActive = !_isGpsActive;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isGpsActive ? 'Koneksi GPS Aktif (Akurasi Tinggi)' : 'GPS Dinonaktifkan'),
                  backgroundColor: _isGpsActive ? AppColors.success : Colors.grey,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Neon Map Canvas View
          Positioned.fill(
            child: _currentRoute.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : InteractiveViewer(
                    maxScale: 3.0,
                    minScale: 0.5,
                    child: CustomPaint(
                      painter: _NeonNavigationMapPainter(
                        orders: _currentRoute,
                        gpsPulse: _gpsPulseValue,
                        isDark: isDark,
                      ),
                      size: Size.infinite,
                    ),
                  ),
          ),

          // 2. Floating Top Info Bar: Active Telemetry
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isGpsActive ? AppColors.success : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isGpsActive ? 'Akurasi GPS: 3m' : 'GPS Offline',
                        style: TextStyle(
                          color: isDark ? AppColors.textDark : AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Speed: ${_vehicleSpeed.toStringAsFixed(0)} KM/H',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Satelit: 18 Active',
                    style: TextStyle(
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Bottom Navigation Card with Route Optimization Link
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Route Optimization Banner
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.explore_outlined, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Multi-System Routing Engine',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Geo-Cluster & SLA Monitoring Aktif',
                                style: TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (delivering.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tidak ada paket aktif untuk dioptimasi.'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RouteOptimizationPage(orders: delivering),
                            ),
                          );
                          if (result != null && result is List<OrderModel>) {
                            setState(() {
                              _currentRoute = result;
                              _activeStopsInfo = 'Rute Cerdas teroptimasi berhasil diterapkan!';
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation: 0,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.insights_rounded, size: 14),
                            SizedBox(width: 4),
                            Text('Optimasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                // Destination list view preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'URUTAN ALAMAT PENGANTARAN',
                            style: TextStyle(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Optimized Route',
                              style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: _currentRoute.isEmpty
                            ? const Center(child: Text('Tidak ada antrean kirim'))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _currentRoute.length + 1,
                                itemBuilder: (context, index) {
                                  final isStart = index == 0;
                                  final order = isStart ? null : _currentRoute[index - 1];
                                  final color = isStart 
                                      ? AppColors.primary 
                                      : _getPriorityColor(order!.orderNumber);

                                  return Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: color.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isStart ? Icons.warehouse_rounded : Icons.location_on_rounded,
                                              color: color,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isStart ? 'Gudang' : order!.orderNumber,
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (index < _currentRoute.length)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6),
                                          child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                                        ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String orderNumber) {
    if (orderNumber == 'TRX-105') return const Color(0xFFEF4444); // Red - Instant
    if (orderNumber == 'TRX-103') return const Color(0xFFF59E0B); // Amber - Frozen Food
    if (orderNumber == 'TRX-106') return const Color(0xFF10B981); // Emerald - Same Day
    if (orderNumber == 'TRX-104') return const Color(0xFF1976D2); // Blue - Regular
    return Colors.grey;
  }
}

class _NeonNavigationMapPainter extends CustomPainter {
  final List<OrderModel> orders;
  final double gpsPulse;
  final bool isDark;

  _NeonNavigationMapPainter({
    required this.orders,
    required this.gpsPulse,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width == 0 ? 400.0 : size.width;
    final double h = size.height == 0 ? 700.0 : size.height;

    // Background Map gridlines
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    for (double i = 0; i < w; i += 25) {
      canvas.drawLine(Offset(i, 0), Offset(i, h), gridPaint);
    }
    for (double i = 0; i < h; i += 25) {
      canvas.drawLine(Offset(0, i), Offset(w, i), gridPaint);
    }

    // Abstract city roads representation
    final roadPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final List<List<Offset>> roads = [
      [Offset(w * 0.1, h * 0.1), Offset(w * 0.9, h * 0.1)],
      [Offset(w * 0.1, h * 0.4), Offset(w * 0.9, h * 0.4)],
      [Offset(w * 0.1, h * 0.7), Offset(w * 0.9, h * 0.7)],
      [Offset(w * 0.2, h * 0.05), Offset(w * 0.2, h * 0.95)],
      [Offset(w * 0.5, h * 0.05), Offset(w * 0.5, h * 0.95)],
      [Offset(w * 0.8, h * 0.05), Offset(w * 0.8, h * 0.95)],
      [Offset(w * 0.1, h * 0.85), Offset(w * 0.9, h * 0.35)], // diagonal road
    ];

    for (var r in roads) {
      canvas.drawLine(r[0], r[1], roadPaint);
    }

    // Coordinates points setup
    // 1. Warehouse point
    final warehousePoint = Offset(w * 0.2, h * 0.7);
    
    // 2. Active courier position (pulsing pointer)
    final courierPoint = Offset(w * 0.35, h * 0.55);

    // Delivery destinations coordinate list mapped to grid spaces
    final List<Offset> points = [warehousePoint];
    final double spacingX = w * 0.55 / orders.length;

    for (int i = 0; i < orders.length; i++) {
      double factor = (orders[i].distance ?? 0.0) / 5.0; // scale distance max 5
      points.add(Offset(
        w * 0.25 + (i * spacingX),
        h * 0.6 - (factor * h * 0.35) + (i % 2 == 0 ? 30.0 : -30.0),
      ));
    }

    // Connect rute paths
    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routeGlowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.18)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    canvas.drawPath(path, routeGlowPaint);
    canvas.drawPath(path, routePaint);

    final pinStrokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // Draw Warehouse Node
    canvas.drawCircle(warehousePoint, 7.0, Paint()..color = AppColors.primary);
    canvas.drawCircle(warehousePoint, 7.0, pinStrokePaint);

    // Draw Courier Node with pulsing radius
    final courierPulsePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.18 * gpsPulse)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(courierPoint, 15.0 + (5.0 * (1.0 - gpsPulse)), courierPulsePaint);
    canvas.drawCircle(courierPoint, 6.0, Paint()..color = Colors.blue);
    canvas.drawCircle(courierPoint, 6.0, pinStrokePaint);

    // Draw Order Nodes color-coded by priority
    for (int i = 1; i < points.length; i++) {
      final order = orders[i - 1];
      Color pinColor = Colors.grey;
      
      if (order.orderNumber == 'TRX-105') {
        pinColor = const Color(0xFFEF4444); // Red - Instant
      } else if (order.orderNumber == 'TRX-103') {
        pinColor = const Color(0xFFF59E0B); // Amber - Frozen Food
      } else if (order.orderNumber == 'TRX-106') {
        pinColor = const Color(0xFF10B981); // Emerald - Same Day
      } else if (order.orderNumber == 'TRX-104') {
        pinColor = const Color(0xFF1976D2); // Blue - Regular
      }

      // Pin background shadow
      canvas.drawCircle(points[i], 5.5, Paint()..color = Colors.black26);
      canvas.drawCircle(points[i], 5.0, Paint()..color = pinColor);
      canvas.drawCircle(points[i], 5.0, pinStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
