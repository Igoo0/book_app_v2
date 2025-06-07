 import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/book.dart';
import '../../models/search_history.dart';
import '../../services/books_api_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../database/database_service.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Book> _searchResults = [];
  List<SearchHistory> _searchHistory = [];
  List<String> _suggestions = [];
  
  bool _isLoading = false;
  bool _hasSearched = false;
  int? _currentUserId;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Fiction',
    'Non-fiction',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Fantasy',
    'Biography',
    'History',
    'Self-help',
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      _currentUserId = user.id;
      final history = await DatabaseService.instance.getSearchHistoryByUserId(
        user.id!,
        limit: 10,
      );
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final categories = await BooksApiService.getBookCategories();
      setState(() {
        _suggestions = categories.take(8).toList();
      });
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }

  Future<void> _performSearch({String? query}) async {
    final searchQuery = query ?? _searchController.text.trim();
    if (searchQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      List<Book> results;
      
      if (_selectedCategory == 'All') {
        results = await BooksApiService.searchBooks(
          query: searchQuery,
          maxResults: 30,
        );
      } else {
        results = await BooksApiService.searchBooks(
          query: '$searchQuery subject:${_selectedCategory.toLowerCase()}',
          maxResults: 30,
        );
      }

      // Save search to history
      if (_currentUserId != null) {
        final searchHistory = SearchHistory(
          userId: _currentUserId!,
          query: searchQuery,
          searchedAt: DateTime.now(),
        );
        await DatabaseService.instance.insertSearchHistory(searchHistory);
        _loadSearchHistory(); // Refresh history
      }

      // Show notification
      await NotificationService.instance.showSearchResultNotification(
        resultCount: results.length,
        query: searchQuery,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // Unfocus search field
      _searchFocusNode.unfocus();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearSearchHistory() async {
    if (_currentUserId != null) {
      await DatabaseService.instance.deleteSearchHistory(_currentUserId!);
      setState(() {
        _searchHistory = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search history cleared'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
      _selectedCategory = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Search Books'),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasSearched)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.indigo[800],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search for books, authors, ISBN...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (value) => _performSearch(),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Category filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            if (_searchController.text.isNotEmpty) {
                              _performSearch();
                            }
                          },
                          selectedColor: Colors.white,
                          backgroundColor: Colors.indigo[600],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.indigo[800] : Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched
                    ? _buildSearchResults()
                    : _buildSearchSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No books found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or categories',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: book.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: book.thumbnail!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.book, size: 20),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.book, size: 20),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.book, size: 20),
                      ),
              ),
            ),
            title: Text(
              book.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  book.authorsString,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.averageRating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        book.averageRating!.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BookDetailScreen(book: book),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search history
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._searchHistory.map((search) => ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(search.query),
              subtitle: Text(
                'Searched ${_getTimeAgo(search.searchedAt)}',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                _searchController.text = search.query;
                _performSearch(query: search.query);
              },
            )).toList(),
            const SizedBox(height: 24),
          ],

          // Popular categories
          const Text(
            'Popular Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion),
                onPressed: () {
                  _searchController.text = suggestion;
                  _performSearch(query: suggestion);
                },
                backgroundColor: Colors.indigo[50],
                labelStyle: TextStyle(color: Colors.indigo[800]),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Search tips
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.indigo[800]),
                      const SizedBox(width: 8),
                      Text(
                        'Search Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Search by title, author, or ISBN\n'
                    '• Use quotes for exact phrases\n'
                    '• Try different categories for better results\n'
                    '• Shake your device for random suggestions!',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
