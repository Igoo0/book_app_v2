import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/book.dart';
import '../../models/favorite.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../database/database_service.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isFavorite = false;
  bool _isLoading = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      _currentUserId = user.id;
      final isFavorite = await DatabaseService.instance.isFavorite(
        user.id!,
        widget.book.id,
      );
      setState(() {
        _isFavorite = isFavorite;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFavorite) {
        // Remove from favorites
        await DatabaseService.instance.deleteFavorite(
          _currentUserId!,
          widget.book.id,
        );
        setState(() {
          _isFavorite = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Add to favorites
        final favorite = Favorite(
          userId: _currentUserId!,
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          bookAuthors: widget.book.authorsString,
          bookThumbnail: widget.book.thumbnail,
          addedAt: DateTime.now(),
        );
        
        await DatabaseService.instance.insertFavorite(favorite);
        setState(() {
          _isFavorite = true;
        });

        // Show notification
        await NotificationService.instance.showFavoriteAddedNotification(
          bookTitle: widget.book.title,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openPreviewLink() async {
    if (widget.book.previewLink != null) {
      final Uri url = Uri.parse(widget.book.previewLink!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open preview link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openInfoLink() async {
    if (widget.book.infoLink != null) {
      final Uri url = Uri.parse(widget.book.infoLink!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open info link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App bar with book cover
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.indigo[800],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.indigo[800]!,
                      Colors.indigo[600]!,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Book cover
                      Container(
                        height: 180,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.book.thumbnail != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.book.thumbnail!,
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
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _isLoading ? null : _toggleFavorite,
              ),
            ],
          ),

          // Book details
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and author
                    Text(
                      widget.book.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'by ${widget.book.authorsString}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rating and info row
                    Row(
                      children: [
                        if (widget.book.averageRating != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.book.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.book.ratingsCount != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(${widget.book.ratingsCount})',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (widget.book.pageCount != null) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book,
                                color: Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.book.pageCount} pages',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Categories
                    if (widget.book.categories.isNotEmpty) ...[
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.book.categories.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.indigo[200]!),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Colors.indigo[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description
                    if (widget.book.description != null) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.book.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Publication info
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Publication Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (widget.book.publisher != null) ...[
                              _buildInfoRow('Publisher', widget.book.publisher!),
                            ],
                            if (widget.book.publishedDate != null) ...[
                              _buildInfoRow('Published', widget.book.publishedDate!),
                            ],
                            if (widget.book.language != null) ...[
                              _buildInfoRow('Language', widget.book.language!.toUpperCase()),
                            ],
                            if (widget.book.industryIdentifiers.isNotEmpty) ...[
                              _buildInfoRow('ISBN', widget.book.industryIdentifiers.first),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        if (widget.book.previewLink != null) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openPreviewLink,
                              icon: const Icon(Icons.preview),
                              label: const Text('Preview'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (widget.book.infoLink != null) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openInfoLink,
                              icon: const Icon(Icons.info_outline),
                              label: const Text('More Info'),
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

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
