import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image/image.dart' as img;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/watermark_util.dart';
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
  File? _qrisPaymentProof;      // Foto bukti pembayaran QRIS
  final _picker = ImagePicker();
  final _receivedByController = TextEditingController();
  bool _isSimulating = false;


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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bukti Pengiriman Paket',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih metode pengambilan foto bukti serah terima paket',
                style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, order);
                },
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text('Buka Kamera', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, order);
                },
                icon: const Icon(Icons.photo_library_outlined, color: AppColors.secondary),
                label: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.secondary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  _simulatePhotoSuccess(order);
                },
                icon: const Icon(Icons.science_rounded, color: Colors.white),
                label: const Text('Simulasi Foto Sukses (Mock)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _simulatePhotoSuccess(OrderModel order) async {
    setState(() {
      _isSimulating = true;
    });
    try {
      final image = img.Image(width: 800, height: 600);
      img.fill(image, color: img.ColorRgb8(30, 41, 59));
      
      img.drawString(
        image, 
        'BUKTI PENGIRIMAN DEPOSUSU', 
        font: img.arial48, 
        x: 50, 
        y: 100, 
        color: img.ColorRgb8(255, 255, 255),
      );
      img.drawString(
        image, 
        'PESANAN: ${order.orderNumber}', 
        font: img.arial24, 
        x: 50, 
        y: 180, 
        color: img.ColorRgb8(16, 185, 129),
      );
      img.drawString(
        image, 
        'STATUS: SEDANG DISERAHKAN (MOCK)', 
        font: img.arial24, 
        x: 50, 
        y: 220, 
        color: img.ColorRgb8(251, 191, 36),
      );
      
      final jpegBytes = img.encodeJpg(image, quality: 80);
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/mock_delivery_${order.orderNumber}.jpg');
      await file.writeAsBytes(jpegBytes);

      final File watermarkedFile = await WatermarkUtil.addDeliveryWatermark(
        imageFile: file,
        orderId: order.orderNumber,
        driverId: 'DRV-001',
        status: 'DELIVERED',
      );

      setState(() {
        _image = watermarkedFile;
        _isSimulating = false;
      });

      _showUploadConfirmDialog();
    } catch (e) {
      setState(() {
        _isSimulating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error simulasi foto: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
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
  }

  void _showUploadConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        final hintColor = isDark ? Colors.grey[500]! : Colors.grey[500]!;
        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.15);
        final fillColor = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04);

        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Delivery Selesai',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apakah foto bukti pengiriman ini sudah jelas?',
                  style: TextStyle(color: isDark ? Colors.grey[400]! : Colors.grey[600]!),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_image!, height: 180, width: MediaQuery.of(context).size.width * 0.7, fit: BoxFit.cover),
                ),
                const SizedBox(height: 20),
                // Field Diterima Oleh
                Text(
                  'DITERIMA OLEH',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _receivedByController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    color: textColor,           // ← theme-aware, bukan hardcode putih
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'Nama penerima barang...',
                    hintStyle: TextStyle(color: hintColor),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: isDark ? Colors.grey[400]! : Colors.grey[600]!)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadProofAndFinish();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
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
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    
                    Text(
                      'Laporan Gagal Kirim',
                      style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pilih tindakan lanjutan untuk paket yang tidak dapat dikirim',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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
                    Text(
                      'Pilih Alasan Kegagalan',
                      style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReason,
                          dropdownColor: cardBg,
                          isExpanded: true,
                          style: TextStyle(color: textColor, fontSize: 14),
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
                      Text(
                        'Pilih Waktu Kirim Ulang',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRescheduleDate,
                            dropdownColor: cardBg,
                            isExpanded: true,
                            style: TextStyle(color: textColor, fontSize: 14),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scan QRIS Deposusu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(height: 16),
                const SizedBox(height: 10),
                
                // QRIS Logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
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
                    border: Border.all(color: Colors.grey[300]!),
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
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Resi: ${order.orderNumber} • ${order.customerName}',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11),
                ),
                const SizedBox(height: 8),

                // Instruksi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Setelah customer bayar, foto struk / layar notifikasi pembayaran sebagai bukti.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isSelected 
          ? activeColor.withValues(alpha: 0.15) 
          : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03)),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : (isDark ? Colors.white10 : Colors.black12),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey,
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
    final isLoading = orderProvider.isLoading || _isSimulating;

    if (isLoading && order == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.surface, title: Text('Detail Tugas')),
        body: Center(
          child: Text(
            orderProvider.errorMessage ?? 'Pesanan tidak ditemukan.',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final isPrepared = order.status == 'prepared';
    final isOnDelivery = order.status == 'delivering';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          order.orderNumber,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STATUS PENGIRIMAN', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                        order.status == 'prepared'
                            ? 'Siap Diambil'
                            : order.status == 'delivering'
                                ? 'Sedang Dikirim'
                                : order.status == 'failed_reschedule'
                                    ? 'Reschedule'
                                    : order.status == 'failed_returned'
                                        ? 'Retur Gudang'
                                        : 'Selesai',
                        style: TextStyle(
                          color: order.status == 'prepared'
                              ? AppColors.info
                              : order.status == 'delivering'
                                  ? AppColors.warning
                                  : order.status == 'failed_reschedule'
                                      ? Colors.orange
                                      : order.status == 'failed_returned'
                                          ? Colors.redAccent
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
                      Text('PEMBAYARAN', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!, fontSize: 10)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (order.paymentStatus.toUpperCase().startsWith('PAID') ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.paymentStatus.toUpperCase().startsWith('PAID') ? 'LUNAS' : 'BELUM LUNAS',
                          style: TextStyle(
                            color: order.paymentStatus.toUpperCase().startsWith('PAID') ? AppColors.success : AppColors.danger,
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_ind_outlined, color: AppColors.secondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DITUGASKAN OLEH', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(order.assignedBy!, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                        ],
                      ),
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('INFORMASI PENERIMA', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 16),
                  Text(
                    order.customerName,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        order.customerPhone.isEmpty ? 'Tidak ada nomor telepon' : order.customerPhone,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontSize: 14),
                      ),
                      if (order.customerPhone.isNotEmpty) ...[
                        const Spacer(),
                        InkWell(
                          onTap: () => _makeCall(order.customerPhone),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.location_on_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerAddress.isEmpty ? 'Alamat tidak diset' : order.customerAddress,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, height: 1.4, fontSize: 14),
                        ),
                      ),
                      if (order.customerAddress.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _launchMaps(order.customerAddress),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
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
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DAFTAR BARANG', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => Divider(height: 24, color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
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
                                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SKU: ${item.productSku} • Qty: ${item.quantity}',
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!, fontSize: 12),
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
                            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                          )
                        ],
                      );
                    },
                  ),
                  Divider(height: 32, color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Tagihan', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontWeight: FontWeight.bold)),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(order.totalAmount),
                        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w800, fontSize: 18),
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BUKTI PENGIRIMAN', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!, fontWeight: FontWeight.bold, fontSize: 11)),
                    const SizedBox(height: 16),
                    if (order.receivedBy != null && order.receivedBy!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_rounded, color: AppColors.success, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('DITERIMA OLEH', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  const SizedBox(height: 2),
                                  Text(order.receivedBy!, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                                ],
                              ),
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
                                child: Icon(Icons.broken_image, color: Colors.white24, size: 50),
                              ),
                            )
                          : Image.file(
                              File(order.deliveryProofPhoto!),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, color: Colors.white24, size: 50),
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'BUKTI BAYAR QRIS',
                          style: TextStyle(
                            color: AppColors.success,
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
                              color: AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.camera_alt_rounded, color: AppColors.info, size: 13),
                                SizedBox(width: 4),
                                Text('Ambil Ulang', style: TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.bold)),
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
                          child: Icon(Icons.broken_image, color: Colors.white24, size: 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showFailedDeliveryDialog,
                      icon: const Icon(Icons.cancel_presentation_rounded, color: Colors.redAccent, size: 18),
                      label: const Text('Gagal Kirim', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: !order.paymentStatus.toUpperCase().startsWith('PAID')
                        ? ElevatedButton.icon(
                            onPressed: () => _showQrisModal(order),
                            icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 18),
                            label: const Text('Tunjukkan QRIS Bayar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _capturePhotoAndFinish(order),
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            label: const Text('Serahkan Barang & Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                  ),
                ],
              )
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
