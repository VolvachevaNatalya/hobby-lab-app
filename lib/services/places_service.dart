import 'dart:convert';
import 'package:http/http.dart' as http;

/// A city result from the Nominatim geocoder.
/// Coordinates are already included — no second "details" call needed.
class CityResult {
  final String name;
  final String secondaryText; // e.g. "Haifa District, Israel"
  final double latitude;
  final double longitude;

  const CityResult({
    required this.name,
    required this.secondaryText,
    required this.latitude,
    required this.longitude,
  });
}

/// Returned to the home screen when the user picks a city.
class CitySelection {
  final String name;
  final double latitude;
  final double longitude;

  const CitySelection({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

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

  /// Searches for cities in Israel using OpenStreetMap Nominatim.
  /// No API key required. Returns up to 8 results with embedded coordinates.
  static Future<List<CityResult>> searchCities(
    String input, {
    String language = 'en',
  }) async {
    if (input.trim().isEmpty) return [];

    final uri =
        Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {
        'q': input.trim(),
        'countrycodes': 'il',
        'format': 'json',
        'limit': '8',
        'addressdetails': '1',
        'accept-language': language,
      },
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'HobbyLabApp/1.0',
      }).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body) as List<dynamic>;
        final results = <CityResult>[];
        final seen = <String>{};

        for (final item in raw) {
          final addr = item['address'] as Map<String, dynamic>? ?? {};

          // A result is a city-level place only if address contains a city/town key.
          // District-level results only have 'state', not 'city'.
          final name = (addr['city'] as String?) ??
              (addr['town'] as String?) ??
              (addr['municipality'] as String?);
          if (name == null || name.isEmpty) continue;

          // Deduplicate: skip if we already have a result for this city name
          if (!seen.add(name.toLowerCase())) continue;

          // Secondary label: "State, Country"
          final parts = <String>[
            if (addr['state'] != null && addr['state'] != name)
              addr['state'] as String,
            if (addr['country'] != null) addr['country'] as String,
          ];
          final secondary = parts.join(', ');

          results.add(CityResult(
            name: name,
            secondaryText: secondary,
            latitude: double.parse(item['lat'] as String),
            longitude: double.parse(item['lon'] as String),
          ));
        }
        return results;
      }
    } catch (_) {}
    return [];
  }
}
