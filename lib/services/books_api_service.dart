import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BooksApiService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const String _apiKey = 'AIzaSyBD7khB3Zvf5LaIh0iWMc_Xn-oXVEo1kCM'; // Replace with actual API key

  static Future<List<Book>> searchBooks({
    required String query,
    int maxResults = 20,
    int startIndex = 0,
    String orderBy = 'relevance',
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query,
        'maxResults': maxResults.toString(),
        'startIndex': startIndex.toString(),
        'orderBy': orderBy,
        if (_apiKey.isNotEmpty) 'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        
        return items.map((item) => Book.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching books: $e');
    }
  }

  static Future<List<Book>> searchBooksByCategory({
    required String category,
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    return searchBooks(
      query: 'subject:$category',
      maxResults: maxResults,
      startIndex: startIndex,
    );
  }

  static Future<List<Book>> searchBooksByAuthor({
    required String author,
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    return searchBooks(
      query: 'inauthor:$author',
      maxResults: maxResults,
      startIndex: startIndex,
    );
  }

  static Future<Book?> getBookById(String bookId) async {
    try {
      final uri = Uri.parse('$_baseUrl/$bookId').replace(queryParameters: {
        if (_apiKey.isNotEmpty) 'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Book.fromJson(data);
      } else {
        throw Exception('Failed to load book: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching book: $e');
    }
  }

  static Future<List<Book>> getNewReleases({
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    final currentYear = DateTime.now().year;
    return searchBooks(
      query: 'publishedDate:$currentYear',
      maxResults: maxResults,
      startIndex: startIndex,
      orderBy: 'newest',
    );
  }

  static Future<List<Book>> getPopularBooks({
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    return searchBooks(
      query: 'bestseller',
      maxResults: maxResults,
      startIndex: startIndex,
      orderBy: 'relevance',
    );
  }

  static Future<List<Book>> getFictionBooks({
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    return searchBooksByCategory(
      category: 'fiction',
      maxResults: maxResults,
      startIndex: startIndex,
    );
  }

  static Future<List<Book>> getNonFictionBooks({
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    return searchBooksByCategory(
      category: 'nonfiction',
      maxResults: maxResults,
      startIndex: startIndex,
    );
  }

  static Future<List<Book>> searchBooksByISBN({
    required String isbn,
  }) async {
    return searchBooks(
      query: 'isbn:$isbn',
      maxResults: 10,
    );
  }

  static Future<List<String>> getBookCategories() async {
    // Return common book categories
    return [
      'Fiction',
      'Non-fiction',
      'Mystery',
      'Romance',
      'Science Fiction',
      'Fantasy',
      'Biography',
      'History',
      'Self-help',
      'Business',
      'Health',
      'Education',
      'Art',
      'Religion',
      'Travel',
      'Cooking',
      'Sports',
      'Technology',
      'Children',
      'Young Adult',
    ];
  }
} 
