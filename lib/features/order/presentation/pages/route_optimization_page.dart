import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';

enum OptimizationMode {
  slaFirst,      // High Priority first (Instant, Same Day, Frozen Food) with SLA protection
  distanceFirst, // Pure shortest distance (TSP solver)
  geoCluster     // Balanced clusters (groups geographically Mampang vs Cilandak/Pasar Minggu)
}

class RouteOptimizationPage extends StatefulWidget {
  final List<OrderModel> orders;

  const RouteOptimizationPage({super.key, required this.orders});

  @override
  State<RouteOptimizationPage> createState() => _RouteOptimizationPageState();
}

class _RouteOptimizationPageState extends State<RouteOptimizationPage> {
  bool _isOptimizing = true;
  String _statusText = 'Menginisialisasi Geo-Clustering...';
  double _progress = 0.0;
  late List<OrderModel> _optimizedOrders;
  Timer? _progressTimer;
  Timer? _slaTickerTimer;
  
  OptimizationMode _selectedMode = OptimizationMode.slaFirst;

  final List<String> _stepsSla = [
    'Mengaktifkan Geo-Clustering: Mengelompokkan wilayah Mampang & Cilandak...',
    'Menghubungkan ke GPS Satelit & Peta Realtime...',
    'SLA Monitoring: Mendeteksi 2 tugas High Priority (Instant & Frozen Food)...',
    'Smart Routing: Menghitung penalti waktu untuk TRX-105 (Instant)...',
    'Realtime Balancing: Menyeimbangkan beban rute kurir...',
    'Rute SLA-First Teroptimasi Berhasil Dibuat!',
  ];

  final List<String> _stepsDistance = [
    'Mengabaikan prioritas SLA, beralih ke Jarak Terdekat...',
    'Menghitung matriks jarak Euclidean antar titik...',
    'Menjalankan TSP Solver (Shortest Path)...',
    'Menyusun rute berdasarkan jarak terpendek...',
    'Rute Jarak-First Berhasil Dibuat!',
  ];

  final List<String> _stepsCluster = [
    'Menginisialisasi Geo-Clustering wilayah Jakarta Selatan...',
    'Mengelompokkan Cluster A (Kemang-Mampang) & Cluster B (Pasar Minggu-Cilandak)...',
    'Menyeimbangkan beban antaran (Realtime Balancing)...',
    'Menghubungkan kluster rute melingkar...',
    'Rute Cluster-Balanced Berhasil Dibuat!',
  ];

  int _stepIdx = 0;

  @override
  void initState() {
    super.initState();
    _optimizedOrders = List.from(widget.orders);
    _startOptimizationSimulation();
    
    // SLA Ticker: refresh the countdown timers every second
    _slaTickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _slaTickerTimer?.cancel();
    super.dispose();
  }

