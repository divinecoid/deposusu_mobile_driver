import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../provider/order_provider.dart';
import '../../data/models/order_model.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  File? _image;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrderDetail(widget.orderId);
    });
  }

  Future<void> _launchMaps(String address) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka peta.')),
        );
      }
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka dialer telepon.')),
        );
      }
    }
  }

  Future<void> _pickup() async {
    final success = await context.read<OrderProvider>().pickupOrder(widget.orderId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status terupdate: Barang sedang dikirim.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.read<OrderProvider>().fetchOrderDetail(widget.orderId);
      }
    } else {
      if (mounted) {
        final error = context.read<OrderProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal mengambil tugas.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _capturePhotoAndFinish() async {
    // Show picker options dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
                title: const Text('Ambil Foto Kamera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.info),
                title: const Text('Pilih dari Galeri', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });

        // Show confirmation dialog with preview before uploading
        _showUploadConfirmDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengambil foto: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showUploadConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardDark,
          title: const Text(
            'Selesaikan Pengiriman',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Apakah foto bukti pengiriman ini sudah jelas?',
                style: TextStyle(color: AppColors.textMutedDark),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_image!, height: 180, width: double.infinity, fit: BoxCover),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textMutedDark)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadProofAndFinish();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('Kirim & Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadProofAndFinish() async {
    if (_image == null) return;

    final success = await context.read<OrderProvider>().finishOrder(widget.orderId, _image!);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengiriman sukses diselesaikan!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Go back to list
      }
    } else {
      if (mounted) {
        final error = context.read<OrderProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal menyelesaikan pengiriman.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrderDetail;
    final isLoading = orderProvider.isLoading;

    if (isLoading && order == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(backgroundColor: AppColors.cardDark, title: const Text('Detail Tugas')),
        body: Center(
          child: Text(
            orderProvider.errorMessage ?? 'Pesanan tidak ditemukan.',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final isPrepared = order.status == 'prepared';
    final isOnDelivery = order.status == 'ondelivery';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          order.orderNumber,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.extrabold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Payment info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STATUS PENGIRIMAN', style: TextStyle(color: AppColors.textMutedDark, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                        order.status == 'prepared'
                            ? 'Siap Diambil'
                            : order.status == 'ondelivery'
                                ? 'Sedang Dikirim'
                                : 'Selesai',
                        style: TextStyle(
                          color: order.status == 'prepared'
                              ? AppColors.info
                              : order.status == 'ondelivery'
                                  ? AppColors.warning
                                  : AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('PEMBAYARAN', style: TextStyle(color: AppColors.textMutedDark, fontSize: 10)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (order.paymentStatus == 'PAID' ? AppColors.success : AppColors.danger).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.paymentStatus == 'PAID' ? 'LUNAS' : 'BELUM LUNAS',
                          style: TextStyle(
                            color: order.paymentStatus == 'PAID' ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer Contact Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INFORMASI PENERIMA', style: TextStyle(color: AppColors.textMutedDark, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 16),
                  Text(
                    order.customerName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: AppColors.textMutedDark, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        order.customerPhone.isEmpty ? 'Tidak ada nomor telepon' : order.customerPhone,
                        style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                      ),
                      if (order.customerPhone.isNotEmpty) ...[
                        const Spacer(),
                        InkWell(
                          onTap: () => _makeCall(order.customerPhone),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call, color: AppColors.primaryLight, size: 18),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.location_on_outlined, color: AppColors.textMutedDark, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerAddress.isEmpty ? 'Alamat tidak diset' : order.customerAddress,
                          style: const TextStyle(color: AppColors.textDark, height: 1.4, fontSize: 14),
                        ),
                      ),
                      if (order.customerAddress.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _launchMaps(order.customerAddress),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.navigation_outlined, color: AppColors.secondary, size: 18),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Order Items
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DAFTAR BARANG', style: TextStyle(color: AppColors.textMutedDark, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 24, color: Colors.white10),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SKU: ${item.productSku} • Qty: ${item.quantity}',
                                  style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(item.subtotal),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          )
                        ],
                      );
                    },
                  ),
                  const Divider(height: 32, color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(order.totalAmount),
                        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.extrabold, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Proof Photo display if delivered
            if (order.deliveryProofPhoto != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BUKTI PENGIRIMAN', style: TextStyle(color: AppColors.textMutedDark, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        order.deliveryProofPhoto!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.white24, size: 50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],

            // Action Buttons based on state
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (isPrepared)
              ElevatedButton(
                onPressed: _pickup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.takeout_dining),
                    SizedBox(width: 8),
                    Text('Ambil Tugas & Mulai Kirim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              )
            else if (isOnDelivery)
              ElevatedButton(
                onPressed: _capturePhotoAndFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt),
                    SizedBox(width: 8),
                    Text('Selesaikan & Foto Bukti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
