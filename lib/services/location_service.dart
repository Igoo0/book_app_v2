import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static final LocationService instance = LocationService._internal();
  factory LocationService() => instance;
  LocationService._internal();

  // Replace with your Google Maps API key
  static const String _googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  Position? _currentPosition;
  String? _currentAddress;
  
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _currentPosition = position;
      
      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);
      
      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Get address from coordinates
  Future<String?> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
        return _currentAddress;
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return null;
  }

  /// Get nearby bookstores (mock data + Google Places API)
  Future<List<Bookstore>> getNearbyBookstores(double latitude, double longitude, {double radiusKm = 10}) async {
    try {
      List<Bookstore> bookstores = [];
      
      // Add mock bookstores for Indonesia (major cities)
      bookstores.addAll(_getMockBookstores(latitude, longitude, radiusKm));
      
      // If you have Google Places API key, uncomment this:
      // final placesBookstores = await _getBookstoresFromGooglePlaces(latitude, longitude, radiusKm);
      // bookstores.addAll(placesBookstores);
      
      return bookstores;
    } catch (e) {
      debugPrint('Error getting nearby bookstores: $e');
      return [];
    }
  }

  /// Get mock bookstores based on major Indonesian cities
  List<Bookstore> _getMockBookstores(double userLat, double userLng, double radiusKm) {
    final List<Bookstore> allBookstores = [
      // Jakarta bookstores
      Bookstore(
        id: '1',
        name: 'Gramedia Matraman',
        address: 'Jl. Matraman Raya No.46, Jakarta Timur',
        latitude: -6.1851,
        longitude: 106.8614,
        type: BookstoreType.gramedia,
        phone: '+62 21 857 5353',
        openHours: '10:00 - 22:00',
      ),
      Bookstore(
        id: '2',
        name: 'Periplus Grand Indonesia',
        address: 'Grand Indonesia Mall, Jakarta Pusat',
        latitude: -6.1956,
        longitude: 106.8239,
        type: BookstoreType.periplus,
        phone: '+62 21 2358 0284',
        openHours: '10:00 - 22:00',
      ),
      Bookstore(
        id: '3',
        name: 'Gramedia Plaza Senayan',
        address: 'Plaza Senayan, Jakarta Selatan',
        latitude: -6.2295,
        longitude: 106.7983,
        type: BookstoreType.gramedia,
        phone: '+62 21 572 5656',
        openHours: '10:00 - 22:00',
      ),
      Bookstore(
        id: '4',
        name: 'Kinokuniya Plaza Senayan',
        address: 'Plaza Senayan, Jakarta Selatan',
        latitude: -6.2290,
        longitude: 106.7990,
        type: BookstoreType.kinokuniya,
        phone: '+62 21 572 5501',
        openHours: '10:00 - 22:00',
      ),
      
      // Bandung bookstores
      Bookstore(
        id: '5',
        name: 'Gramedia Paris Van Java',
        address: 'Paris Van Java Mall, Bandung',
        latitude: -6.8951,
        longitude: 107.5644,
        type: BookstoreType.gramedia,
        phone: '+62 22 8205 7900',
        openHours: '10:00 - 22:00',
      ),
      Bookstore(
        id: '6',
        name: 'Periplus Bandung Indah Plaza',
        address: 'Bandung Indah Plaza, Bandung',
        latitude: -6.8648,
        longitude: 107.5845,
        type: BookstoreType.periplus,
        phone: '+62 22 7313 888',
        openHours: '10:00 - 22:00',
      ),
      
      // Surabaya bookstores
      Bookstore(
        id: '7',
        name: 'Gramedia Tunjungan Plaza',
        address: 'Tunjungan Plaza, Surabaya',
        latitude: -7.2675,
        longitude: 112.7369,
        type: BookstoreType.gramedia,
        phone: '+62 31 531 8008',
        openHours: '10:00 - 22:00',
      ),
      Bookstore(
        id: '8',
        name: 'Periplus Pakuwon Mall',
        address: 'Pakuwon Mall, Surabaya',
        latitude: -7.3297,
        longitude: 112.6778,
        type: BookstoreType.periplus,
        phone: '+62 31 7345 678',
        openHours: '10:00 - 22:00',
      ),
      
      // Medan bookstores
      Bookstore(
        id: '9',
        name: 'Gramedia Centre Point Medan',
        address: 'Centre Point Medan, Medan',
        latitude: 3.5952,
        longitude: 98.6722,
        type: BookstoreType.gramedia,
        phone: '+62 61 4577 890',
        openHours: '10:00 - 22:00',
      ),
      
      // Yogyakarta bookstores
      Bookstore(
        id: '10',
        name: 'Gramedia Malioboro',
        address: 'Jl. Malioboro No.52-58, Yogyakarta',
        latitude: -7.7951,
        longitude: 110.3655,
        type: BookstoreType.gramedia,
        phone: '+62 274 566 766',
        openHours: '09:00 - 22:00',
      ),
      Bookstore(
        id: '11',
        name: 'Togamas Book Store',
        address: 'Jl. Prawirotaman, Yogyakarta',
        latitude: -7.8034,
        longitude: 110.3660,
        type: BookstoreType.other,
        phone: '+62 274 376 743',
        openHours: '08:00 - 21:00',
      ),
      
      // Denpasar (Bali) bookstores
      Bookstore(
        id: '12',
        name: 'Gramedia Denpasar',
        address: 'Level 21 Mall, Denpasar',
        latitude: -8.6705,
        longitude: 115.2126,
        type: BookstoreType.gramedia,
        phone: '+62 361 234 567',
        openHours: '10:00 - 22:00',
      ),
      Bookstore(
        id: '13',
        name: 'Periplus Bali Collection',
        address: 'Bali Collection, Nusa Dua',
        latitude: -8.8019,
        longitude: 115.2304,
        type: BookstoreType.periplus,
        phone: '+62 361 771 662',
        openHours: '10:00 - 22:00',
      ),
    ];

    // Filter bookstores within radius
    return allBookstores.where((bookstore) {
      final distance = _calculateDistance(
        userLat, userLng,
        bookstore.latitude, bookstore.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculate distance between two points in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get bookstores from Google Places API (requires API key)
  Future<List<Bookstore>> _getBookstoresFromGooglePlaces(double latitude, double longitude, double radiusKm) async {
    if (_googleMapsApiKey == 'AIzaSyBD7khB3Zvf5LaIh0iWMc_Xn-oXVEo1kCM') {
      return []; // Return empty if no API key
    }

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$latitude,$longitude'
          '&radius=${radiusKm * 1000}' // Convert to meters
          '&type=book_store'
          '&keyword=gramedia|periplus|bookstore'
          '&key=$_googleMapsApiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        
        return results.map((place) {
          final location = place['geometry']['location'];
          return Bookstore(
            id: place['place_id'],
            name: place['name'],
            address: place['vicinity'] ?? 'Address not available',
            latitude: location['lat'].toDouble(),
            longitude: location['lng'].toDouble(),
            type: _determineBookstoreType(place['name']),
            phone: '', // Would need Place Details API for phone
            openHours: place['opening_hours']?['open_now'] == true ? 'Open' : 'Closed',
            rating: place['rating']?.toDouble(),
            photoReference: place['photos']?.isNotEmpty == true ? place['photos'][0]['photo_reference'] : null,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching from Google Places: $e');
    }
    
    return [];
  }

  BookstoreType _determineBookstoreType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('gramedia')) {
      return BookstoreType.gramedia;
    } else if (lowerName.contains('periplus')) {
      return BookstoreType.periplus;
    } else if (lowerName.contains('kinokuniya')) {
      return BookstoreType.kinokuniya;
    } else {
      return BookstoreType.other;
    }
  }

  /// Get directions URL to a bookstore
  String getDirectionsUrl(double destLat, double destLng) {
    if (_currentPosition != null) {
      return 'https://www.google.com/maps/dir/${_currentPosition!.latitude},${_currentPosition!.longitude}/$destLat,$destLng';
    } else {
      return 'https://www.google.com/maps/search/$destLat,$destLng';
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

class Bookstore {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final BookstoreType type;
  final String phone;
  final String openHours;
  final double? rating;
  final String? photoReference;

  Bookstore({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.phone,
    required this.openHours,
    this.rating,
    this.photoReference,
  });

  String get iconPath {
    switch (type) {
      case BookstoreType.gramedia:
        return 'assets/images/gramedia_icon.png'; // Add your own icons
      case BookstoreType.periplus:
        return 'assets/images/periplus_icon.png';
      case BookstoreType.kinokuniya:
        return 'assets/images/kinokuniya_icon.png';
      case BookstoreType.other:
        return 'assets/images/bookstore_icon.png';
    }
  }

  Color get brandColor {
    switch (type) {
      case BookstoreType.gramedia:
        return Colors.red;
      case BookstoreType.periplus:
        return Colors.blue;
      case BookstoreType.kinokuniya:
        return Colors.orange;
      case BookstoreType.other:
        return Colors.green;
    }
  }

  double distanceFrom(double lat, double lng) {
    const double earthRadius = 6371;
    
    final double dLat = (latitude - lat) * (pi / 180);
    final double dLng = (longitude - lng) * (pi / 180);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * (pi / 180)) * cos(latitude * (pi / 180)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
}

enum BookstoreType {
  gramedia,
  periplus,
  kinokuniya,
  other,
}