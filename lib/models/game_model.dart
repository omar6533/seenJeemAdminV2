class GameModel {
  final String id;
  final String userId;
  final String categoryId;
  final int score;
  final int totalQuestions;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;

  GameModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.score,
    required this.totalQuestions,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory GameModel.fromFirestore(Map<String, dynamic> data, String id) {
    return GameModel(
      id: id,
      userId: data['userId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      score: (data['score'] is int) 
          ? data['score'] 
          : (data['score'] is num) 
              ? data['score'].toInt() 
              : 0,
      totalQuestions: (data['totalQuestions'] is int) 
          ? data['totalQuestions'] 
          : (data['totalQuestions'] is num) 
              ? data['totalQuestions'].toInt() 
              : 0,
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'score': score,
      'totalQuestions': totalQuestions,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
