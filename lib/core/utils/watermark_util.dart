import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WatermarkUtil {
  static String _toDMS(double coordinate, bool isLatitude) {
    String direction = isLatitude ? (coordinate >= 0 ? 'N' : 'S') : (coordinate >= 0 ? 'E' : 'W');
    coordinate = coordinate.abs();
    int degrees = coordinate.truncate();
    double minutesFloat = (coordinate - degrees) * 60;
    int minutes = minutesFloat.truncate();
    double seconds = (minutesFloat - minutes) * 60;
    return "$degrees°$minutes'${seconds.toStringAsFixed(3)}\"$direction";
  }

  static Future<File> addDeliveryWatermark({
    required File imageFile,
    required String orderId,
    required String driverId,
    required String status,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) return imageFile;

    final now = DateTime.now();
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final formattedTime = '${now.day.toString().padLeft(2, '0')}-${monthNames[now.month - 1]}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    String dms = '';
    String provinceCity = '';
    String subDistrict = '';

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          dms = '${_toDMS(position.latitude, true)} ${_toDMS(position.longitude, false)}';
          
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              provinceCity = '${place.administrativeArea?.toUpperCase() ?? ''} ${place.subAdministrativeArea?.toUpperCase() ?? ''}'.trim();
              subDistrict = '${place.locality?.toUpperCase() ?? place.subLocality?.toUpperCase() ?? ''}'.trim();
            }
          } catch(e) {}
        }
      }
    } catch (e) {
      dms = 'GPS Error';
    }

    final driverInfo = '[$driverId] NUR ROHMAT';

    final watermarkLines = [
      formattedTime,
      if (provinceCity.isNotEmpty) provinceCity,
      if (subDistrict.isNotEmpty) subDistrict,
      dms,
      '$orderId  $driverInfo',
    ];

    final font = decodedImage.width > 1000 ? img.arial48 : img.arial24;
    final padding = 15;
    final lineSpacing = 8;
    
    final totalHeight = (font.size + lineSpacing) * watermarkLines.length;

    // Bottom-Left alignment
    final startX = padding;
    final startY = decodedImage.height - totalHeight - padding;

    // Optional: Draw a subtle background gradient or box for readability
    img.fillRect(
      decodedImage,
      x1: 0,
      y1: startY - padding,
      x2: decodedImage.width,
      y2: decodedImage.height,
      color: img.ColorRgba8(0, 0, 0, 100), // Slightly transparent black covering bottom
    );

    // Draw each line
    int currentY = startY;
    for (var line in watermarkLines) {
      // Draw shadow
      img.drawString(
        decodedImage,
        line,
        font: font,
        x: startX + 2,
        y: currentY + 2,
        color: img.ColorRgb8(0, 0, 0),
      );
      // Draw text
      img.drawString(
        decodedImage,
        line,
        font: font,
        x: startX,
        y: currentY,
        color: img.ColorRgb8(230, 230, 230), // Off-White
      );
      currentY += font.size + lineSpacing;
    }

    final encoded = img.encodeJpg(decodedImage, quality: 85);
    await imageFile.writeAsBytes(encoded);

    return imageFile;
  }
}
