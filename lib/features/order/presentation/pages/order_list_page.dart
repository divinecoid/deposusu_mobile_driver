import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../provider/order_provider.dart';
import '../../data/models/order_model.dart';
import 'order_detail_page.dart';
import 'route_optimization_page.dart';


class OrderListPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final ValueChanged<int>? onNavigateTab;

  const OrderListPage({super.key, this.onOpenDrawer, this.onNavigateTab});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<OrderModel>? _localOptimizedOrders;
  bool _isAcceptingAll = false;

  Future<void> _acceptAllTugas(List<OrderModel> pendingOrders) async {
    if (_isAcceptingAll) return;
    setState(() {
      _isAcceptingAll = true;
    });
    
    final provider = context.read<OrderProvider>();
    final messenger = ScaffoldMessenger.of(context);
    
    int count = 0;
    try {
      final ordersToAccept = List<OrderModel>.from(pendingOrders);
      for (var order in ordersToAccept) {
        final success = await provider.pickupOrder(order.id);
        if (success) count++;
      }
    } catch (e) {
      debugPrint('Error accepting all tasks: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAcceptingAll = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Berhasil menerima $count tugas baru!'),
            backgroundColor: AppColors.success,
          ),
        );
        _tabController.animateTo(1); // Auto switch to Proses Kirim tab!
        _refresh();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _localOptimizedOrders = null;
    });
    final provider = context.read<OrderProvider>();
    await Future.wait([
      provider.fetchPendingOrders(),
      provider.fetchDeliveringOrders(),
    ]);
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
                  color: isCompleted 
                      ? AppColors.success 
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
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
    final pending = orderProvider.pendingOrders;
    final delivering = orderProvider.deliveringOrders;

    int currentStep = 1;
    if (delivering.isNotEmpty) {
      final allScanned = delivering.every((o) => orderProvider.verifiedOrderIds.contains(o.id));
      currentStep = allScanned ? 3 : 2;
    } else if (pending.isNotEmpty) {
      currentStep = 1;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: Icon(Icons.menu_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: Text(
          'Daftar Pengiriman',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textMutedDark,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: [
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Tugas Baru'),
                    if (pending.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: AppColors.info,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${pending.length}',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Proses Kirim'),
                    if (delivering.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${delivering.length}',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildProgressStepper(currentStep),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppColors.primary,
                      child: _buildList(pending, isPending: true),
                    ),
                    RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppColors.primary,
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildList(delivering, isPending: false),
                          ),
                          if (delivering.isNotEmpty && delivering.every((o) => orderProvider.verifiedOrderIds.contains(o.id)))
                            _buildOptimasiRuteCTA(delivering),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isAcceptingAll)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.65),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.secondary),
                      SizedBox(height: 16),
                      Text(
                        'Menerima Semua Tugas...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptimasiRuteCTA(List<OrderModel> delivering) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08))),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -3),
          )
        ],
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            widget.onNavigateTab?.call(2); // Switch to Navigasi tab (index 2)
          },
          icon: const Icon(Icons.directions_car_rounded, color: Colors.white),
          label: const Text(
            'Mulai Pengantaran',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildTerimaSemuaHeader(List<OrderModel> pendingList) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
              : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFF7DD3FC)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.blue.withValues(alpha: 0.04),
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
                  'Tugas Baru Tersedia',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pendingList.length} tugas siap diambil',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _acceptAllTugas(pendingList),
            icon: const Icon(Icons.check_circle_outline, size: 14),
            label: const Text(
              'Terima Semua',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<OrderModel> list, {required bool isPending}) {
    final activeList = (!isPending && _localOptimizedOrders != null) ? _localOptimizedOrders! : list;

    if (activeList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Icon(Icons.delivery_dining_outlined, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            isPending ? 'Tidak ada tugas baru saat ini' : 'Tidak ada tugas pengantaran aktif saat ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 16),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: isPending ? activeList.length + 1 : activeList.length,
      itemBuilder: (context, index) {
        if (isPending) {
          if (index == 0) {
            return _buildTerimaSemuaHeader(activeList);
          }
          final order = activeList[index - 1];
          return _NewOfferCard(
            order: order,
            onRefresh: _refresh,
            tabController: _tabController,
          );
        } else {
          final order = activeList[index];
          return _buildOrderCard(order, isPending);
        }
      },
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text, Color iconColor) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, bool isPending) {
    final provider = context.watch<OrderProvider>();
    int totalItems = order.items.fold(0, (sum, item) => sum + item.quantity);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
            );
            if (result == 'picked_up') {
              _tabController.animateTo(1);
            } else {
              _refresh();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.orderNumber,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSourceBadge(order.orderSource),
                      ],
                    ),
                    if (!isPending) ...[
                      if (provider.verifiedOrderIds.contains(order.id))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 10),
                              SizedBox(width: 4),
                              Text('Terverifikasi', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 10),
                              SizedBox(width: 4),
                              Text('⚠️ Belum Discan', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                    ] else
                      _buildBadge(order.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textMutedDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMutedDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.customerAddress.isEmpty ? 'Alamat tidak diset' : order.customerAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoItem(
                      context,
                      Icons.social_distance_outlined,
                      order.distance != null ? '${order.distance} km' : 'TBD',
                      AppColors.primary,
                    ),
                    _buildInfoItem(
                      context,
                      Icons.access_time,
                      order.deadline != null ? DateFormat('HH:mm').format(order.deadline!) : 'Asap',
                      Colors.orange,
                    ),
                    _buildInfoItem(
                      context,
                      Icons.inventory_2_outlined,
                      '$totalItems Paket',
                      AppColors.secondary,
                    ),
                  ],
                ),
                Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Tagihan',
                            style: TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(order.totalAmount),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isPending && !provider.verifiedOrderIds.contains(order.id))
                      ElevatedButton.icon(
                        onPressed: () {
                          widget.onNavigateTab?.call(3); // Switch to Scan tab (index 3)
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 14, color: Colors.white),
                        label: const Text('Scan Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
                          );
                          if (result == 'picked_up') {
                            _tabController.animateTo(1);
                          } else {
                            _refresh();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPending ? AppColors.primary : AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          isPending ? 'Ambil' : 'Detail',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'prepared':
        color = AppColors.info;
        label = 'Siap Ambil';
        break;
      case 'delivering':
        color = AppColors.warning;
        label = 'Dalam Kirim';
        break;
      case 'failed_reschedule':
        color = Colors.orange;
        label = 'Reschedule';
        break;
      case 'failed_returned':
        color = Colors.redAccent;
        label = 'Retur Gudang';
        break;
      case 'delivered':
      case 'done':
      case 'completed':
        color = AppColors.success;
        label = 'Selesai';
        break;
      default:
        color = AppColors.textMutedDark;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    Color color;
    String label;
    IconData icon;

    switch (source.toLowerCase()) {
      case 'app':
        color = const Color(0xFF1E3A8A); // Royal Blue
        label = 'APP';
        icon = Icons.phone_android_rounded;
        break;
      case 'web':
        color = const Color(0xFF0D9488); // Teal
        label = 'WEB';
        icon = Icons.language_rounded;
        break;
      case 'shopee':
        color = const Color(0xFFEA580C); // Shopee Orange
        label = 'SHOPEE';
        icon = Icons.shopping_bag_outlined;
        break;
      case 'tokopedia':
        color = const Color(0xFF16A34A); // Tokopedia Hijau
        label = 'TOKOPEDIA';
        icon = Icons.store_rounded;
        break;
      case 'tiktok':
        color = const Color(0xFF0F172A); // Midnight Black
        label = 'TIKTOK SHOP';
        icon = Icons.music_note_rounded;
        break;
      case 'manual':
      default:
        color = const Color(0xFF64748B); // Slate Grey
        label = 'MANUAL';
        icon = Icons.note_alt_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _NewOfferCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onRefresh;
  final TabController tabController;

  const _NewOfferCard({
    required this.order,
    required this.onRefresh,
    required this.tabController,
  });

  @override
  State<_NewOfferCard> createState() => _NewOfferCardState();
}

class _NewOfferCardState extends State<_NewOfferCard> {
  int _secondsLeft = 30;
  Timer? _timer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
        }
      } else {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });
    context.read<OrderProvider>().rejectOrder(widget.order.id).then((_) {
      widget.onRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    int totalItems = widget.order.items.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _secondsLeft <= 10 
              ? Colors.redAccent.withValues(alpha: 0.5) 
              : (isDark ? Colors.white10 : Colors.black12),
          width: _secondsLeft <= 10 ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: widget.order.id)),
            );
            if (result == 'picked_up') {
              widget.tabController.animateTo(1);
            } else {
              widget.onRefresh();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.order.orderNumber,
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSourceBadge(widget.order.orderSource),
                      ],
                    ),
                    // Ticking timer badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _secondsLeft <= 10 ? Colors.redAccent : Colors.amber[700],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${_secondsLeft}s',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textMutedDark),
                    const SizedBox(width: 8),
                    Text(
                      widget.order.customerName,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMutedDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.order.customerAddress.isEmpty ? 'Alamat tidak diset' : widget.order.customerAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoItem(
                      context,
                      Icons.social_distance_outlined,
                      widget.order.distance != null ? '${widget.order.distance} km' : 'TBD',
                      AppColors.primary,
                    ),
                    _buildInfoItem(
                      context,
                      Icons.access_time,
                      widget.order.deadline != null ? DateFormat('HH:mm').format(widget.order.deadline!) : 'Asap',
                      Colors.orange,
                    ),
                    _buildInfoItem(
                      context,
                      Icons.inventory_2_outlined,
                      '$totalItems Paket',
                      AppColors.secondary,
                    ),
                  ],
                ),
                
                Divider(height: 24, color: isDark ? Colors.white10 : Colors.black12),
                Row(
                  children: [
                    // Reject Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing 
                            ? null 
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final provider = context.read<OrderProvider>();
                                setState(() {
                                  _isProcessing = true;
                                });
                                _timer?.cancel();
                                final success = await provider.rejectOrder(widget.order.id);
                                if (success && mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Pesanan ${widget.order.orderNumber} ditolak.'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  widget.onRefresh();
                                } else {
                                  setState(() {
                                    _isProcessing = false;
                                  });
                                }
                              },
                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                        label: const Text(
                          'Tolak',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Accept Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final provider = context.read<OrderProvider>();
                                setState(() {
                                  _isProcessing = true;
                                });
                                _timer?.cancel();
                                final success = await provider.pickupOrder(widget.order.id);
                                if (success && mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Pesanan ${widget.order.orderNumber} diterima! Masuk ke Proses Kirim.'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  widget.tabController.animateTo(1);
                                  widget.onRefresh();
                                } else {
                                  setState(() {
                                    _isProcessing = false;
                                  });
                                }
                              },
                        icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Terima',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          disabledBackgroundColor: Colors.grey[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String text, Color iconColor) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    Color color;
    String label;
    IconData icon;

    switch (source.toLowerCase()) {
      case 'app':
        color = const Color(0xFF1E3A8A); // Royal Blue
        label = 'APP';
        icon = Icons.phone_android_rounded;
        break;
      case 'web':
        color = const Color(0xFF0D9488); // Teal
        label = 'WEB';
        icon = Icons.language_rounded;
        break;
      case 'shopee':
        color = const Color(0xFFEA580C); // Shopee Orange
        label = 'SHOPEE';
        icon = Icons.shopping_bag_outlined;
        break;
      case 'tokopedia':
        color = const Color(0xFF16A34A); // Tokopedia Hijau
        label = 'TOKOPEDIA';
        icon = Icons.store_rounded;
        break;
      case 'tiktok':
        color = const Color(0xFF0F172A); // Midnight Black
        label = 'TIKTOK SHOP';
        icon = Icons.music_note_rounded;
        break;
      case 'manual':
      default:
        color = const Color(0xFF64748B); // Slate Grey
        label = 'MANUAL';
        icon = Icons.note_alt_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
