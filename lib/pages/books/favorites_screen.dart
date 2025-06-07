import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/favorite.dart';
import '../../models/book.dart';
import '../../services/auth_service.dart';
import '../../services/books_api_service.dart';
import '../../database/database_service.dart';
import 'book_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSearch;
  
  const FavoritesScreen({
    super.key,
    this.onNavigateToSearch,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Favorite> _favorites = [];
  bool _isLoading = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await AuthService.getCurrentUser();
      if (user != null && user.id != null) {
        _currentUserId = user.id;
        final favorites = await DatabaseService.instance.getFavoritesByUserId(user.id!);
        if (mounted) {
          setState(() {
            _favorites = favorites;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error loading favorites: ${e.toString()}');
      }
    }
  }

  Future<void> _removeFavorite(Favorite favorite) async {
    if (_currentUserId == null || !mounted) return;

    try {
      await DatabaseService.instance.deleteFavorite(
        _currentUserId!,
        favorite.bookId,
      );
      
      if (mounted) {
        setState(() {
          _favorites.removeWhere((f) => f.id == favorite.id);
        });

        _showSuccessSnackBar('Removed from favorites');
      }
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      if (mounted) {
        _showErrorSnackBar('Error removing favorite: ${e.toString()}');
      }
    }
  }

  Future<void> _openBookDetail(Favorite favorite) async {
    if (!mounted) return;

    try {
      // Try to get full book details from API
      final book = await BooksApiService.getBookById(favorite.bookId);
      
      if (book != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(book: book),
          ),
        );
        // Refresh favorites when returning from book detail
        if (mounted) {
          _loadFavorites();
        }
      } else {
        // Fallback: create a basic book object from favorite data
        final book = Book(
          id: favorite.bookId,
          title: favorite.bookTitle,
          authors: favorite.bookAuthors.split(', '),
          thumbnail: favorite.bookThumbnail,
          categories: [],
          industryIdentifiers: [],
        );
        
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
          if (mounted) {
            _loadFavorites();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading book details: $e');
      if (mounted) {
        _showErrorSnackBar('Error loading book details: ${e.toString()}');
      }
    }
  }

  Future<void> _clearAllFavorites() async {
    if (_currentUserId == null || _favorites.isEmpty || !mounted) return;

    final confirmed = await _showConfirmationDialog(
      title: 'Clear All Favorites',
      content: 'Are you sure you want to remove all books from your favorites? This action cannot be undone.',
      confirmText: 'Clear All',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        // Remove all favorites for the current user
        for (final favorite in _favorites) {
          await DatabaseService.instance.deleteFavorite(
            _currentUserId!,
            favorite.bookId,
          );
        }

        if (mounted) {
          setState(() {
            _favorites.clear();
          });
          _showSuccessSnackBar('All favorites cleared');
        }
      } catch (e) {
        debugPrint('Error clearing favorites: $e');
        if (mounted) {
          _showErrorSnackBar('Error clearing favorites: ${e.toString()}');
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) async {
    if (!mounted) return null;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive 
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToSearch() {
    if (widget.onNavigateToSearch != null) {
      // Use the callback provided by parent
      widget.onNavigateToSearch!();
    } else {
      // Try to use DefaultTabController if available
      try {
        final tabController = DefaultTabController.of(context);
        tabController.animateTo(1);
      } catch (e) {
        debugPrint('Error navigating to search: $e');
        _showInfoSnackBar('Please navigate to the search tab manually');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Favorites'),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_favorites.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllFavorites();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
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
          Text('Loading your favorites...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_favorites.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: Column(
        children: [
          // Stats header
          Container(
            width: double.infinity,
            color: Colors.indigo[800],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.red[300],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_favorites.length} favorite ${_favorites.length == 1 ? 'book' : 'books'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Favorites list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final favorite = _favorites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Dismissible(
                    key: Key('favorite_${favorite.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await _showConfirmationDialog(
                        title: 'Remove Favorite',
                        content: 'Remove "${favorite.bookTitle}" from your favorites?',
                        confirmText: 'Remove',
                        isDestructive: true,
                      );
                    },
                    onDismissed: (direction) {
                      _removeFavorite(favorite);
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: _buildBookThumbnail(favorite.bookThumbnail),
                      title: Text(
                        favorite.bookTitle,
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
                            favorite.bookAuthors,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Added ${_getTimeAgo(favorite.addedAt)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Colors.red[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _openBookDetail(favorite),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookThumbnail(String? thumbnailUrl) {
    return Container(
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
        child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: thumbnailUrl,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding books to your favorites\nby tapping the heart icon',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToSearch,
            icon: const Icon(Icons.search),
            label: const Text('Discover Books'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }
}