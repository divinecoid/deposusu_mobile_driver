import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../provider/order_provider.dart';
import '../../data/models/order_model.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const OrderHistoryPage({super.key, this.onOpenDrawer});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchCompletedOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final completed = orderProvider.completedOrders;
    final isLoading = orderProvider.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : Colors.black87),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: Text(
          'Histori Pengiriman',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.fetchCompletedOrders(),
        color: AppColors.primary,
        child: isLoading && completed.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : completed.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      const Icon(Icons.history_toggle_off, size: 80, color: Colors.white10),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada pengiriman yang diselesaikan',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: completed.length,
                    itemBuilder: (context, index) {
                      final order = completed[index];
                      return _buildHistoryCard(order);
                    },
                  ),
      ),
    );
  }

  Widget _buildHistoryCard(OrderModel order) {
    final String formattedDate = order.deliveredAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(order.deliveredAt!)
        : '--/--/----';

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id)),
            );
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'SELESAI',
                        style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
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
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMutedDark),
                    const SizedBox(width: 8),
                    Text(
                      'Selesai: $formattedDate',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (order.deliveryProofPhoto != null && order.deliveryProofPhoto!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
                        body: Center(
                          child: InteractiveViewer(
                            child: order.deliveryProofPhoto!.startsWith('http')
                                ? Image.network(order.deliveryProofPhoto!)
                                : Image.file(File(order.deliveryProofPhoto!)),
                          ),
                        ),
                      )));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: order.deliveryProofPhoto!.startsWith('http')
                        ? Image.network(
                            order.deliveryProofPhoto!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 120,
                              child: Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 30)),
                            ),
                          )
                        : Image.file(
                            File(order.deliveryProofPhoto!),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 120,
                              child: Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 30)),
                            ),
                          ),
                    ),
                  ),
                ],
                Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Nilai Barang',
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 11),
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
                    Row(
                      children: [
                        Text(
                          'Detail',
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], size: 16),
                      ],
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
}
