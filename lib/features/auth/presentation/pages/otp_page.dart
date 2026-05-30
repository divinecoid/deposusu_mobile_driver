import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../main.dart';
import '../provider/auth_provider.dart';

class OtpPage extends StatefulWidget {
  final String loginValue;

  const OtpPage({super.key, required this.loginValue});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _resendOtp() async {
    if (!_canResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.requestOtp(widget.loginValue);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP baru telah dikirim!'),
            backgroundColor: AppColors.success,
          ),
        );
        _startTimer();
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

  void _submitOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi 4 digit kode OTP'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(widget.loginValue, otp);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi OTP berhasil!'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to MainNavigationPage (and replace stack)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationPage()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Verifikasi OTP gagal.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _onFieldChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        _focusNodes[index].unfocus();
        _submitOtp();
      }
    }
  }

  void _bypassForTesting() {
    setState(() {
      _controllers[0].text = '1';
      _controllers[1].text = '2';
      _controllers[2].text = '3';
      _controllers[3].text = '4';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP Uji Coba terisi otomatis!'),
        duration: Duration(milliseconds: 800),
        backgroundColor: AppColors.info,
      ),
    );
    _submitOtp();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icon
              const Center(
                child: Icon(
                  Icons.vpn_key_outlined,
                  size: 70,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 24),
              // Header
              const Text(
                'Verifikasi Kode OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'Masukkan 4 digit kode verifikasi yang telah dikirim ke:\n${widget.loginValue}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMutedDark,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // OTP Fields Card
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
                child: Column(
                  children: [
                    // Code Fields Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 56,
                          height: 64,
                          child: RawKeyboardListener(
                            focusNode: FocusNode(), // Wrap key detection to handle backspace easily
                            onKey: (event) {
                              if (event is RawKeyDownEvent && 
                                  event.logicalKey == LogicalKeyboardKey.backspace && 
                                  _controllers[index].text.isEmpty && 
                                  index > 0) {
                                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                              }
                            },
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.bgDark,
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.secondary, width: 2),
                                ),
                              ),
                              onChanged: (value) => _onFieldChanged(value, index),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Verify Button
                    Container(
                      width: double.infinity,
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
                        onPressed: isLoading ? null : _submitOtp,
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
                                'Otorisasi',
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
              const SizedBox(height: 32),

              // Countdown / Resend OTP
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _resendOtp,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                        ),
                        child: const Text(
                          'Kirim Ulang OTP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppColors.textMutedDark,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: 'Kirim ulang OTP dalam '),
                            TextSpan(
                              text: '${_secondsRemaining}s',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 48),

              // Demo Bypass Button
              Opacity(
                opacity: 0.7,
                child: TextButton.icon(
                  onPressed: _bypassForTesting,
                  icon: const Icon(Icons.flash_on_rounded, color: AppColors.secondary),
                  label: const Text(
                    'Bypass untuk Uji Coba (OTP: 1234)',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
