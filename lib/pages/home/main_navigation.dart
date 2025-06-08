import 'package:flutter/material.dart';
import '../../services/sensor_service.dart';
import '../../services/notification_service.dart';
import '../../services/books_api_service.dart';
import '../books/home_screen.dart';
import '../books/search_screen.dart';
import '../books/favorites_screen.dart';
import '../books/map_screen.dart';
import '../tools/tools_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const FavoritesScreen(),
    const MapScreen(), // Added map screen
    const ToolsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSensors();
  }

  void _initializeSensors() async {
    // Initialize sensor service for shake detection
    final sensorService = SensorService.instance;
    
    // Check if sensors are available
    final sensorsAvailable = await sensorService.areSensorsAvailable();
    if (sensorsAvailable) {
      // Set shake callback
      sensorService.setShakeCallback(() {
        _onShakeDetected();
      });
      
      // Start listening to accelerometer
      sensorService.startAccelerometerListening();
    }
  }

  void _onShakeDetected() async {
    // Show notification
    await NotificationService.instance.showShakeDetectedNotification();
    
    // Show random book suggestions
    _showRandomBookSuggestions();
  }

  void _showRandomBookSuggestions() async {
    try {
      final categories = ['fiction', 'mystery', 'romance', 'science', 'history'];
      final randomCategory = categories[DateTime.now().millisecond % categories.length];
      
      final books = await BooksApiService.searchBooksByCategory(
        category: randomCategory,
        maxResults: 3,
      );

      if (mounted && books.isNotEmpty) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.shuffle, color: Colors.indigo[800]),
                    const SizedBox(width: 8),
                    Text(
                      'Shake Suggestions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Random books from $randomCategory category:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ...books.take(3).map((book) => ListTile(
                  leading: book.thumbnail != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            book.thumbnail!,
                            width: 40,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.book),
                          ),
                        )
                      : const Icon(Icons.book),
                  title: Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    book.authorsString,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to book details
                  },
                )).toList(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing random suggestions: $e');
    }
  }

  @override
  void dispose() {
    // Stop sensor listening
    SensorService.instance.stopAllSensors();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.indigo[800],
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: 'Tools',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 1; // Go to search
          });
        },
        backgroundColor: Colors.indigo[800],
        child: const Icon(Icons.search, color: Colors.white),
      ) : null,
    );
  }
}