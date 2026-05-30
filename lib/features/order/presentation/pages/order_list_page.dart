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

  const OrderListPage({super.key, this.onOpenDrawer});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<OrderModel>? _localOptimizedOrders;

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

  void _showScannerMockup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Scan Barcode Resi',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Arahkan kamera ke barcode resi pada paket',
                style: TextStyle(color: AppColors.textMutedDark, fontSize: 14),
              ),
              const SizedBox(height: 40),
              // Scanner box mockup
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 2,
                        width: 240,
                        color: Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.qr_code_scanner, size: 80, color: Colors.white24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Simulate picking up order #1 as a mockup
                    final provider = this.context.read<OrderProvider>();
                    final pending = provider.pendingOrders;
                    if (pending.isNotEmpty) {
                      final orderToPickup = pending.first;
                      final success = await provider.pickupOrder(orderToPickup.id);
                      if (success) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Pesanan ${orderToPickup.orderNumber} berhasil di-scan! Status: 🚚 ON DELIVERY'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _tabController.animateTo(1);
                        _refresh();
                      }
                    } else {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Tidak ada tugas baru untuk di-pickup.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Simulasi: Scan Sukses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final pending = orderProvider.pendingOrders;
    final delivering = orderProvider.deliveringOrders;

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
          tabs: [
            Tab(
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
            Tab(
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
          ],
        ),
      ),
      body: TabBarView(
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
            child: _buildList(delivering, isPending: false),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScannerMockup,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Scan Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            'Tidak ada tugas saat ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 16),
          ),
        ],
      );
    }

    final showOptimization = !isPending && list.length > 1;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: showOptimization ? activeList.length + 1 : activeList.length,
      itemBuilder: (context, index) {
        if (showOptimization && index == 0) {
          return _buildRouteOptimizationBanner(list);
        }
        final order = activeList[showOptimization ? index - 1 : index];
        return _buildOrderCard(order, isPending);
      },
    );
  }

  Widget _buildRouteOptimizationBanner(List<OrderModel> orders) {
    final hasOptimized = _localOptimizedOrders != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: hasOptimized
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasOptimized ? const Color(0xFF10B981) : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasOptimized ? Icons.check_circle_rounded : Icons.explore_rounded, 
                  color: Colors.white, 
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasOptimized ? 'Rute Pengiriman Optimal Aktif' : 'Optimasi Jalur Pengiriman (TSP)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasOptimized 
                          ? 'Alamat diurutkan berdasarkan titik terdekat.'
                          : 'Urutkan alamat kurir agar hemat waktu & BBM.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouteOptimizationPage(orders: orders),
                ),
              );
              if (result != null && result is List<OrderModel>) {
                setState(() {
                  _localOptimizedOrders = result;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: hasOptimized ? const Color(0xFF047857) : AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(hasOptimized ? Icons.insights_rounded : Icons.insights_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  hasOptimized ? 'Lihat/Hitung Ulang Rute' : 'Mulai Optimasi Rute (TSP)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildOrderCard(OrderModel order, bool isPending) {
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
              // Provider already updated its lists via pickupOrder().
              // Just switch to the "Proses Kirim" tab — no refresh needed.
              _tabController.animateTo(1);
            } else {
              // Only refresh if we didn't just do a pickup (avoids race condition)
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
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    _buildBadge(order.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AppColors.textMutedDark),
                    const SizedBox(width: 8),
                    Text(
                      order.customerName,
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
                    Column(
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
                        ),
                      ],
                    ),
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
      case 'ondelivery':
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
}
