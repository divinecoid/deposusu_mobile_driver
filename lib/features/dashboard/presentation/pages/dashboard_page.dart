import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../provider/dashboard_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final Function(int)? onNavigateTab;

  const DashboardPage({super.key, this.onOpenDrawer, this.onNavigateTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardData();
    });
  }

  void _handleCheckIn() async {
    final shift = 'Full Day';
    final success = await context.read<DashboardProvider>().checkIn(
      latitude: -6.2088, // Placeholder GPS coordinate (Jakarta)
      longitude: 106.8456,
      shift: shift,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-In berhasil! Selamat bekerja.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = context.read<DashboardProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal Check-In.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleCheckOut() async {
    final success = await context.read<DashboardProvider>().checkOut(
      latitude: -6.2088,
      longitude: 106.8456,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-Out berhasil! Terima kasih untuk kerja keras Anda hari ini.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = context.read<DashboardProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal Check-Out.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    const textColor = Color(0xFF0F172A);
    const mutedTextColor = Color(0xFF64748B);
    final colorScheme = Theme.of(context).colorScheme;
    const isDark = false;
    const surfaceColor = Colors.white;

    final user = authProvider.user ?? {};
    final driverProfile = user['profile'] ?? {};
    final stats = dashboardProvider.stats;
    final attendance = dashboardProvider.attendance;
    final isLoading = dashboardProvider.isLoading;

    final String checkedInTime = attendance['check_in_at'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(attendance['check_in_at']))
        : '--:--';
        
    final String checkedOutTime = attendance['check_out_at'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(attendance['check_out_at']))
        : '--:--';

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
          'DEPOSUSU',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dashboardProvider.fetchDashboardData(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profil Kurir (Card Putih Premium)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF0284C7).withOpacity(0.1),
                        child: Text(
                          authProvider.isAuthenticated ? (authProvider.user!['name'] as String).split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase() : 'KR',
                          style: const TextStyle(
                            color: Color(0xFF0284C7),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'] ?? 'Kurir',
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${driverProfile['vehicle_type'] ?? "Tugas Kurir"} • ${driverProfile['license_plate'] ?? "Siap Bertugas"}',
                              style: const TextStyle(
                                color: mutedTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),



                // Card Attendance Check In/Out
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.watch_later_outlined, color: colorScheme.secondary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ABSENSI',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeCol('Mulai Bertugas', checkedInTime, attendance['checked_in'], isDark, textColor),
                          ),
                          Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12),
                          Expanded(
                            child: _buildTimeCol('Selesai Bertugas', checkedOutTime, attendance['checked_out'], isDark, textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (isLoading)
                        Center(child: CircularProgressIndicator(color: colorScheme.primary))
                      else if (!attendance['checked_in'])
                        ElevatedButton(
                          onPressed: _handleCheckIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Mulai Bertugas', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      else if (attendance['checked_in'] && !attendance['checked_out'])
                        ElevatedButton(
                          onPressed: _handleCheckOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Akhiri Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Tugas Hari Ini Selesai',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Ringkasan Tugas Title
                Text(
                  'RINGKASAN TUGAS HARI INI',
                  style: TextStyle(
                    color: mutedTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Grid stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Siap Ambil',
                        '${stats['pending_tasks'] ?? 0}',
                        Icons.assignment_outlined,
                        Colors.blue,
                        surfaceColor,
                        isDark,
                        textColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Dalam Kirim',
                        '${stats['active_deliveries'] ?? 0}',
                        Icons.local_shipping_outlined,
                        Colors.orange,
                        surfaceColor,
                        isDark,
                        textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCardFull(
                  'Selesai Hari Ini',
                  '${stats['completed_today'] ?? 0}',
                  Icons.task_alt,
                  Colors.green,
                  surfaceColor,
                  isDark,
                  textColor,
                ),
                
                // Quick Actions Title
                const SizedBox(height: 28),
                Text(
                  'AKSI CEPAT (QUICK ACTION)',
                  style: TextStyle(
                    color: mutedTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // 2x2 Grid of Quick Actions
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildQuickActionBtn(
                      context,
                      'Start Delivery',
                      'Mulai Pengiriman',
                      Icons.play_circle_fill_rounded,
                      Colors.blue,
                      () => _showQuickActionDialog(
                        context,
                        'Mulai Pengiriman',
                        'Apakah Anda ingin mengubah status tugas aktif Anda ke Sedang Dikirim dan memulai perjalanan sekarang?',
                        Icons.local_shipping_rounded,
                        Colors.blue,
                        confirmLabel: 'Mulai',
                        onConfirm: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status pengiriman berhasil diubah ke: SEDANG DIKIRIM'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                      ),
                    ),
                    _buildQuickActionBtn(
                      context,
                      'Scan Package',
                      'Scan Barcode/QR',
                      Icons.qr_code_scanner_rounded,
                      Colors.orange,
                      () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(3); // Index 3 is Scan Package tab
                        } else {
                          _showScanSimulator(context);
                        }
                      },
                    ),
                    _buildQuickActionBtn(
                      context,
                      'Open Maps',
                      'Navigasi Peta',
                      Icons.near_me_rounded,
                      Colors.green,
                      () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(2); // Index 2 is Maps tab
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Membuka Peta Navigasi...')),
                          );
                        }
                      },
                    ),
                    _buildQuickActionBtn(
                      context,
                      'Call Customer',
                      'Hubungi Pelanggan',
                      Icons.phone_in_talk_rounded,
                      Colors.pink,
                      () => _showQuickActionDialog(
                        context,
                        'Hubungi Pelanggan',
                        'Pilih metode untuk menghubungi pelanggan aktif:',
                        Icons.phone_rounded,
                        Colors.pink,
                        isCallOption: true,
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

  Widget _buildTimeCol(String title, String time, bool isActive, bool isDark, Color textColor) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            color: isActive ? Colors.green : textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color surfaceColor, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardFull(String label, String value, IconData icon, Color color, Color surfaceColor, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActionDialog(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color, {
    String confirmLabel = 'Lanjutkan',
    VoidCallback? onConfirm,
    bool isCallOption = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (isCallOption) ...[
                  // Call choices
                  _buildCallOptionBtn(
                    context,
                    'Hubungi via WhatsApp',
                    Icons.chat_bubble_rounded,
                    const Color(0xFF25D366),
                    () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Membuka WhatsApp ke +62 812-3456-7890...'),
                          backgroundColor: Color(0xFF25D366),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildCallOptionBtn(
                    context,
                    'Hubungi via Telepon Seluler',
                    Icons.phone_in_talk_rounded,
                    Colors.blue,
                    () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Melakukan panggilan seluler ke 081234567890...'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  // Standard Confirm/Cancel
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (onConfirm != null) onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallOptionBtn(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showScanSimulator(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isScanned = false;
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 440,
                  child: Column(
                    children: [
                      // Camera simulation view (Top)
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                color: const Color(0xFF0F172A),
                                child: Center(
                                  child: Icon(
                                    Icons.photo_camera_back_rounded,
                                    color: Colors.white.withOpacity(0.04),
                                    size: 100,
                                  ),
                                ),
                              ),
                            ),
                            // Scanner overlay grid
                            Center(
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  border: Border.all(color: isScanned ? Colors.green : const Color(0xFF0284C7), width: 2.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: isScanned 
                                  ? const Center(
                                      child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                                    )
                                  : Stack(
                                      children: [
                                        // Laser scanning line
                                        TweenAnimationBuilder<double>(
                                          tween: Tween<double>(begin: 0.0, end: 1.0),
                                          duration: const Duration(seconds: 2),
                                          builder: (context, value, child) {
                                            return Positioned(
                                              top: value * 150,
                                              left: 10,
                                              right: 10,
                                              child: Container(
                                                height: 3,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF0284C7),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFF0284C7),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                            // Cancel/Close button
                            Positioned(
                              top: 12,
                              right: 12,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.black45,
                                child: IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Info & Button Area (Bottom)
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isScanned ? 'Scan Berhasil!' : 'Posisikan Barcode Paket Di Dalam Kotak',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isScanned ? Colors.green : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!isScanned)
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isScanned = true;
                                  });
                                  // Auto close after 1.5s
                                  Future.delayed(const Duration(milliseconds: 1500), () {
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Paket #DP-9021 Berhasil Discan!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                                child: const Text('Simulasikan Scan Paket', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
