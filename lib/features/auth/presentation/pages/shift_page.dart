import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../main.dart';
import '../provider/auth_provider.dart';

class ShiftPage extends StatefulWidget {
  const ShiftPage({super.key});

  @override
  State<ShiftPage> createState() => _ShiftPageState();
}

class _ShiftPageState extends State<ShiftPage> {
  String? _selectedShiftTemp;

  final List<Map<String, dynamic>> _shifts = [
    {
      'id': 'pagi',
      'name': 'Shift Pagi',
      'time': '07:00 - 15:00',
      'icon': Icons.wb_twilight_rounded,
      'color': Colors.blue,
      'gradient': const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'id': 'siang',
      'name': 'Shift Siang',
      'time': '15:00 - 23:00',
      'icon': Icons.wb_sunny_rounded,
      'color': Colors.amber,
      'gradient': const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'id': 'malam',
      'name': 'Shift Malam',
      'time': '23:00 - 07:00',
      'icon': Icons.nightlight_round,
      'color': Colors.purple,
      'gradient': const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  ];

  void _confirmShift() async {
    if (_selectedShiftTemp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih salah satu shift terlebih dahulu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.selectShift(_selectedShiftTemp!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shift ${_selectedShiftTemp!.toUpperCase()} diaktifkan!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to MainNavigationPage and replace routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = context.watch<AuthProvider>().user?['name'] ?? 'Kurir';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $driverName! 👋',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Siap bertugas hari ini?',
                        style: TextStyle(
                          color: AppColors.textMutedDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false).logout();
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Page Title
              const Text(
                'Pilih Shift Kerja Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih shift kerja aktif sebelum memulai pengantaran pesanan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMutedDark,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),

              // Shift Cards List
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _shifts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final shift = _shifts[index];
                    final isSelected = _selectedShiftTemp == shift['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedShiftTemp = shift['id'];
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.transparent : AppColors.cardDark,
                          gradient: isSelected ? shift['gradient'] as Gradient : null,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? (shift['color'] as Color).withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.05),
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (shift['color'] as Color).withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            // Shift Icon with Circle Background
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : AppColors.bgDark,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                shift['icon'] as IconData,
                                color: isSelected ? Colors.white : shift['color'] as Color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Shift Information
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shift['name'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textDark,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    shift['time'] as String,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : AppColors.textMutedDark,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selection Indicator
                            AnimatedScale(
                              scale: isSelected ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Button
              Container(
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _selectedShiftTemp != null
                      ? AppColors.primaryGradient
                      : null,
                  color: _selectedShiftTemp == null ? Colors.white10 : null,
                  boxShadow: _selectedShiftTemp != null
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: _selectedShiftTemp != null ? _confirmShift : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Mulai Tugas',
                    style: TextStyle(
                      color: _selectedShiftTemp != null ? Colors.white : Colors.white24,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
