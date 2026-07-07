class AppConstants {
  // ─── BASE URL ────────────────────────────────────────────────────────────────
  // Karena Anda menggunakan HP fisik (bukan emulator), kita gunakan IP lokal Mac:
  // IP Mac Anda terdeteksi: 192.168.1.50
  static const String baseUrl = '192.168.1.6:8000/api';

  // Auth Endpoints
  static const String login = '/login';
  static const String requestOtp = '/driver/request-otp';
  static const String verifyOtp = '/driver/verify-otp';
  
  // Driver Endpoints
  static const String dashboard = '/driver/dashboard';
  static const String checkIn = '/driver/check-in';
  static const String checkOut = '/driver/check-out';
  static const String orders = '/driver/orders';
  
  static String showOrder(int id) => '/driver/orders/$id';
  static String pickupOrder(int id) => '/driver/orders/$id/pickup';
  static String finishOrder(int id) => '/driver/orders/$id/finish';
}
