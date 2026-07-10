import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/watermark_util.dart';
import '../provider/order_provider.dart';
import '../../data/models/order_model.dart';
import '../../../dashboard/presentation/provider/dashboard_provider.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  File? _image;
  File? _qrisPaymentProof;      // Foto bukti pembayaran QRIS
  final _picker = ImagePicker();
  final _receivedByController = TextEditingController();


  String _actionType = 'reschedule'; // 'reschedule' or 'return'
  final List<String> _rescheduleReasons = [
    'Rumah Kosong / Terkunci',
    'Pelanggan Meminta Tunda',
    'Alamat Kurang Jelas',
  ];
  final List<String> _returnReasons = [
    'Pelanggan Menolak Pesanan',
    'Barang Rusak di Jalan',
    'Alamat Tidak Ditemukan',
  ];
  final List<String> _rescheduleDates = [
    'Hari Ini Nanti',
    'Besok Pagi',
    'Lusa Sore',
  ];
  late String _selectedReason;
  late String _selectedRescheduleDate;

  @override
  void dispose() {
    _receivedByController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedReason = _rescheduleReasons[0];
    _selectedRescheduleDate = _rescheduleDates[0];
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
      // Auto check-in sudah diproses backend — refresh dashboard untuk update waktu
      if (mounted) {
        context.read<DashboardProvider>().fetchDashboardData();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status terupdate: Barang sedang dikirim.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, 'picked_up');
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

  Future<void> _capturePhotoAndFinish(OrderModel order) async {
    // Langsung buka kamera — tanpa opsi galeri
    await _pickImage(ImageSource.camera, order);
  }



  Future<void> _pickImage(ImageSource source, OrderModel order) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        final File watermarkedFile = await WatermarkUtil.addDeliveryWatermark(
          imageFile: File(pickedFile.path),
          orderId: order.orderNumber,
          driverId: 'DRV-001',
          status: 'DELIVERED',
        );
        setState(() {
          _image = watermarkedFile;
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
  }  void _showUploadConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        const textColor = Color(0xFF0F172A);
        const hintColor = Color(0xFF94A3B8);
        const borderColor = Color(0xFFE2E8F0);
        const fillColor = Color(0xFFF8FAFC);

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Delivery Selesai',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apakah foto bukti pengiriman ini sudah jelas?',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.maxFinite,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_image!, height: 180, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                // Field Diterima Oleh
                const Text(
                  'DITERIMA OLEH',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _receivedByController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: const Color(0xFF0284C7),
                  decoration: InputDecoration(
                    hintText: 'Nama penerima barang...',
                    hintStyle: const TextStyle(color: hintColor),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF0284C7)),
                    filled: true,
                    fillColor: fillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadProofAndFinish();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Konfirmasi & Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadProofAndFinish() async {
    if (_image == null) return;

    final success = await context.read<OrderProvider>().finishOrder(
      widget.orderId,
      _image!,
      receivedBy: _receivedByController.text.trim(),
    );
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

  void _showFailedDeliveryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            const cardBg = Colors.white;
            const textColor = Color(0xFF0F172A);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pull indicator
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    
                    const Text(
                      'Laporan Gagal Kirim',
                      style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pilih tindakan lanjutan untuk paket yang tidak dapat dikirim',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Choice Selectors: Reschedule vs Return
                    Row(
                      children: [
                        Expanded(
                          child: _buildChoiceBtn(
                            'Reschedule',
                            _actionType == 'reschedule',
                            Icons.calendar_today_rounded,
                            Colors.orange,
                            () => setState(() {
                              _actionType = 'reschedule';
                              _selectedReason = _rescheduleReasons[0];
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildChoiceBtn(
                            'Retur Gudang',
                            _actionType == 'return',
                            Icons.keyboard_return_rounded,
                            Colors.redAccent,
                            () => setState(() {
                              _actionType = 'return';
                              _selectedReason = _returnReasons[0];
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Reason Selector Dropdown
                    const Text(
                      'Pilih Alasan Kegagalan',
                      style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReason,
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                          items: (_actionType == 'reschedule' ? _rescheduleReasons : _returnReasons)
                              .map((String val) => DropdownMenuItem<String>(
                                    value: val,
                                    child: Text(val),
                                  ))
                              .toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setState(() {
                                _selectedReason = newVal;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // If Reschedule: Date Selector Dropdown
                    if (_actionType == 'reschedule') ...[
                      const Text(
                        'Pilih Waktu Kirim Ulang',
                        style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRescheduleDate,
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            style: const TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                            items: _rescheduleDates
                                .map((String val) => DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    ))
                                .toList(),
                            onChanged: (newVal) {
                              if (newVal != null) {
                                  setState(() {
                                    _selectedRescheduleDate = newVal;
                                  });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _submitFailedDelivery();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Konfirmasi Laporan Gagal',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitFailedDelivery() async {
    final success = await context.read<OrderProvider>().failOrder(
      widget.orderId,
      actionType: _actionType,
      reason: _selectedReason,
      rescheduleDate: _actionType == 'reschedule' ? _selectedRescheduleDate : null,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _actionType == 'reschedule'
                  ? 'Pengiriman di-reschedule berhasil!'
                  : 'Paket berhasil ditandai Retur ke Gudang!',
            ),
            backgroundColor: _actionType == 'reschedule' ? Colors.orange : Colors.redAccent,
          ),
        );
        Navigator.pop(context); // Go back to list
      }
    } else {
      if (mounted) {
        final error = context.read<OrderProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal memproses kegagalan pengiriman.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showQrisModal(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Scan QRIS Deposusu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 10),
                
                // QRIS Logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'QRIS GPN',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 16),

                // Mock QR Image Canvas using CustomPaint
                Container(
                  width: 180,
                  height: 180,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: CustomPaint(
                    painter: _MockQrCodePainter(),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resi: ${order.orderNumber} • ${order.customerName}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 8),

                // Instruksi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Setelah customer bayar, foto struk / layar notifikasi pembayaran sebagai bukti.',
                          style: TextStyle(
                            color: Color(0xFF0284C7),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _takeQrisPaymentProof(order);
                  },
                  icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Konfirmasi & Foto Bukti Bayar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Buka kamera langsung untuk ambil foto bukti pembayaran QRIS
  Future<void> _takeQrisPaymentProof(OrderModel order) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        final File watermarkedFile = await WatermarkUtil.addDeliveryWatermark(
          imageFile: File(pickedFile.path),
          orderId: order.orderNumber,
          driverId: 'DRV-001',
          status: 'PAID (QRIS)',
        );
        setState(() {
          _qrisPaymentProof = watermarkedFile;
        });
        _confirmQrisPayment(order);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto bukti pembayaran QRIS bersifat WAJIB. Silakan ambil foto struk / notifikasi.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error kamera: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _confirmQrisPayment(OrderModel order) {
    context.read<OrderProvider>().simulateQrisPayment(order.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              _qrisPaymentProof != null
                  ? 'QRIS LUNAS ✓ Bukti foto tersimpan!'
                  : 'Pembayaran QRIS ${order.orderNumber} DIKONFIRMASI!',
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }



  Widget _buildChoiceBtn(
    String label,
    bool isSelected,
    IconData icon,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: isSelected 
          ? activeColor.withOpacity(0.12) 
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? activeColor : const Color(0xFF64748B), size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrderDetail;
    final isLoading = orderProvider.isLoading;

    if (isLoading && order == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0284C7))),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(backgroundColor: Colors.white, title: const Text('Detail Tugas', style: TextStyle(color: Color(0xFF0F172A)))),
        body: Center(
          child: Text(
            orderProvider.errorMessage ?? 'Pesanan tidak ditemukan.',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    final isPrepared = order.status == 'prepared';
    final isOnDelivery = order.status == 'ondelivery';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          order.orderNumber,
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: isLoading
              ? const Center(
                  heightFactor: 1.5,
                  child: CircularProgressIndicator(color: Color(0xFF0284C7)),
                )
              : isPrepared
                  ? ElevatedButton.icon(
                      onPressed: _pickup,
                      icon: const Icon(Icons.takeout_dining, color: Colors.white),
                      label: const Text(
                        'Ambil Tugas & Mulai Kirim',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    )
                  : isOnDelivery
                      ? Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                onPressed: _showFailedDeliveryDialog,
                                icon: const Icon(Icons.cancel_presentation_rounded, color: Colors.redAccent, size: 18),
                                label: const Text('Gagal Kirim',
                                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: !order.paymentStatus.toUpperCase().contains('PAID') && _qrisPaymentProof == null
                                  ? ElevatedButton.icon(
                                      onPressed: () => _showQrisModal(order),
                                      icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 18),
                                      label: const Text('Tunjukkan QRIS',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0284C7),
                                        minimumSize: const Size(0, 52),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                    )
                                  : ElevatedButton.icon(
                                      onPressed: () => _capturePhotoAndFinish(order),
                                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                      label: const Text('Serahkan & Selesai',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        minimumSize: const Size(0, 52),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 0,
                                      ),
                                    ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Payment info
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STATUS PENGIRIMAN', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        order.status == 'prepared'
                            ? 'Siap Diambil'
                            : order.status == 'ondelivery'
                                ? 'Sedang Dikirim'
                                : order.status == 'failed_reschedule'
                                    ? 'Reschedule'
                                    : order.status == 'failed_returned'
                                        ? 'Retur Gudang'
                                        : 'Selesai',
                        style: TextStyle(
                          color: order.status == 'prepared'
                              ? const Color(0xFF0284C7)
                              : order.status == 'ondelivery'
                                  ? const Color(0xFFF59E0B)
                                  : order.status == 'failed_reschedule'
                                      ? Colors.orange
                                      : order.status == 'failed_returned'
                                          ? Colors.redAccent
                                          : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('PEMBAYARAN', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (order.paymentStatus.toUpperCase().contains('PAID') ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.paymentStatus.toUpperCase().contains('PAID') ? 'LUNAS' : 'BELUM LUNAS',
                          style: TextStyle(
                            color: order.paymentStatus.toUpperCase().contains('PAID') ? const Color(0xFF059669) : const Color(0xFFDC2626),
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

            if (order.assignedBy != null && order.assignedBy!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_ind_outlined, color: Color(0xFF0284C7), size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DITUGASKAN OLEH', style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(order.assignedBy!, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Customer Contact Info
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('INFORMASI PENERIMA', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 16),
                  Text(
                    order.customerName,
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        order.customerPhone.isEmpty ? 'Tidak ada nomor telepon' : order.customerPhone,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      if (order.customerPhone.isNotEmpty) ...[
                        const Spacer(),
                        InkWell(
                          onTap: () => _makeCall(order.customerPhone),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call, color: Color(0xFF0284C7), size: 18),
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
                        child: Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerAddress.isEmpty ? 'Alamat tidak diset' : order.customerAddress,
                          style: const TextStyle(color: Color(0xFF0F172A), height: 1.4, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (order.customerAddress.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _launchMaps(order.customerAddress),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.navigation_outlined, color: Color(0xFF0284C7), size: 18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DAFTAR BARANG', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 24, color: Color(0xFFE2E8F0)),
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
                                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SKU: ${item.productSku} • Qty: ${item.quantity}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
                            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                          )
                        ],
                      );
                    },
                  ),
                  const Divider(height: 32, color: Color(0xFFE2E8F0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(order.totalAmount),
                        style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w900, fontSize: 18),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BUKTI PENGIRIMAN', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 16),
                    if (order.receivedBy != null && order.receivedBy!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6EE7B7)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_rounded, color: Color(0xFF059669), size: 20),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('DITERIMA OLEH', style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                Text(order.receivedBy!, style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        borderRadius: BorderRadius.circular(12),
                        child: order.deliveryProofPhoto!.startsWith('http')
                          ? Image.network(
                              order.deliveryProofPhoto!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, color: Color(0xFFCBD5E1), size: 50),
                              ),
                            )
                          : Image.file(
                              File(order.deliveryProofPhoto!),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, color: Color(0xFFCBD5E1), size: 50),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],

            // ── Bukti Foto Pembayaran QRIS ─────────────────────────────
            if (_qrisPaymentProof != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'BUKTI BAYAR QRIS',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final order = context.read<OrderProvider>().currentOrderDetail;
                            if (order != null) await _takeQrisPaymentProof(order);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBAE6FD)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.camera_alt_rounded, color: Color(0xFF0284C7), size: 13),
                                SizedBox(width: 4),
                                Text('Ambil Ulang', style: TextStyle(color: Color(0xFF0284C7), fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _qrisPaymentProof!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Color(0xFFCBD5E1), size: 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }
}


class _MockQrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double step = size.width / 15.0;
    final paintDark = Paint()..color = Colors.black;

    // Finder patterns
    canvas.drawRect(Rect.fromLTWH(0, 0, step * 4, step * 4), paintDark);
    canvas.drawRect(Rect.fromLTWH(step, step, step * 2, step * 2), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(step * 1.5, step * 1.5, step, step), paintDark);

    canvas.drawRect(Rect.fromLTWH(size.width - step * 4, 0, step * 4, step * 4), paintDark);
    canvas.drawRect(Rect.fromLTWH(size.width - step * 3, step, step * 2, step * 2), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(size.width - step * 2.5, step * 1.5, step, step), paintDark);

    canvas.drawRect(Rect.fromLTWH(0, size.height - step * 4, step * 4, step * 4), paintDark);
    canvas.drawRect(Rect.fromLTWH(step, size.height - step * 3, step * 2, step * 2), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(step * 1.5, size.height - step * 2.5, step, step), paintDark);

    // Random QR data blocks
    final randomPositions = [
      Offset(step * 5, step * 5), Offset(step * 6, step * 5), Offset(step * 8, step * 5),
      Offset(step * 5, step * 7), Offset(step * 7, step * 7), Offset(step * 9, step * 7),
      Offset(step * 6, step * 8), Offset(step * 8, step * 8), Offset(step * 10, step * 8),
      Offset(step * 11, step * 5), Offset(step * 12, step * 6), Offset(step * 11, step * 7),
      Offset(step * 5, step * 11), Offset(step * 6, step * 12), Offset(step * 7, step * 11),
      Offset(step * 9, step * 10), Offset(step * 10, step * 11), Offset(step * 12, step * 12),
    ];

    for (var pos in randomPositions) {
      canvas.drawRect(Rect.fromLTWH(pos.dx, pos.dy, step * 1.2, step * 1.2), paintDark);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
