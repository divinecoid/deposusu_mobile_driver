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
    _tabController = TabController(length: 3, vsync: this);
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
      provider.fetchCompletedOrders(),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Scan Barcode Resi',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Arahkan kamera ke barcode resi pada paket',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 40),
              // Scanner box mockup
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0284C7), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        height: 2,
                        width: 240,
                        color: Colors.red.withOpacity(0.5),
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFFCBD5E1)),
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
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 0,
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
    final completed = orderProvider.completedOrders;

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
          'Daftar Pengiriman',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0284C7),
          labelColor: const Color(0xFF0284C7),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          labelPadding: EdgeInsets.zero,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tugas Baru'),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${pending.length}',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Proses Kirim'),
                  if (delivering.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${delivering.length}',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Terkirim'),
                  if (completed.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${completed.length}',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
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
            color: const Color(0xFF0284C7),
            child: _buildList(pending, isPending: true),
          ),
          RefreshIndicator(
            onRefresh: _refresh,
            color: const Color(0xFF0284C7),
            child: _buildList(delivering, isPending: false),
          ),
          RefreshIndicator(
            onRefresh: _refresh,
            color: const Color(0xFF10B981),
            child: _buildCompletedList(completed),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScannerMockup,
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text('Scan Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 2,
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
          const Icon(Icons.delivery_dining_outlined, size: 80, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada tugas saat ini',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500),
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
                colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFE0F2FE), Color(0xFFEFF6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasOptimized ? const Color(0xFF6EE7B7) : const Color(0xFFBAE6FD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
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
                  color: hasOptimized ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF0284C7).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasOptimized ? Icons.check_circle_rounded : Icons.explore_rounded, 
                  color: hasOptimized ? const Color(0xFF047857) : const Color(0xFF0284C7), 
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
                      style: TextStyle(
                        color: hasOptimized ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasOptimized 
                          ? 'Alamat diurutkan berdasarkan titik terdekat.'
                          : 'Urutkan alamat kurir agar hemat waktu & BBM.',
                      style: TextStyle(
                        color: hasOptimized ? const Color(0xFF047857) : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
              backgroundColor: hasOptimized ? const Color(0xFF10B981) : const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insights_rounded, size: 18),
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
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.bold,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
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
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
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
                    const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
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
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.customerAddress.isEmpty ? 'Alamat tidak diset' : order.customerAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
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
                      const Color(0xFF0284C7),
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
                      const Color(0xFF10B981),
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
                        const Text(
                          'Total Tagihan',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(order.totalAmount),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
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
                        backgroundColor: isPending ? const Color(0xFF0284C7) : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
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

  Widget _buildCompletedList(List<OrderModel> list) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Icon(Icons.check_circle_outline_rounded, size: 80, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada pengiriman selesai',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kiriman yang berhasil diselesaikan akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildCompletedCard(list[index]),
    );
  }

  Widget _buildCompletedCard(OrderModel order) {
    int totalItems = order.items.fold(0, (sum, item) => sum + item.quantity);
    final isFailed = order.status == 'failed_returned' || order.status == 'failed_reschedule';
    final cardAccent = isFailed ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final cardBg = isFailed ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardAccent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
            );
          },
          child: Column(
            children: [
              // Header strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFailed ? Icons.cancel_rounded : Icons.check_circle_rounded,
                      color: cardAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.orderNumber,
                      style: TextStyle(
                        color: cardAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    _buildBadge(order.status),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.customerAddress.isEmpty ? 'Alamat tidak diset' : order.customerAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              '$totalItems Paket',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(order.totalAmount),
                          style: TextStyle(
                            color: cardAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
        color = const Color(0xFF0284C7);
        label = 'Siap Ambil';
        break;
      case 'ondelivery':
        color = const Color(0xFFF59E0B);
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
        color = const Color(0xFF10B981);
        label = 'Selesai';
        break;
      default:
        color = const Color(0xFF64748B);
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
