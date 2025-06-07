class Favorite {
  final int? id;
  final int userId;
  final String bookId;
  final String bookTitle;
  final String bookAuthors;
  final String? bookThumbnail;
  final DateTime addedAt;

  Favorite({
    this.id,
    required this.userId,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthors,
    this.bookThumbnail,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'book_title': bookTitle,
      'book_authors': bookAuthors,
      'book_thumbnail': bookThumbnail,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      bookId: map['book_id'] ?? '',
      bookTitle: map['book_title'] ?? '',
      bookAuthors: map['book_authors'] ?? '',
      bookThumbnail: map['book_thumbnail'],
      addedAt: DateTime.parse(map['added_at']),
    );
  }

  @override
  String toString() {
    return 'Favorite(id: $id, userId: $userId, bookId: $bookId, bookTitle: $bookTitle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Favorite &&
        other.userId == userId &&
        other.bookId == bookId;
  }

  @override
  int get hashCode => userId.hashCode ^ bookId.hashCode;
}