import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../provider/order_provider.dart';
import '../../data/models/order_model.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

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

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        elevation: 0,
        title: const Text(
          'Histori Pengiriman',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.extrabold),
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
                      const Text(
                        'Belum ada pengiriman yang diselesaikan',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMutedDark, fontSize: 16),
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
      margin: const EdgeInsets.bottom(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
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
                      style: const TextStyle(
                        color: AppColors.textDark,
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
                      style: const TextStyle(
                        color: AppColors.textMutedDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Nilai Barang',
                          style: TextStyle(color: AppColors.textMutedDark, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(order.totalAmount),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text(
                          'Detail',
                          style: TextStyle(color: AppColors.textMutedDark, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: AppColors.textMutedDark, size: 16),
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
