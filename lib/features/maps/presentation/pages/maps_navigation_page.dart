import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/watermark_util.dart';
import '../../../order/presentation/provider/order_provider.dart';
import '../../../order/data/models/order_model.dart';
class MapsNavigationPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onNavigateTab;

  const MapsNavigationPage({super.key, this.onOpenDrawer, this.onNavigateTab});

  @override
  State<MapsNavigationPage> createState() => _MapsNavigationPageState();
}

class _MapsNavigationPageState extends State<MapsNavigationPage> {
  bool _isGpsActive = true;
  double _vehicleSpeed = 38.0;
  List<OrderModel> _currentRoute = [];
  Timer? _gpsPulseTimer;
  double _gpsPulseValue = 1.0;

  int _activeStopIndex = 0;
  final _picker = ImagePicker();
  final _receivedByController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDeliveringOrders();
    _startGpsPulse();
  }

  @override
  void dispose() {
    _gpsPulseTimer?.cancel();
    _receivedByController.dispose();
    super.dispose();
  }

  void _sortRouteBySla() {
    _currentRoute.sort((a, b) {
      // 1. Sort by Priority (Instant > Same Day > Scheduled)
      final aPri = _getStopPriority(a.deliveryType);
      final bPri = _getStopPriority(b.deliveryType);
      
      if (aPri != bPri) {
        return bPri.compareTo(aPri); // Descending (instant first)
      }
      
      // 2. Sort by Urgent Flag
      if (a.isUrgent != b.isUrgent) {
        return a.isUrgent ? -1 : 1; // Urgent (true) comes first
      }
      
      // 3. Sort by Deadline Terdekat
      if (a.deadline != b.deadline) {
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!); // Earliest first
      }
      
      // 4. Sort by Jarak Terdekat
      return (a.distance ?? 0.0).compareTo(b.distance ?? 0.0); // Shortest first
    });
  }

  int _getStopPriority(String type) {
    switch (type.toLowerCase()) {
      case 'instant':
        return 2;
      case 'scheduled':
        return 0;
      case 'sameday':
      default:
        return 1;
    }
  }

  void _loadDeliveringOrders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orders = context.read<OrderProvider>().deliveringOrders;
      setState(() {
        _currentRoute = List.from(orders);
        _sortRouteBySla();
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

  void _showAllStopsCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
                  child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Semua Antaran Sukses! 🏆',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Luar biasa! Anda telah menyelesaikan semua titik pengiriman hari ini dengan selamat. Terima kasih atas kerja keras Anda!',
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      context.read<OrderProvider>().clearVerifiedOrders();
                      widget.onNavigateTab?.call(1); // Switch to Kirim tab (index 1)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Kembali ke Kirim',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildProgressStepper(int currentStep) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = [
      {'title': 'Terima Tugas', 'icon': Icons.assignment_turned_in_rounded},
      {'title': 'Scan Paket', 'icon': Icons.qr_code_scanner_rounded},
      {'title': 'Optimasi Rute', 'icon': Icons.insights_rounded},
      {'title': 'Antar Paket', 'icon': Icons.explore_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: isCompleted ? AppColors.success : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
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
            textColor = isDark ? Colors.white : AppColors.primaryDark;
            nodeIcon = Icon(step['icon'] as IconData, color: AppColors.secondary, size: 13);
          } else {
            nodeBgColor = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02);
            nodeBorderColor = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05);
            textColor = isDark ? Colors.white30 : Colors.black38;
            nodeIcon = Text(
              '$stepNum',
              style: TextStyle(
                color: isDark ? Colors.white30 : Colors.black38,
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

    // Check if the current route has different non-completed orders than the provider's delivering list
    final localDeliveringIds = _currentRoute.skip(_activeStopIndex).map((o) => o.id).toList();
    final providerDeliveringIds = delivering.map((o) => o.id).toList();
    
    // If provider list is different, re-load the whole route
    bool isDifferent = localDeliveringIds.length != providerDeliveringIds.length;
    if (!isDifferent) {
      for (int i = 0; i < localDeliveringIds.length; i++) {
        if (localDeliveringIds[i] != providerDeliveringIds[i]) {
          isDifferent = true;
          break;
        }
      }
    }
    
    if (isDifferent && delivering.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentRoute = List.from(delivering);
          _sortRouteBySla();
          _activeStopIndex = 0;
        });
      });
    } else if (_currentRoute.isEmpty && delivering.isNotEmpty) {
      _currentRoute = List.from(delivering);
      _sortRouteBySla();
      _activeStopIndex = 0;
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
      body: Column(
        children: [
          _buildProgressStepper(4),
          Expanded(
            child: Stack(
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
                              orders: _currentRoute.skip(_activeStopIndex).toList(),
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

                // 3. Sliding Stops Bottom Sheet Drawer (DraggableScrollableSheet)
                _currentRoute.isEmpty
                    ? const SizedBox()
                    : DraggableScrollableSheet(
                        initialChildSize: 0.35,
                        minChildSize: 0.26,
                        maxChildSize: 0.85,
                        builder: (context, scrollController) {
                          final totalStops = _currentRoute.length;
                          final completedStops = _activeStopIndex;
                          final remainingStops = (totalStops - completedStops).clamp(0, totalStops);
                          
                          double totalDistance = _currentRoute.fold(0.0, (sum, o) => sum + (o.distance ?? 0.0));
                          int totalDuration = (totalDistance * 3.5).round() + (totalStops * 5);
                          double distanceSaved = (totalDistance * 0.25).clamp(1.1, 4.2);
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2, offset: Offset(0, -4))
                              ],
                              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                            ),
                            child: Column(
                              children: [
                                // Draggable Handle bar
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    width: 40,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white24 : Colors.black12,
                                      borderRadius: BorderRadius.circular(2.5),
                                    ),
                                  ),
                                ),
                                
                                // Header Statistics summary
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'IKHTISAR RUTE AKTIF',
                                            style: TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$remainingStops / $totalStops Paket Tersisa',
                                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                                        ),
                                        child: Text(
                                          'Hemat ${distanceSaved.toStringAsFixed(1)} KM',
                                          style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Simple Stats Badges
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  child: Row(
                                    children: [
                                      _buildHeaderBadge(Icons.straighten, '${totalDistance.toStringAsFixed(1)} KM', isDark),
                                      const SizedBox(width: 8),
                                      _buildHeaderBadge(Icons.access_time_filled, '$totalDuration Mnt', isDark),
                                      const SizedBox(width: 8),
                                      _buildHeaderBadge(Icons.local_shipping, '$totalStops Stop', isDark),
                                    ],
                                  ),
                                ),
                                const Divider(height: 20, color: Colors.white10),
                                
                                // Stops List
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                    itemCount: _currentRoute.length + 2, // Warehouse start, Stop items, Completed Finish node
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return _buildWarehouseStop(isDark);
                                      }
                                      
                                      final stopIndex = index - 1;
                                      
                                      if (stopIndex == _currentRoute.length) {
                                        return _buildFinishStop(isDark);
                                      }
                                      
                                      return _buildStopCard(stopIndex, isDark);
                                    },
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
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseStop(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.warehouse_rounded, color: AppColors.primary, size: 10),
              ),
            ),
            Container(width: 2, height: 40, color: isDark ? Colors.white10 : Colors.black12),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Titik Mulai: Gudang Deposusu',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'Jl. Mawar No. 1, Jakarta',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinishStop(bool isDark) {
    final allDone = _activeStopIndex >= _currentRoute.length;
    final color = allDone ? AppColors.success : (isDark ? Colors.white24 : Colors.black26);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Icon(Icons.flag_rounded, color: color, size: 10),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selesai Rute',
                style: TextStyle(
                  color: allDone 
                      ? AppColors.success 
                      : (isDark ? Colors.white38 : Colors.black38), 
                  fontSize: 13, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                allDone ? 'Semua antrean rute telah sukses diantar! 🎉' : 'Rute pengantaran selesai.',
                style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStopCard(int stopIndex, bool isDark) {
    final order = _currentRoute[stopIndex];
    final isCompleted = stopIndex < _activeStopIndex;
    final isActive = stopIndex == _activeStopIndex;
    final isLocked = stopIndex > _activeStopIndex;
    final isUnpaid = order.paymentStatus.toUpperCase().contains('UNPAID');
    
    Color nodeColor;
    if (isCompleted) {
      nodeColor = AppColors.success;
    } else if (isActive) {
      nodeColor = AppColors.secondary;
    } else {
      nodeColor = isDark ? Colors.white24 : Colors.black26;
    }

    final cardBg = isActive
        ? (isDark ? const Color(0xFF1E293B) : Colors.blue.withValues(alpha: 0.05))
        : Colors.transparent;

    final borderSide = isActive
        ? Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.5)
        : Border.all(color: Colors.transparent);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline connector
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: nodeColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: nodeColor, width: 2),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: AppColors.success, size: 10)
                    : Text(
                        '${stopIndex + 1}',
                        style: TextStyle(
                          color: nodeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            Container(
              width: 2,
              height: isActive ? 150 : 55,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          ],
        ),
        const SizedBox(width: 14),
        
        // Stop details card
        Expanded(
          child: Opacity(
            opacity: isLocked ? 0.4 : 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: borderSide,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STOP ${stopIndex + 1} ${isCompleted ? '✓' : ''}',
                        style: TextStyle(
                          color: isCompleted ? AppColors.success : AppColors.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${order.distance ?? 1.5} KM',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Customer Name
                  Text(
                    order.customerName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  
                  // Address
                  Text(
                    order.customerAddress,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black45,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Order source / details
                  if (isActive) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildSourceBadge(order.orderSource),
                        const SizedBox(width: 8),
                        _buildPaymentBadge(order.paymentStatus),
                      ],
                    ),
                  ],
                  
                  // Action buttons if active
                  if (isActive) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchNavigation(order),
                            icon: const Icon(Icons.navigation_rounded, size: 14),
                            label: const Text('📍 Navigasi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: isUnpaid
                              ? ElevatedButton.icon(
                                  onPressed: () => _showQRISPaymentDialog(order),
                                  icon: const Icon(Icons.qr_code_2_rounded, size: 14),
                                  label: const Text('Mulai Pembayaran', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber[800],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _showFinishDeliveryDialog(order),
                                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                                  label: const Text('Konfirmasi Pengiriman', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceBadge(String source) {
    Color color;
    switch (source.toLowerCase()) {
      case 'app':
        color = const Color(0xFF1E3A8A);
        break;
      case 'shopee':
        color = const Color(0xFFEA580C);
        break;
      case 'tokopedia':
        color = const Color(0xFF16A34A);
        break;
      case 'tiktok':
        color = const Color(0xFF0F172A);
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        source.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    final isUnpaid = status.toUpperCase().contains('UNPAID');
    final color = isUnpaid ? Colors.orange : Colors.green;
    final label = isUnpaid ? 'COD (BAYAR DI TEMPAT)' : 'LUNAS';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _launchNavigation(OrderModel order) async {
    final address = Uri.encodeComponent(order.customerAddress);
    final url = 'https://www.google.com/maps/search/?api=1&query=$address';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka peta navigasi untuk: ${order.customerName}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showQRISPaymentDialog(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int scanLineKey = 0;
        bool isProcessing = false;
        bool isSuccess = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final dialogBg = isDark ? const Color(0xFF0F172A) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;
            final subTextColor = isDark ? Colors.white60 : Colors.black54;

            if (isSuccess) {
              return Dialog(
                backgroundColor: dialogBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Pembayaran Sukses!',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Webhook callback berhasil diterima.',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status Order: PAID_QRIS ✓',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded, color: AppColors.secondary, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Bayar di Tempat (QRIS)',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: isProcessing ? null : () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white30 : Colors.black38),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Colors.white10),
                    
                    if (isProcessing) ...[
                      const SizedBox(height: 40),
                      const CircularProgressIndicator(color: AppColors.secondary),
                      const SizedBox(height: 24),
                      Text(
                        'Memproses Callback Pembayaran...',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Menunggu sinyal sukses dari gerbang pembayaran...',
                        style: TextStyle(color: subTextColor, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                    ] else ...[
                      // Detail order
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('No. Order:', style: TextStyle(color: subTextColor, fontSize: 11)),
                                Text(order.orderNumber, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Pelanggan:', style: TextStyle(color: subTextColor, fontSize: 11)),
                                Text(order.customerName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Total Tagihan
                      Text('TOTAL TAGIHAN', style: TextStyle(color: subTextColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 2),
                      Text(
                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.totalAmount),
                        style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green[700], fontWeight: FontWeight.w900, fontSize: 24),
                      ),
                      const SizedBox(height: 20),
                      
                      // Interactive QR Container
                      Container(
                        width: 175,
                        height: 175,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.qr_code_2_rounded,
                              size: 155,
                              color: Colors.black87,
                            ),
                            // Scanning red line moving up/down
                            TweenAnimationBuilder<double>(
                              key: ValueKey(scanLineKey),
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: const Duration(seconds: 2),
                              builder: (context, value, child) {
                                return Positioned(
                                  top: 10.0 + (value * 125.0),
                                  left: 6,
                                  right: 6,
                                  child: Container(
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.redAccent.withValues(alpha: 0.8),
                                          blurRadius: 3,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                              onEnd: () {
                                setDialogState(() {
                                  scanLineKey++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tunjukkan QRIS ini pada pelanggan untuk di-scan',
                        style: TextStyle(color: subTextColor, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Callback Simulator Button
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
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              isProcessing = true;
                            });
                            Future.delayed(const Duration(milliseconds: 1200), () {
                              if (context.mounted) {
                                context.read<OrderProvider>().simulateQrisPayment(order.id);
                                setDialogState(() {
                                  isProcessing = false;
                                  isSuccess = true;
                                });
                                
                                Future.delayed(const Duration(milliseconds: 1500), () {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Pembayaran Berhasil! Silakan ketuk "Konfirmasi Pengiriman" untuk menyelesaikan antaran.',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppColors.success,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                });
                              }
                            });
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
                          label: const Text('Simulasi Callback Sukses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFinishDeliveryDialog(OrderModel order) {
    _receivedByController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Selesaikan Antaran',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Harap lengkapi bukti pengiriman untuk order ${order.orderNumber}:',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _receivedByController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Nama Penerima',
                        labelStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded, color: Colors.white30, size: 40),
                            SizedBox(height: 8),
                            Text('Wajib ambil foto bukti pengiriman', style: TextStyle(color: Colors.white30, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.white30)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = _receivedByController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama penerima wajib diisi!'), backgroundColor: Colors.orange),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _takePhotoAndSubmit(order, name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Ambil Foto & Kirim', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _takePhotoAndSubmit(OrderModel order, String recipientName) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );

      if (photo == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final File file = File(photo.path);
      File watermarkedFile = file;

      try {
        watermarkedFile = await WatermarkUtil.addDeliveryWatermark(
          imageFile: file,
          orderId: order.orderNumber,
          driverId: 'NUR ROHMAT',
          status: 'DELIVERED',
        );
      } catch (e) {
        debugPrint('Watermark error: $e');
      }

      final provider = context.read<OrderProvider>();
      final success = await provider.finishOrder(order.id, watermarkedFile, receivedBy: recipientName);

      if (mounted) {
        Navigator.pop(context); 
        
        if (success) {
          setState(() {
            _activeStopIndex++;
          });

          showDialog(
            context: context,
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
                      'Antaran Selesai!',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bukti pengiriman untuk ${order.customerName} telah berhasil diunggah ke server.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (_activeStopIndex >= _currentRoute.length) {
                          _showAllStopsCompletedDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Gagal menyelesaikan pengiriman.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
      
      switch (order.deliveryType.toLowerCase()) {
        case 'instant':
          pinColor = const Color(0xFFEF4444); // Red - Instant
          break;
        case 'sameday':
          pinColor = const Color(0xFF10B981); // Emerald - Same Day
          break;
        case 'scheduled':
          pinColor = const Color(0xFFF59E0B); // Amber - Scheduled
          break;
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
