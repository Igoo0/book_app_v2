import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/book.dart';
import '../../services/books_api_service.dart';
import '../../services/auth_service.dart';
import 'book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _popularBooks = [];
  List<Book> _newReleases = [];
  List<Book> _fictionBooks = [];
  List<Book> _nonFictionBooks = [];
  
  bool _isLoading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        _username = user.username;
      }

      // Load books concurrently
      final results = await Future.wait([
        BooksApiService.getPopularBooks(maxResults: 10),
        BooksApiService.getNewReleases(maxResults: 10),
        BooksApiService.getFictionBooks(maxResults: 8),
        BooksApiService.getNonFictionBooks(maxResults: 8),
      ]);

      setState(() {
        _popularBooks = results[0];
        _newReleases = results[1];
        _fictionBooks = results[2];
        _nonFictionBooks = results[3];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your library...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.indigo[800],
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $_username!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Text(
                    'BookVerse',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // TODO: Show notifications
                },
              ),
            ],
          ),

          // Content
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),

              // Featured section
              if (_popularBooks.isNotEmpty) ...[
                _buildSectionHeader('Featured Books', 'Popular picks for you'),
                const SizedBox(height: 12),
                _buildHorizontalBookList(_popularBooks),
                const SizedBox(height: 24),
              ],

              // New releases section
              if (_newReleases.isNotEmpty) ...[
                _buildSectionHeader('New Releases', 'Latest books just arrived'),
                const SizedBox(height: 12),
                _buildHorizontalBookList(_newReleases),
                const SizedBox(height: 24),
              ],

              // Categories section
              _buildSectionHeader('Categories', 'Explore by genre'),
              const SizedBox(height: 12),
              _buildCategoriesGrid(),
              const SizedBox(height: 24),

              // Fiction section
              if (_fictionBooks.isNotEmpty) ...[
                _buildSectionHeader('Fiction', 'Dive into amazing stories'),
                const SizedBox(height: 12),
                _buildHorizontalBookList(_fictionBooks),
                const SizedBox(height: 24),
              ],

              // Non-fiction section
              if (_nonFictionBooks.isNotEmpty) ...[
                _buildSectionHeader('Non-Fiction', 'Learn something new'),
                const SizedBox(height: 12),
                _buildHorizontalBookList(_nonFictionBooks),
                const SizedBox(height: 24),
              ],

              // Bottom padding
              const SizedBox(height: 80),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalBookList(List<Book> books) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(book: book),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book cover
                  Container(
                    height: 160,
                    width: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: book.thumbnail != null
                          ? CachedNetworkImage(
                              imageUrl: book.thumbnail!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.book,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.book,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Book title
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Author
                  Text(
                    book.authorsString,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'name': 'Fiction', 'icon': Icons.auto_stories, 'color': Colors.blue},
      {'name': 'Non-Fiction', 'icon': Icons.science, 'color': Colors.green},
      {'name': 'Mystery', 'icon': Icons.search, 'color': Colors.purple},
      {'name': 'Romance', 'icon': Icons.favorite, 'color': Colors.pink},
      {'name': 'Sci-Fi', 'icon': Icons.rocket_launch, 'color': Colors.orange},
      {'name': 'Biography', 'icon': Icons.person, 'color': Colors.teal},
    ];

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              // TODO: Navigate to category books
            },
            child: Container(
              decoration: BoxDecoration(
                color: (category['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (category['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: category['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 
