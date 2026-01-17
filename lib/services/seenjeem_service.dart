import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/main_category_model.dart';
import '../models/sub_category_model.dart';
import '../models/seenjeem_question_model.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';
import '../models/payment_model.dart';

class SeenjeemService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<MainCategoryModel>> getMainCategories() {
    return _db
        .collection('main_categories')
        .orderBy('display_order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MainCategoryModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<String> addMainCategory(MainCategoryModel category) async {
    final docRef =
        await _db.collection('main_categories').add(category.toFirestore());
    print(docRef);
    return docRef.id;
  }

  Future<void> updateMainCategory(String id, MainCategoryModel category) async {
    await _db
        .collection('main_categories')
        .doc(id)
        .update(category.toFirestore());
  }

  Future<void> deleteMainCategory(String id) async {
    await _db.collection('main_categories').doc(id).delete();
  }

  Stream<List<SubCategoryModel>> getSubCategories({String? mainCategoryId}) {
    Query query = _db.collection('sub_categories').orderBy('display_order');

    if (mainCategoryId != null && mainCategoryId.isNotEmpty) {
      query = query.where('main_category_id', isEqualTo: mainCategoryId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => SubCategoryModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<String> addSubCategory(SubCategoryModel category) async {
    final docRef =
        await _db.collection('sub_categories').add(category.toFirestore());
    return docRef.id;
  }

  Future<void> updateSubCategory(String id, SubCategoryModel category) async {
    await _db
        .collection('sub_categories')
        .doc(id)
        .update(category.toFirestore());
  }

  Future<void> deleteSubCategory(String id) async {
    await _db.collection('sub_categories').doc(id).delete();
  }

  Stream<List<SeenjeemQuestionModel>> getQuestions({
    String? subCategoryId,
    int? points,
    String? status,
  }) {
    Query query = _db.collection('questions');

    if (subCategoryId != null && subCategoryId.isNotEmpty) {
      query = query.where('sub_category_id', isEqualTo: subCategoryId);
    }

    if (points != null) {
      query = query.where('points', isEqualTo: points);
    }

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => SeenjeemQuestionModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<String> addQuestion(SeenjeemQuestionModel question) async {
    final exists = await _db
        .collection('questions')
        .where('sub_category_id', isEqualTo: question.subCategoryId)
        .where('points', isEqualTo: question.points)
        .get();

    if (exists.docs.isNotEmpty) {
      throw Exception(
          'A question with ${question.points} points already exists for this sub-category');
    }

    final docRef =
        await _db.collection('questions').add(question.toFirestore());
    return docRef.id;
  }

  Future<void> updateQuestion(String id, SeenjeemQuestionModel question) async {
    final exists = await _db
        .collection('questions')
        .where('sub_category_id', isEqualTo: question.subCategoryId)
        .where('points', isEqualTo: question.points)
        .get();

    if (exists.docs.isNotEmpty && exists.docs.first.id != id) {
      throw Exception(
          'A question with ${question.points} points already exists for this sub-category');
    }

    await _db.collection('questions').doc(id).update(question.toFirestore());
  }

  Future<void> deleteQuestion(String id) async {
    await _db.collection('questions').doc(id).delete();
  }

  Future<String> uploadMedia(
      Uint8List fileBytes, String fileName, String folder) async {
    try {
      final ref = _storage.ref().child('$folder/$fileName');
      final uploadTask = await ref.putData(fileBytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  Future<void> deleteMedia(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete media: $e');
    }
  }

  Stream<List<UserModel>> getUsers() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Stream<List<GameModel>> getGames() {
    return _db
        .collection('games')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GameModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<List<PaymentModel>> getPayments() {
    return _db
        .collection('payments')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final futures = await Future.wait([
        _db
            .collection('main_categories')
            .get()
            .timeout(const Duration(seconds: 5)),
        _db
            .collection('sub_categories')
            .get()
            .timeout(const Duration(seconds: 5)),
        _db.collection('questions').get().timeout(const Duration(seconds: 5)),
        _db
            .collection('questions')
            .where('status', isEqualTo: 'active')
            .get()
            .timeout(const Duration(seconds: 5)),
        _db.collection('users').get().timeout(const Duration(seconds: 5)),
        _db.collection('games').get().timeout(const Duration(seconds: 5)),
      ]);

      return {
        'totalMainCategories': futures[0].docs.length,
        'totalSubCategories': futures[1].docs.length,
        'totalQuestions': futures[2].docs.length,
        'activeQuestions': futures[3].docs.length,
        'totalUsers': futures[4].docs.length,
        'totalGames': futures[5].docs.length,
      };
    } catch (e) {
      return {
        'totalMainCategories': 0,
        'totalSubCategories': 0,
        'totalQuestions': 0,
        'activeQuestions': 0,
        'totalUsers': 0,
        'totalGames': 0,
      };
    }
  }

  // Future versions for pages that need them
  Future<List<MainCategoryModel>> getMainCategoriesFuture() async {
    final snapshot =
        await _db.collection('main_categories').orderBy('display_order').get();
    return snapshot.docs
        .map((doc) => MainCategoryModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<SubCategoryModel>> getSubCategoriesFuture(
      {String? mainCategoryId}) async {
    Query query = _db.collection('sub_categories').orderBy('display_order');

    if (mainCategoryId != null && mainCategoryId.isNotEmpty) {
      query = query.where('main_category_id', isEqualTo: mainCategoryId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => SubCategoryModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<SeenjeemQuestionModel>> getQuestionsFuture({
    String? mainCategoryId,
    String? subCategoryId,
    int? points,
    String? status,
    String? search,
  }) async {
    Query query = _db.collection('questions');

    if (subCategoryId != null && subCategoryId.isNotEmpty) {
      query = query.where('sub_category_id', isEqualTo: subCategoryId);
    }

    if (points != null) {
      query = query.where('points', isEqualTo: points);
    }

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    var questions = snapshot.docs
        .map((doc) => SeenjeemQuestionModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    // Filter by main category if needed (requires joining with sub_categories)
    if (mainCategoryId != null && mainCategoryId.isNotEmpty) {
      final subCats =
          await getSubCategoriesFuture(mainCategoryId: mainCategoryId);
      final subCatIds = subCats.map((cat) => cat.id).toSet();
      questions =
          questions.where((q) => subCatIds.contains(q.subCategoryId)).toList();
    }

    // Filter by search query if provided
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      questions = questions
          .where((q) =>
              q.questionTextAr.toLowerCase().contains(searchLower) ||
              q.answerTextAr.toLowerCase().contains(searchLower))
          .toList();
    }

    return questions;
  }

  Future<void> createQuestion(Map<String, dynamic> data) async {
    final question = SeenjeemQuestionModel(
      id: '',
      subCategoryId: data['sub_category_id'] as String,
      questionTextAr: data['question_text_ar'] as String,
      answerTextAr: data['answer_text_ar'] as String,
      questionMediaUrl: data['question_media_url'] as String?,
      answerMediaUrl: data['answer_media_url'] as String?,
      points: data['points'] as int,
      status: data['status'] as String? ?? 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await addQuestion(question);
  }

  Future<void> updateQuestionFromMap(
      String id, Map<String, dynamic> data) async {
    final doc = await _db.collection('questions').doc(id).get();
    if (!doc.exists) {
      throw Exception('Question not found');
    }

    final existing = SeenjeemQuestionModel.fromFirestore(doc.data()!, doc.id);
    final question = SeenjeemQuestionModel(
      id: id,
      subCategoryId:
          data['sub_category_id'] as String? ?? existing.subCategoryId,
      questionTextAr:
          data['question_text_ar'] as String? ?? existing.questionTextAr,
      answerTextAr: data['answer_text_ar'] as String? ?? existing.answerTextAr,
      questionMediaUrl:
          data['question_media_url'] as String? ?? existing.questionMediaUrl,
      answerMediaUrl:
          data['answer_media_url'] as String? ?? existing.answerMediaUrl,
      points: data['points'] as int? ?? existing.points,
      status: data['status'] as String? ?? existing.status,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    // Check for duplicate points
    final exists = await _db
        .collection('questions')
        .where('sub_category_id', isEqualTo: question.subCategoryId)
        .where('points', isEqualTo: question.points)
        .get();

    if (exists.docs.isNotEmpty && exists.docs.first.id != id) {
      throw Exception(
          'A question with ${question.points} points already exists for this sub-category');
    }

    await _db.collection('questions').doc(id).update(question.toFirestore());
  }

  Future<void> createMainCategory(Map<String, dynamic> data) async {
    try {
      final category = MainCategoryModel(
        id: '',
        nameAr: data['name_ar'] as String,
        mediaUrl: data['media_url'] as String?,
        displayOrder: data['display_order'] as int? ?? 0,
        isActive: data['is_active'] as bool? ?? true,
        status: data['status'] as String? ?? 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await addMainCategory(category);
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateMainCategoryFromMap(
      String id, Map<String, dynamic> data) async {
    final doc = await _db.collection('main_categories').doc(id).get();
    if (!doc.exists) {
      throw Exception('Main category not found');
    }

    final existing = MainCategoryModel.fromFirestore(doc.data()!, doc.id);
    final category = MainCategoryModel(
      id: id,
      nameAr: data['name_ar'] as String? ?? existing.nameAr,
      mediaUrl: data['media_url'] as String? ?? existing.mediaUrl,
      displayOrder: data['display_order'] as int? ?? existing.displayOrder,
      isActive: data['is_active'] as bool? ?? existing.isActive,
      status: data['status'] as String? ?? existing.status,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    await updateMainCategory(id, category);
  }

  Future<void> createSubCategory(Map<String, dynamic> data) async {
    final category = SubCategoryModel(
      id: '',
      mainCategoryId: data['main_category_id'] as String,
      nameAr: data['name_ar'] as String,
      mediaUrl: data['media_url'] as String,
      displayOrder: data['display_order'] as int? ?? 0,
      isActive: data['is_active'] as bool? ?? true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await addSubCategory(category);
  }

  Future<void> updateSubCategoryFromMap(
      String id, Map<String, dynamic> data) async {
    final doc = await _db.collection('sub_categories').doc(id).get();
    if (!doc.exists) {
      throw Exception('Sub category not found');
    }

    final existing = SubCategoryModel.fromFirestore(doc.data()!, doc.id);
    final category = SubCategoryModel(
      id: id,
      mainCategoryId:
          data['main_category_id'] as String? ?? existing.mainCategoryId,
      nameAr: data['name_ar'] as String? ?? existing.nameAr,
      mediaUrl: data['media_url'] as String? ?? existing.mediaUrl,
      displayOrder: data['display_order'] as int? ?? existing.displayOrder,
      isActive: data['is_active'] as bool? ?? existing.isActive,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    await updateSubCategory(id, category);
  }
}
