import 'location_service_mobile.dart' if (dart.library.html) 'location_service_web.dart' as impl;

class LocationService {
  static Future<String> getCurrentAddress() => impl.getCurrentAddress();
}
