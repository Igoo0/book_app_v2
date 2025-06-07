 class SearchHistory {
  final int? id;
  final int userId;
  final String query;
  final DateTime searchedAt;

  SearchHistory({
    this.id,
    required this.userId,
    required this.query,
    required this.searchedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'query': query,
      'searched_at': searchedAt.toIso8601String(),
    };
  }

  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    return SearchHistory(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      query: map['query'] ?? '',
      searchedAt: DateTime.parse(map['searched_at']),
    );
  }

  @override
  String toString() {
    return 'SearchHistory(id: $id, userId: $userId, query: $query, searchedAt: $searchedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchHistory &&
        other.id == id &&
        other.userId == userId &&
        other.query == query;
  }

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ query.hashCode;
}
