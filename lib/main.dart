import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/provider/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/provider/dashboard_provider.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/order/presentation/provider/order_provider.dart';
import 'features/order/presentation/pages/order_list_page.dart';
import 'features/order/presentation/pages/order_history_page.dart';
import 'features/maps/presentation/pages/maps_navigation_page.dart';
import 'features/scan/presentation/pages/scan_package_page.dart';
import 'features/profile/presentation/pages/driver_profile_page.dart';
import 'features/settings/presentation/pages/driver_settings_page.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize network API client
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => OrderProvider(apiClient)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Deposusu Kurir',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: authProvider.isAuthenticated
          ? const MainNavigationPage()
          : const LoginPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onNavigateTab: _onItemTapped,
      ), // 0: Home
      OrderListPage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onNavigateTab: _onItemTapped,
      ), // 1: Queue Delivery
      MapsNavigationPage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onNavigateTab: _onItemTapped,
      ), // 2: Maps
      ScanPackagePage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onNavigateTab: _onItemTapped,
      ), // 3: Scan Package
      OrderHistoryPage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ), // 4: History
      DriverProfilePage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ), // 5: Profile
      DriverSettingsPage(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ), // 6: Settings
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2 || index == 3) {
      final orderProvider = context.read<OrderProvider>();
      final delivering = orderProvider.deliveringOrders;
      final verified = orderProvider.verifiedOrderIds;

      if (index == 2) { // Navigasi tab
        if (delivering.isEmpty) {
          _showWarningSnackBar('Tidak ada tugas aktif. Silakan terima tugas terlebih dahulu!');
          return;
        }
        final allScanned = delivering.every((o) => verified.contains(o.id));
        if (!allScanned) {
          _showWarningSnackBar('Silakan scan semua paket terlebih dahulu!');
          setState(() {
            _selectedIndex = 3; // Redirect to Scan tab
          });
          return;
        }
      } else if (index == 3) { // Scan tab
        if (delivering.isEmpty) {
          _showWarningSnackBar('Tidak ada paket aktif untuk discan. Silakan terima tugas terlebih dahulu!');
          return;
        }
      }
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      body: _pages[_selectedIndex],
      drawer: _buildDrawer(context),
      bottomNavigationBar: _selectedIndex > 3
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: theme.colorScheme.surface,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[400],
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_shipping_outlined),
                  activeIcon: Icon(Icons.local_shipping),
                  label: 'Kirim',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore),
                  label: 'Navigasi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner_outlined),
                  activeIcon: Icon(Icons.qr_code_scanner),
                  label: 'Scan',
                ),
              ],
            ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final drawerBg = isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95);
    final auth = context.read<AuthProvider>();
    final user = auth.user ?? {};

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Driver Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      auth.isAuthenticated ? (user['name'] as String).split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase() : 'KR',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user['name'] ?? 'Kurir',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? 'driver@deposusu.com',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Navigation Items List
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDrawerTile(0, 'Beranda', Icons.dashboard_rounded),
                  _buildDrawerTile(1, 'Antrean Pengiriman', Icons.local_shipping_rounded),
                  _buildDrawerTile(2, 'Navigasi', Icons.near_me_rounded),
                  _buildDrawerTile(3, 'Scan Paket', Icons.qr_code_scanner_rounded),
                  _buildDrawerTile(4, 'Riwayat Pengiriman', Icons.history_rounded),
                  _buildDrawerTile(5, 'Profil', Icons.person_rounded),
                  _buildDrawerTile(6, 'Pengaturan', Icons.settings_rounded),
                ],
              ),
            ),

            // Footer: Brand Version
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Deposusu Driver v2.1.0',
                  style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.secondary : (isDark ? Colors.white70 : Colors.black54),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.secondary : (isDark ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close Drawer
          _onItemTapped(index);
        },
      ),
    );
  }
}
