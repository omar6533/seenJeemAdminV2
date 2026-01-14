import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
import '../models/game_model.dart';
import '../models/payment_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<UserModel>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addUser(UserModel user) async {
    await _db.collection('users').add(user.toFirestore());
  }

  Future<void> updateUser(String id, UserModel user) async {
    await _db.collection('users').doc(id).update(user.toFirestore());
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }

  Stream<List<CategoryModel>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addCategory(CategoryModel category) async {
    await _db.collection('categories').add(category.toFirestore());
  }

  Future<void> updateCategory(String id, CategoryModel category) async {
    await _db.collection('categories').doc(id).update(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  Stream<List<QuestionModel>> getQuestions() {
    return _db.collection('questions').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => QuestionModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addQuestion(QuestionModel question) async {
    await _db.collection('questions').add(question.toFirestore());
  }

  Future<void> updateQuestion(String id, QuestionModel question) async {
    await _db.collection('questions').doc(id).update(question.toFirestore());
  }

  Future<void> deleteQuestion(String id) async {
    await _db.collection('questions').doc(id).delete();
  }

  Stream<List<GameModel>> getGames() {
    return _db.collection('games').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => GameModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addGame(GameModel game) async {
    await _db.collection('games').add(game.toFirestore());
  }

  Future<void> updateGame(String id, GameModel game) async {
    await _db.collection('games').doc(id).update(game.toFirestore());
  }

  Future<void> deleteGame(String id) async {
    await _db.collection('games').doc(id).delete();
  }

  Stream<List<PaymentModel>> getPayments() {
    return _db.collection('payments').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => PaymentModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addPayment(PaymentModel payment) async {
    await _db.collection('payments').add(payment.toFirestore());
  }

  Future<void> updatePayment(String id, PaymentModel payment) async {
    await _db.collection('payments').doc(id).update(payment.toFirestore());
  }

  Future<void> deletePayment(String id) async {
    await _db.collection('payments').doc(id).delete();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Use timeout for each query to prevent hanging
      final futures = await Future.wait([
        _db.collection('users').get().timeout(const Duration(seconds: 5)),
        _db.collection('games').get().timeout(const Duration(seconds: 5)),
        _db.collection('questions').get().timeout(const Duration(seconds: 5)),
        _db.collection('payments').get().timeout(const Duration(seconds: 5)),
      ]);

      final usersSnapshot = futures[0];
      final gamesSnapshot = futures[1];
      final questionsSnapshot = futures[2];
      final paymentsSnapshot = futures[3];

      double totalRevenue = 0.0;
      for (var doc in paymentsSnapshot.docs) {
        try {
          final payment = PaymentModel.fromFirestore(doc.data(), doc.id);
          if (payment.status == 'completed') {
            totalRevenue += payment.amount;
          }
        } catch (e) {
          // Skip invalid payment documents
          continue;
        }
      }

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalGames': gamesSnapshot.docs.length,
        'totalQuestions': questionsSnapshot.docs.length,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      // Return zero values if there's an error
      return {
        'totalUsers': 0,
        'totalGames': 0,
        'totalQuestions': 0,
        'totalRevenue': 0.0,
      };
    }
  }
}
