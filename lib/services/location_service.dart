import 'package:geolocator/geolocator.dart';

class LocationService {
  /// يُرجع إحداثيات الموقع كنص، أو رسالة خطأ واضحة
  static Future<String> getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'خدمة GPS معطلة';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'تم رفض صلاحية الموقع';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return 'صلاحية الموقع محظورة نهائياً';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      return '$lat, $lng';
    } on LocationServiceDisabledException {
      return 'خدمة GPS معطلة';
    } catch (_) {
      return 'غير متاح';
    }
  }
}