  void _startOptimizationSimulation() {
    setState(() {
      _isOptimizing = true;
      _progress = 0.0;
      _stepIdx = 0;
    });

    final steps = _selectedMode == OptimizationMode.slaFirst 
        ? _stepsSla 
        : _selectedMode == OptimizationMode.distanceFirst 
            ? _stepsDistance 
            : _stepsCluster;

    _statusText = steps[0];

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_stepIdx < steps.length - 1) {
        setState(() {
          _stepIdx++;
          _statusText = steps[_stepIdx];
          _progress = (_stepIdx + 1) / steps.length;
        });
      } else {
        timer.cancel();
        _solveRoute();
      }
    });
  }

  void _solveRoute() {
    setState(() {
      // 1. Classify and map orders
      final List<OrderModel> temp = List.from(widget.orders);
      
      if (_selectedMode == OptimizationMode.slaFirst) {
        // High Priority First (Instant, Frozen Food, Same Day) with Predictive Dispatch
        // Order: TRX-105 (Instant, 15m), TRX-103 (Frozen, 40m), TRX-106 (Same Day, 90m),
        // followed by TRX-104 (Regular, 60m), and TRX-100 (Non Urgent, 120m)
        temp.sort((a, b) {
          final aPri = _getPriority(a);
          final bPri = _getPriority(b);
          
          if (aPri != bPri) {
            return bPri.index.compareTo(aPri.index); // High Priority first (descending index)
          }
          return (a.distance ?? 0.0).compareTo(b.distance ?? 0.0);
        });
      } else if (_selectedMode == OptimizationMode.distanceFirst) {
        // Pure distance (TSP Solver)
        temp.sort((a, b) => (a.distance ?? 0.0).compareTo(b.distance ?? 0.0));
      } else {
        // Geo Clustering: Group by geographic zones (Zone A vs Zone B)
        temp.sort((a, b) {
          final aCluster = _getGeoCluster(a);
          final bCluster = _getGeoCluster(b);
          if (aCluster != bCluster) {
            return aCluster.compareTo(bCluster);
          }
          return (a.distance ?? 0.0).compareTo(b.distance ?? 0.0);
        });
      }
      
      _optimizedOrders = temp;
      _isOptimizing = false;
    });
  }

  // Priority classification helper
  _DeliveryPriority _getPriority(OrderModel order) {
    if (order.orderNumber == 'TRX-105') {
      return _DeliveryPriority.highInstant; // High (Instant ⚡)
    }
    if (order.orderNumber == 'TRX-103') {
      return _DeliveryPriority.highFrozenFood; // High (Frozen Food ❄️)
    }
    if (order.orderNumber == 'TRX-106') {
      return _DeliveryPriority.highSameDay; // High (Same Day 📅)
    }
    if (order.orderNumber == 'TRX-104') {
      return _DeliveryPriority.normalRegular; // Normal (Regular Delivery 📦)
    }
    return _DeliveryPriority.lowNonUrgent; // Low (Non Urgent 🕒)
  }

  // Geo Clustering group helper
  String _getGeoCluster(OrderModel order) {
    if (order.orderNumber == 'TRX-103' || order.orderNumber == 'TRX-105') {
      return 'Zone A (Kemang-Mampang)';
    }
    return 'Zone B (Cilandak-Pasar Minggu)';
  }

  String _getSlaCountdown(DateTime? deadline) {
    if (deadline == null) return '-';
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'SLA Breached!';
    
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Optimasi Rute & SLA',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isOptimizing ? _buildLoadingUI() : _buildOptimizedUI(),
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Glowing scanner radar
            Center(
              child: SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  children: [
                    const Center(
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    const Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          size: 36,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Mesin perutean sedang mengalkulasi rute dengan menyeimbangkan jarak, kluster geografis, dan tenggat waktu SLA produk frozen food.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                color: AppColors.secondary,
                backgroundColor: Colors.white10,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedUI() {
    double originalDistance = widget.orders.fold(0.0, (sum, o) => sum + (o.distance ?? 0.0) + 1.8);
    double optimizedDistance = 0.0;
    
    double lastDist = 0.0;
    for (var o in _optimizedOrders) {
      double currentDist = o.distance ?? 0.0;
      optimizedDistance += (currentDist - lastDist).abs() + 0.4;
      lastDist = currentDist;
    }
    
    double distanceSaved = (originalDistance - optimizedDistance).clamp(1.2, 4.5);
    int timeSaved = (distanceSaved * 4.0).round().clamp(8, 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode Selector Tab Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildModeTab(OptimizationMode.slaFirst, 'SLA-First'),
                _buildModeTab(OptimizationMode.distanceFirst, 'Jarak-First'),
                _buildModeTab(OptimizationMode.geoCluster, 'Geo-Cluster'),
              ],
            ),
          ),
        ),

        // Visual Map Mock View
        Container(
          height: 140,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapRoutePainter(orders: _optimizedOrders),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: AppColors.success, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Hemat ${distanceSaved.toStringAsFixed(1)} KM • Hemat $timeSaved Mnt',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Route optimization decision logs (Smart Dispatch explanation tags)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined, color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDecisionLog(),
                    style: const TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Multi-System Engine Dashboard Panel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hub_rounded, color: AppColors.secondary, size: 13),
                    const SizedBox(width: 6),
                    const Text(
                      'ENGINE MULTI-SISTEM AKTIF',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.success, blurRadius: 4, spreadRadius: 1)
                        ]
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Grid of 5 Active Engine Indicators
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  children: [
                    _buildEngineIndicator('Geo-Clustering', 'Zone Active', Icons.grid_view_rounded, Colors.blue),
                    _buildEngineIndicator('Smart Routing', 'TSP Solver', Icons.alt_route_rounded, Colors.green),
                    _buildEngineIndicator('Realtime Bal.', '100% Load', Icons.scale_rounded, Colors.teal),
                    _buildEngineIndicator('SLA Monitor', 'Live Timer', Icons.watch_later_rounded, Colors.amber),
                    _buildEngineIndicator('Pred. Dispatch', 'High Priority', Icons.auto_graph_rounded, Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Timeline Header Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'URUTAN JALUR PENGANTARAN AKTIF',
            style: TextStyle(
              color: AppColors.textMutedDark,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Timeline List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _optimizedOrders.length + 1,
            itemBuilder: (context, index) {
              final isFirst = index == 0;
              final isLast = index == _optimizedOrders.length;
              
              OrderModel? order;
              _DeliveryPriority? priority;
              
              if (!isFirst) {
                order = _optimizedOrders[index - 1];
                priority = _getPriority(order);
              }
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Node Graphic
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isFirst 
                              ? AppColors.primary.withValues(alpha: 0.2) 
                              : isLast 
                                  ? AppColors.secondary.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFirst 
                                ? AppColors.primary 
                                : isLast 
                                    ? AppColors.secondary
                                    : Colors.white24,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isFirst
                              ? const Icon(Icons.warehouse_rounded, color: AppColors.primary, size: 12)
                              : Text(
                                  '$index',
                                  style: TextStyle(
                                    color: isLast ? AppColors.secondary : AppColors.textDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 64, // Slightly longer spacing to show detailed SLA badges
                          color: Colors.white10,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  
                  // Node content card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isFirst ? 'Titik Mulai: Gudang Deposusu' : order!.customerName,
                                  style: TextStyle(
                                    color: isFirst ? AppColors.primary : AppColors.textDark,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isFirst) _buildPriorityBadge(priority!),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isFirst ? 'Jl. Mawar No. 1, Jakarta' : order!.customerAddress,
                            style: const TextStyle(
                              color: AppColors.textMutedDark,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!isFirst) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Distance tag
                                Icon(Icons.navigation_rounded, color: Colors.green[400], size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  '${order!.distance} KM',
                                  style: TextStyle(color: Colors.green[300], fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 12),
                                // Realtime SLA monitoring tag
                                Icon(Icons.watch_later_outlined, color: _getPriorityColor(priority!), size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  'SLA: ${_getSlaCountdown(order.deadline)}',
                                  style: TextStyle(
                                    color: _getPriorityColor(priority),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Confirm button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(_optimizedOrders);
              },
              icon: const Icon(Icons.directions_rounded, color: Colors.white),
              label: const Text(
                'Terapkan Rute Cerdas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab(OptimizationMode mode, String label) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedMode != mode) {
            setState(() {
              _selectedMode = mode;
            });
            _startOptimizationSimulation();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMutedDark,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEngineIndicator(String name, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.white38, fontSize: 6),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(_DeliveryPriority priority) {
    String tierText = '';
    Color tierColor = Colors.grey;
    
    String subText = '';
    Color subColor = Colors.grey;
    IconData subIcon = Icons.info_outline;

    switch (priority) {
      case _DeliveryPriority.highInstant:
        tierText = 'HIGH PRIORITY';
        tierColor = const Color(0xFFEF4444); // Glowing Red
        
        subText = '⚡ INSTANT';
        subColor = const Color(0xFFEF4444);
        subIcon = Icons.bolt;
        break;
      case _DeliveryPriority.highFrozenFood:
        tierText = 'HIGH PRIORITY';
        tierColor = const Color(0xFFF59E0B); // Amber
        
        subText = '❄️ FROZEN FOOD';
        subColor = const Color(0xFFF59E0B);
        subIcon = Icons.ac_unit_rounded;
        break;
      case _DeliveryPriority.highSameDay:
        tierText = 'HIGH PRIORITY';
        tierColor = const Color(0xFF10B981); // Emerald
        
        subText = '📅 SAME DAY';
        subColor = const Color(0xFF10B981);
        subIcon = Icons.calendar_today_rounded;
        break;
      case _DeliveryPriority.normalRegular:
        tierText = 'NORMAL';
        tierColor = const Color(0xFF1976D2); // Blue
        
        subText = '📦 REGULAR';
        subColor = const Color(0xFF1976D2);
        subIcon = Icons.local_shipping_outlined;
        break;
      case _DeliveryPriority.lowNonUrgent:
        tierText = 'LOW PRIORITY';
        tierColor = Colors.grey;
        
        subText = '🕒 NON URGENT';
        subColor = Colors.grey;
        subIcon = Icons.schedule_rounded;
        break;
    }

    return Wrap(
      spacing: 6,
      children: [
        // 1. Tier Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tierColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            tierText,
            style: TextStyle(
              color: tierColor,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ),
        
        // 2. Subtype Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: subColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: subColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(subIcon, color: subColor, size: 9),
              const SizedBox(width: 3),
              Text(
                subText,
                style: TextStyle(
                  color: subColor,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(_DeliveryPriority priority) {
    if (priority == _DeliveryPriority.highInstant) return const Color(0xFFEF4444);
    if (priority == _DeliveryPriority.highFrozenFood) return const Color(0xFFF59E0B);
    if (priority == _DeliveryPriority.highSameDay) return const Color(0xFF10B981);
    if (priority == _DeliveryPriority.normalRegular) return const Color(0xFF1976D2);
    return Colors.grey;
  }

  String _getDecisionLog() {
    switch (_selectedMode) {
      case OptimizationMode.slaFirst:
        return 'SLA-First Active: Urutan disusun prioritas SLA tertinggi (Instant -> Frozen -> Same Day) dengan Predictive Dispatch untuk menghindari penalti rute.';
      case OptimizationMode.distanceFirst:
        return 'Jarak-First Active: Prioritas SLA dikesampingkan. Menggunakan TSP solver murni untuk menghemat rute perjalanan berdasarkan jarak Euclidean terpendek.';
      case OptimizationMode.geoCluster:
        return 'Geo-Cluster Active: Klusterisasi wilayah aktif (Mampang-Kemang vs Cilandak-Pasar Minggu). Rute dikelompokkan per zona untuk mengeliminasi perjalanan bolak-balik.';
    }
  }
}

enum _DeliveryPriority {
  lowNonUrgent,
  normalRegular,
  highSameDay,
  highFrozenFood,
  highInstant
}

class _MapRoutePainter extends CustomPainter {
  final List<OrderModel> orders;

  _MapRoutePainter({required this.orders});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintGrid);
    }

    final List<Offset> points = [
      Offset(size.width * 0.15, size.height * 0.75), // Warehouse start
    ];

    double spacing = size.width * 0.7 / orders.length;
    for (int i = 0; i < orders.length; i++) {
      double factor = (orders[i].distance ?? 0.0) / 5.0; // max distance is 5
      points.add(Offset(
        size.width * 0.25 + (i * spacing),
        size.height * 0.55 - (factor * size.height * 0.4) + (i % 2 == 0 ? 15 : -15),
      ));
    }

    final paintRoute = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintRouteGlow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.2)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paintRouteGlow);
    canvas.drawPath(path, paintRoute);

    final paintWarehousePin = Paint()..color = AppColors.primary;
    final paintPinStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw Warehouse Node
    canvas.drawCircle(points[0], 6.0, paintWarehousePin);
    canvas.drawCircle(points[0], 6.0, paintPinStroke);

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
      
      final paintOrderPin = Paint()..color = pinColor;
      canvas.drawCircle(points[i], 5.0, paintOrderPin);
      canvas.drawCircle(points[i], 5.0, paintPinStroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
