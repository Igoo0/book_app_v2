import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final LocationService _locationService = LocationService.instance;
  
  Position? _currentPosition;
  List<Bookstore> _nearbyBookstores = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  String _selectedFilter = 'All';
  double _searchRadius = 10.0; // km

  final List<String> _filterOptions = ['All', 'Gramedia', 'Periplus', 'Kinokuniya', 'Others'];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permission
      _hasLocationPermission = await _locationService.checkLocationPermission();
      
      if (_hasLocationPermission) {
        // Get current location
        _currentPosition = await _locationService.getCurrentLocation();
        
        if (_currentPosition != null) {
          // Get nearby bookstores
          await _loadNearbyBookstores();
        }
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
      _showErrorSnackBar('Error loading map: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNearbyBookstores() async {
    if (_currentPosition == null) return;

    try {
      final bookstores = await _locationService.getNearbyBookstores(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        radiusKm: _searchRadius,
      );

      setState(() {
        _nearbyBookstores = bookstores;
      });

      _updateMapMarkers();
    } catch (e) {
      debugPrint('Error loading bookstores: $e');
      _showErrorSnackBar('Error loading bookstores: $e');
    }
  }

  void _updateMapMarkers() {
    Set<Marker> markers = {};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: _locationService.currentAddress ?? 'Current Position',
          ),
        ),
      );
    }

    // Add bookstore markers
    final filteredBookstores = _getFilteredBookstores();
    
    for (final bookstore in filteredBookstores) {
      markers.add(
        Marker(
          markerId: MarkerId(bookstore.id),
          position: LatLng(bookstore.latitude, bookstore.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(bookstore.type)),
          infoWindow: InfoWindow(
            title: bookstore.name,
            snippet: bookstore.address,
            onTap: () => _showBookstoreDetails(bookstore),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  List<Bookstore> _getFilteredBookstores() {
    if (_selectedFilter == 'All') {
      return _nearbyBookstores;
    }
    
    BookstoreType? filterType;
    switch (_selectedFilter) {
      case 'Gramedia':
        filterType = BookstoreType.gramedia;
        break;
      case 'Periplus':
        filterType = BookstoreType.periplus;
        break;
      case 'Kinokuniya':
        filterType = BookstoreType.kinokuniya;
        break;
      case 'Others':
        filterType = BookstoreType.other;
        break;
    }

    return _nearbyBookstores.where((bookstore) => bookstore.type == filterType).toList();
  }

  double _getMarkerHue(BookstoreType type) {
    switch (type) {
      case BookstoreType.gramedia:
        return BitmapDescriptor.hueRed;
      case BookstoreType.periplus:
        return BitmapDescriptor.hueBlue;
      case BookstoreType.kinokuniya:
        return BitmapDescriptor.hueOrange;
      case BookstoreType.other:
        return BitmapDescriptor.hueGreen;
    }
  }

  void _showBookstoreDetails(Bookstore bookstore) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BookstoreDetailsSheet(
        bookstore: bookstore,
        currentPosition: _currentPosition,
        onGetDirections: () => _getDirections(bookstore),
        onCall: () => _callBookstore(bookstore),
      ),
    );
  }

  Future<void> _getDirections(Bookstore bookstore) async {
    final url = _locationService.getDirectionsUrl(bookstore.latitude, bookstore.longitude);
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open directions');
    }
  }

  Future<void> _callBookstore(Bookstore bookstore) async {
    if (bookstore.phone.isNotEmpty) {
      final uri = Uri.parse('tel:${bookstore.phone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackBar('Could not make phone call');
      }
    } else {
      _showErrorSnackBar('Phone number not available');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Move camera to current location if available
    if (_currentPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          14.0,
        ),
      );
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoading = true;
    });

    await _initializeMap();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookstores'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filter options
            ..._filterOptions.map((filter) => RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
                _updateMapMarkers();
              },
            )).toList(),
            
            const Divider(),
            
            // Search radius
            Text('Search Radius: ${_searchRadius.toStringAsFixed(1)} km'),
            Slider(
              value: _searchRadius,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              onChanged: (value) {
                setState(() {
                  _searchRadius = value;
                });
              },
              onChangeEnd: (value) {
                _loadNearbyBookstores();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nearby Bookstores'),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading nearby bookstores...'),
                ],
              ),
            )
          : !_hasLocationPermission
              ? _buildLocationPermissionScreen()
              : _currentPosition == null
                  ? _buildLocationErrorScreen()
                  : _buildMapScreen(),
      floatingActionButton: _currentPosition != null
          ? FloatingActionButton(
              onPressed: () {
                _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    16.0,
                  ),
                );
              },
              backgroundColor: Colors.indigo[800],
              child: const Icon(Icons.my_location, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMapScreen() {
    return Column(
      children: [
        // Stats header
        Container(
          width: double.infinity,
          color: Colors.indigo[800],
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.store, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_getFilteredBookstores().length} bookstore(s) found',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_selectedFilter != 'All') ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedFilter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Map
        Expanded(
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(-6.2088, 106.8456), // Default to Jakarta
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
            buildingsEnabled: true,
            trafficEnabled: false,
          ),
        ),

        // Bookstore list
        if (_getFilteredBookstores().isNotEmpty) ...[
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: _getFilteredBookstores().length,
              itemBuilder: (context, index) {
                final bookstore = _getFilteredBookstores()[index];
                final distance = _currentPosition != null
                    ? bookstore.distanceFrom(_currentPosition!.latitude, _currentPosition!.longitude)
                    : 0.0;

                return Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 8),
                  child: Card(
                    child: InkWell(
                      onTap: () => _showBookstoreDetails(bookstore),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: bookstore.brandColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    bookstore.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookstore.address,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${distance.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.indigo[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  bookstore.openHours,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationPermissionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Location Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To find nearby bookstores, we need access to your location. Please grant location permission.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await _locationService.openAppSettings();
                _initializeMap();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_disabled,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Get Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Please make sure location services are enabled and try again.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await _locationService.openLocationSettings();
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Location Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800],
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _refreshLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BookstoreDetailsSheet extends StatelessWidget {
  final Bookstore bookstore;
  final Position? currentPosition;
  final VoidCallback onGetDirections;
  final VoidCallback onCall;

  const BookstoreDetailsSheet({
    super.key,
    required this.bookstore,
    this.currentPosition,
    required this.onGetDirections,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final distance = currentPosition != null
        ? bookstore.distanceFrom(currentPosition!.latitude, currentPosition!.longitude)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: bookstore.brandColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bookstore.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bookstore.address,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Distance and hours
                Row(
                  children: [
                    if (distance != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.directions_walk, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '${distance.toStringAsFixed(1)} km away',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          bookstore.openHours,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),

                if (bookstore.phone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        bookstore.phone,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],

                if (bookstore.rating != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 20, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        '${bookstore.rating!.toStringAsFixed(1)} stars',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onGetDirections();
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (bookstore.phone.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onCall();
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo[800],
                            side: BorderSide(color: Colors.indigo[800]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}