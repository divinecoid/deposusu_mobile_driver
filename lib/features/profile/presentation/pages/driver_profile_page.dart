import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/provider/auth_provider.dart';


class DriverProfilePage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const DriverProfilePage({super.key, this.onOpenDrawer});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final user = authProvider.user ?? {};
    final driverProfile = user['profile'] ?? {};
    final name = user['name'] ?? 'Kurir Deposusu';
    final email = user['email'] ?? 'driver@deposusu.com';
    final phone = user['phone'] ?? '081234567890';
    
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
          'Profil Kurir',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Profile Header card with Glassmorphic design
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: AppColors.secondary, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '4.95 Rating Kurir',
                          style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  _buildProfileInfoRow(Icons.email_outlined, 'Email', email),
                  const SizedBox(height: 12),
                  _buildProfileInfoRow(Icons.phone_iphone_rounded, 'Nomor HP', phone),
                  const SizedBox(height: 12),
                  _buildProfileInfoRow(Icons.motorcycle_rounded, 'Kendaraan', '${driverProfile['vehicle_type'] ?? "Motor Matic"} - ${driverProfile['license_plate'] ?? "B 3912 SCG"}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        )
      ],
    );
  }
}
