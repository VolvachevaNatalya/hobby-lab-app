import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  /// Reverse-geocodes coordinates to a city name using Nominatim.
  /// Returns null if the request fails or no city-level name is found.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    final uri =
        Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
      queryParameters: {
        'format': 'jsonv2',
        'lat': lat.toString(),
        'lon': lng.toString(),
        'zoom': '10',
        'addressdetails': '1',
        'accept-language': 'en',
      },
    );
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'HobbyLabApp/1.0',
      }).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        return (addr['city'] as String?) ??
            (addr['town'] as String?) ??
            (addr['municipality'] as String?) ??
            (addr['county'] as String?);
      }
    } catch (_) {}
    return null;
  }
}
