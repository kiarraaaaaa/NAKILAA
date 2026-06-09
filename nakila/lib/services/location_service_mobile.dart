import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

Future<String> getCurrentAddress() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return 'Layanan lokasi nonaktif';

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return 'Izin lokasi ditolak';
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Izin lokasi ditolak permanen';
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final street = place.street ?? '';
        final locality = place.locality ?? '';
        final administrativeArea = place.administrativeArea ?? '';
        final city = locality.isNotEmpty ? locality : administrativeArea;
        final addressParts = [street, city].where((part) => part.isNotEmpty).toList();
        return addressParts.join(', ').trim();
      }
    } catch (_) {
      // fallback to coordinates if reverse geocoding fails
    }

    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  } catch (e) {
    return 'Lokasi gagal';
  }
}
