import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/presentation/provider/auth_provider.dart';
import '../provider/dashboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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
    final success = await context.read<DashboardProvider>().checkIn(
      latitude: -6.2088, // Placeholder GPS coordinate (Jakarta)
      longitude: 106.8456,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-In berhasil! Selamat bekerja.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final error = context.read<DashboardProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal Check-In.'),
            backgroundColor: AppColors.danger,
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
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final error = context.read<DashboardProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal Check-Out.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
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
      backgroundColor: AppColors.bgDark,
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
                // Header Profil Kurir
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        authProvider.isAuthenticated ? authProvider.user!['name'].substring(0, 2).toUpperCase() : 'KR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${driverProfile['vehicle_type'] ?? "Grand Max"} • ${driverProfile['license_plate'] ?? "B 1234 CD"}',
                            style: const TextStyle(
                              color: AppColors.textMutedDark,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.danger),
                      onPressed: () => authProvider.logout(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Card Attendance Check In/Out
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.watch_later_outlined, color: AppColors.secondary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'PRESENSI HARIAN',
                            style: TextStyle(
                              color: AppColors.textDark,
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
                            child: _buildTimeCol('Check In', checkedInTime, attendance['checked_in']),
                          ),
                          Container(width: 1, height: 40, color: Colors.white10),
                          Expanded(
                            child: _buildTimeCol('Check Out', checkedOutTime, attendance['checked_out']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      else if (!attendance['checked_in'])
                        ElevatedButton(
                          onPressed: _handleCheckIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Check In Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      else if (attendance['checked_in'] && !attendance['checked_out'])
                        ElevatedButton(
                          onPressed: _handleCheckOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Check Out Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Tugas Hari Ini Selesai',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Ringkasan Tugas Title
                const Text(
                  'RINGKASAN TUGAS HARI INI',
                  style: TextStyle(
                    color: AppColors.textMutedDark,
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
                        '${stats['pending_tasks']}',
                        Icons.assignment_outlined,
                        AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Dalam Kirim',
                        '${stats['active_deliveries']}',
                        Icons.local_shipping_outlined,
                        AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCardFull(
                  'Selesai Hari Ini',
                  '${stats['completed_today']}',
                  Icons.task_alt,
                  AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCol(String title, String time, bool isActive) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            color: isActive ? AppColors.success : AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.extrabold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                  fontWeight: FontWeight.extrabold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardFull(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                  color: AppColors.textDark,
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
              fontWeight: FontWeight.extrabold,
            ),
          ),
        ],
      ),
    );
  }
}
