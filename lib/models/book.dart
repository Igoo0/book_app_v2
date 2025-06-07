class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String? description;
  final String? thumbnail;
  final String? publishedDate;
  final String? publisher;
  final int? pageCount;
  final List<String> categories;
  final double? averageRating;
  final int? ratingsCount;
  final String? previewLink;
  final String? infoLink;
  final List<String> industryIdentifiers;
  final String? language;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    this.description,
    this.thumbnail,
    this.publishedDate,
    this.publisher,
    this.pageCount,
    required this.categories,
    this.averageRating,
    this.ratingsCount,
    this.previewLink,
    this.infoLink,
    required this.industryIdentifiers,
    this.language,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final imageLinks = volumeInfo['imageLinks'] ?? {};
    final industryIds = volumeInfo['industryIdentifiers'] as List? ?? [];

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Unknown Title',
      authors: List<String>.from(volumeInfo['authors'] ?? ['Unknown Author']),
      description: volumeInfo['description'],
      thumbnail: imageLinks['thumbnail'] ?? imageLinks['smallThumbnail'],
      publishedDate: volumeInfo['publishedDate'],
      publisher: volumeInfo['publisher'],
      pageCount: volumeInfo['pageCount'],
      categories: List<String>.from(volumeInfo['categories'] ?? ['General']),
      averageRating: volumeInfo['averageRating']?.toDouble(),
      ratingsCount: volumeInfo['ratingsCount'],
      previewLink: volumeInfo['previewLink'],
      infoLink: volumeInfo['infoLink'],
      industryIdentifiers: industryIds.map((id) => id['identifier'].toString()).toList(),
      language: volumeInfo['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'authors': authors.join(', '),
      'description': description,
      'thumbnail': thumbnail,
      'published_date': publishedDate,
      'publisher': publisher,
      'page_count': pageCount,
      'categories': categories.join(', '),
      'average_rating': averageRating,
      'ratings_count': ratingsCount,
      'preview_link': previewLink,
      'info_link': infoLink,
      'industry_identifiers': industryIdentifiers.join(', '),
      'language': language,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      authors: (map['authors'] ?? '').split(', ').where((s) => s.isNotEmpty).toList(),
      description: map['description'],
      thumbnail: map['thumbnail'],
      publishedDate: map['published_date'],
      publisher: map['publisher'],
      pageCount: map['page_count']?.toInt(),
      categories: (map['categories'] ?? '').split(', ').where((s) => s.isNotEmpty).toList(),
      averageRating: map['average_rating']?.toDouble(),
      ratingsCount: map['ratings_count']?.toInt(),
      previewLink: map['preview_link'],
      infoLink: map['info_link'],
      industryIdentifiers: (map['industry_identifiers'] ?? '').split(', ').where((s) => s.isNotEmpty).toList(),
      language: map['language'],
    );
  }

  String get authorsString => authors.join(', ');
  String get categoriesString => categories.join(', ');
  String get shortDescription => description != null && description!.length > 200 
      ? '${description!.substring(0, 200)}...' 
      : description ?? 'No description available';

  @override
  String toString() {
    return 'Book(id: $id, title: $title, authors: $authors)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}