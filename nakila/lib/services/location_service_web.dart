import 'dart:async';
import 'dart:html' as html;
import 'package:geocoding/geocoding.dart';

Future<String> getCurrentAddress() async {
  try {
    final geolocation = html.window.navigator.geolocation;

    final position = await geolocation
        .getCurrentPosition()
        .timeout(const Duration(seconds: 15));

    final coords = position.coords;
    if (coords == null || coords.latitude == null || coords.longitude == null) {
      return 'Lokasi tidak tersedia';
    }

    final latitude = coords.latitude!.toDouble();
    final longitude = coords.longitude!.toDouble();

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
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

    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  } on TimeoutException {
    return 'Lokasi timeout - coba lagi';
  } catch (e) {
    return 'Lokasi gagal';
  }
}
