class AppConstants {
  // If testing on android emulator, localhost is 10.0.2.2. If on iOS/Web, it is localhost.
  static const String baseUrl = 'http://localhost:8000/api'; // Or replace with your server IP

  // Auth Endpoints
  static const String login = '/login';
  
  // Driver Endpoints
  static const String dashboard = '/driver/dashboard';
  static const String checkIn = '/driver/check-in';
  static const String checkOut = '/driver/check-out';
  static const String orders = '/driver/orders';
  
  static String showOrder(int id) => '/driver/orders/$id';
  static String pickupOrder(int id) => '/driver/orders/$id/pickup';
  static String finishOrder(int id) => '/driver/orders/$id/finish';
}
