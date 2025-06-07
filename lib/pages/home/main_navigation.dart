import 'package:flutter/material.dart';
import '../../services/sensor_service.dart';
import '../../services/notification_service.dart';
import '../../services/books_api_service.dart';
import '../books/home_screen.dart';
import '../books/search_screen.dart';
import '../books/favorites_screen.dart';
import '../tools/tools_screen.dart';
import '../profile/profile_screen.dart';
import '../books/book_detail_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _sensorsAvailable = false;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    const SearchScreen(),
    const FavoritesScreen(),
    const ToolsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSensors();
  }

  void _initializeSensors() async {
    try {
      debugPrint('Initializing sensors...');
      
      // Initialize sensor service for shake detection
      final sensorService = SensorService.instance;
      
      // Check if sensors are available
      final sensorsAvailable = await sensorService.areSensorsAvailable();
      debugPrint('Sensors available: $sensorsAvailable');
      
      setState(() {
        _sensorsAvailable = sensorsAvailable;
      });
      
      if (sensorsAvailable) {
        // Set shake callback
        sensorService.setShakeCallback(() {
          debugPrint('Shake detected in main navigation!');
          _onShakeDetected();
        });
        
        // Start listening to accelerometer
        sensorService.startAccelerometerListening();
        debugPrint('Started accelerometer listening');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shake detection enabled! Shake your phone for book suggestions.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('Sensors not available on this device');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Shake detection not available on this device'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing sensors: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing shake detection: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onShakeDetected() async {
    try {
      debugPrint('Processing shake detection...');
      
      // Show notification
      await NotificationService.instance.showShakeDetectedNotification();
      
      // Show random book suggestions
      _showRandomBookSuggestions();
      
    } catch (e) {
      debugPrint('Error in shake detection handler: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing shake: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRandomBookSuggestions() async {
    try {
      debugPrint('Fetching random book suggestions...');
      
      final categories = ['fiction', 'mystery', 'romance', 'science', 'history', 'biography', 'fantasy'];
      final randomCategory = categories[DateTime.now().millisecond % categories.length];
      
      debugPrint('Selected category: $randomCategory');
      
      final books = await BooksApiService.searchBooksByCategory(
        category: randomCategory,
        maxResults: 5,
      );

      debugPrint('Found ${books.length} books');

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
                    Expanded(
                      child: Text(
                        'Shake Suggestions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[800],
                        ),
                        overflow: TextOverflow.ellipsis,
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
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: books.take(3).length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
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
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BookDetailScreen(book: book),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRandomBookSuggestions(); // Get new suggestions
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[800],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('More'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No book suggestions found. Try again!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error showing random suggestions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading suggestions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Manual test button for shake functionality
  void _testShakeFunction() {
    debugPrint('Manual shake test triggered');
    _onShakeDetected();
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
      floatingActionButton: _currentIndex == 0 
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Test shake button (for debugging)
                if (!_sensorsAvailable)
                  FloatingActionButton(
                    onPressed: _testShakeFunction,
                    backgroundColor: Colors.orange,
                    heroTag: "test_shake",
                    mini: true,
                    child: const Icon(Icons.shuffle, color: Colors.white),
                  ),
                if (!_sensorsAvailable) const SizedBox(height: 8),
                // Search button
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1; // Go to search
                    });
                  },
                  backgroundColor: Colors.indigo[800],
                  heroTag: "search",
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ],
            ) 
          : null,
    );
  }
}