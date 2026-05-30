import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../provider/auth_provider.dart';
import 'otp_page.dart';

// Demo credentials for testing
const String _demoEmail = 'driver@deposusu.com';
const String _demoPhone = '081234567890';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
  
  static Route route() {
    return MaterialPageRoute(builder: (_) => const LoginPage());
  }
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.requestOtp(
      _loginController.text.trim(),
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP berhasil dikirim!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpPage(loginValue: _loginController.text.trim()),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Gagal mengirim OTP.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header/Logo
              const Icon(
                Icons.local_shipping_outlined,
                size: 80,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'DEPOSUSU KURIR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk untuk melihat dan mengantar pesanan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMutedDark,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),

              // Form Card
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Login Field
                      const Text(
                        'Nomor HP / Email',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _loginController,
                        style: const TextStyle(color: AppColors.textDark),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Masukkan Nomor HP atau Email',
                          hintStyle: const TextStyle(color: Colors.white24),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMutedDark),
                          filled: true,
                          fillColor: AppColors.bgDark,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor HP atau Email wajib diisi';
                          }
                          // Simple validation for email or phone number
                          final val = value.trim();
                          final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val);
                          final isPhone = RegExp(r'^[0-9+]{8,15}$').hasMatch(val);
                          if (!isEmail && !isPhone) {
                            return 'Format nomor HP atau email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Request OTP Button
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Kirim Kode OTP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Demo Credentials Card
              _buildDemoCard(),

              const SizedBox(height: 24),
              const Text(
                'Versi 1.1.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_circle_outlined,
                  color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Akun Demo Kurir',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fillDemoCredentials,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flash_on_rounded,
                          color: AppColors.secondary, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Isi Otomatis',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),
          _buildCredentialRow(
            icon: Icons.phone_android_rounded,
            label: 'No. HP',
            value: _demoPhone,
          ),
          const SizedBox(height: 8),
          _buildCredentialRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _demoEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label disalin ke clipboard'),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.secondary,
          ),
        );
      },
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMutedDark, size: 15),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textMutedDark,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.copy_outlined,
              color: Colors.white12, size: 12),
        ],
      ),
    );
  }

  void _fillDemoCredentials() {
    _loginController.text = _demoPhone;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor HP demo telah diisi!'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
