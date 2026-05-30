import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/provider/auth_provider.dart';

class DriverSettingsPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const DriverSettingsPage({super.key, this.onOpenDrawer});

  @override
  State<DriverSettingsPage> createState() => _DriverSettingsPageState();
}

class _DriverSettingsPageState extends State<DriverSettingsPage> {
  bool _notificationSound = true;
  bool _notificationVibrate = true;
  bool _offlineBypassMode = false;
  bool _gpxHighAccuracy = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isDark = themeProvider.isDarkMode;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final border = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : Colors.black87),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: Text(
          'Pengaturan',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Theme Configuration Section
          _buildSectionHeader('TAMPILAN & TEMA'),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: isDark,
                  onChanged: (val) {
                    themeProvider.toggleTheme();
                  },
                  secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.secondary),
                  title: const Text('Mode Gelap (Dark Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Gunakan nuansa gelap premium untuk menghemat daya baterai.', style: TextStyle(fontSize: 11)),
                  activeColor: AppColors.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Notification Preferences Section
          _buildSectionHeader('PEMBERITAHUAN (NOTIFIKASI)'),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationSound,
                  onChanged: (val) {
                    setState(() {
                      _notificationSound = val;
                    });
                  },
                  secondary: const Icon(Icons.volume_up_rounded, color: Colors.blue),
                  title: const Text('Suara Peringatan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Mainkan bel ringtone saat tugas pesanan baru masuk.', style: TextStyle(fontSize: 11)),
                  activeColor: Colors.blue,
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  value: _notificationVibrate,
                  onChanged: (val) {
                    setState(() {
                      _notificationVibrate = val;
                    });
                  },
                  secondary: const Icon(Icons.vibration_rounded, color: Colors.blue),
                  title: const Text('Getaran HP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Getarkan perangkat saat status rute diperbarui.', style: TextStyle(fontSize: 11)),
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Testing / Simulation / GPS features
          _buildSectionHeader('SIMULASI GPS & PENGUJIAN'),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _offlineBypassMode,
                  onChanged: (val) {
                    setState(() {
                      _offlineBypassMode = val;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_offlineBypassMode ? 'Bypass Mode Offline Diaktifkan!' : 'Kembali ke Koneksi Server Normal'),
                        backgroundColor: _offlineBypassMode ? AppColors.success : AppColors.primary,
                      ),
                    );
                  },
                  secondary: const Icon(Icons.wifi_off_rounded, color: Colors.orange),
                  title: const Text('Bypass Mode Offline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Abaikan jaringan server, gunakan data lokal tiruan (mock) untuk demonstrasi.', style: TextStyle(fontSize: 11)),
                  activeColor: Colors.orange,
                ),
                const Divider(height: 1, indent: 56),
                SwitchListTile(
                  value: _gpxHighAccuracy,
                  onChanged: (val) {
                    setState(() {
                      _gpxHighAccuracy = val;
                    });
                  },
                  secondary: const Icon(Icons.track_changes_rounded, color: Colors.green),
                  title: const Text('Akurasi GPS Tinggi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 4. Logout trigger button card
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: ListTile(
              onTap: () {
                _showLogoutConfirmDialog(context, authProvider);
              },
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                'Keluar Dari Akun Kurir',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: const Text('Hapus token Sanctum dan set shift lokal.', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, AuthProvider auth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Konfirmasi Keluar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Apakah Anda yakin ingin keluar dari akun kurir Deposusu saat ini? Semua sesi aktif Anda akan dihapus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Batal', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          auth.logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
