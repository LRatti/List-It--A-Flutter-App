import 'package:app_code/models/category.dart';
import 'package:app_code/models/supermarket.dart';
import 'package:app_code/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FirebaseSupermarketManager {

  FirebaseSupermarketManager({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  
  CollectionReference<Map<String, dynamic>> get _supermarkets {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Supermarkets");
  }
  
  CollectionReference<Map<String, dynamic>> get _categories {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return _firestore.collection("Users").doc(uid).collection("Categories");
  }
  
  // Methods to manage supermarket data in Firebase
  Future<void> setSupermarket(Supermarket supermarket) async {
    try {
      await _supermarkets.doc(supermarket.id).set(supermarket.toDatabase());
      AppLogger.info('Supermarket added successfully', data: {'id': supermarket.id});
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to add supermarket',
        error: error,
        stackTrace: stackTrace,
        data: {'id': supermarket.id},
      );
    }
  }

  Future<void> setAllSupermarkets(List<Supermarket> supermarkets) async {
    // Code to add multiple supermarkets to the database using batch writes
    if (supermarkets.isEmpty) return;
    
    WriteBatch batch = _firestore.batch();
    for (var supermarket in supermarkets) {
      batch.set(_supermarkets.doc(supermarket.id), supermarket.toDatabase());
    }
    
    try {
      await batch.commit();
      AppLogger.info('Supermarkets batch added successfully', data: {'count': supermarkets.length});
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to add supermarkets batch',
        error: error,
        stackTrace: stackTrace,
        data: {'count': supermarkets.length},
      );
    }
  }

  Future<Supermarket?> getSupermarketById(String sid) async {
    // Code to retrieve a supermarket by its ID from the database
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _supermarkets.doc(sid).get();
      if (doc.exists) {
        Supermarket supermarket;
        List<Category> categories = [];
        if (doc.data() != null && doc.data()!['categoryIds'] != null) {
          // Fetch all categories in parallel
          categories = (await Future.wait(
            (doc.data()!['categoryIds'] as List).map((catId) async {
              try {
                final catDoc = await _categories.doc(catId).get();
                if (catDoc.exists && catDoc.data() != null) {
                  return Category.fromJson(catDoc.data()!);
                }
              } catch (e) {
                // Category not found, skip it
                AppLogger.error('Error fetching category', error: e, data: {'categoryId': catId});
              }
              return null;
            })
          )).whereType<Category>().toList();
        }
        supermarket = Supermarket.fromDatabase(doc.data()!);
        supermarket.setCategories(categories);
        return supermarket;
      }
      else {
        AppLogger.warning('Supermarket not found', data: {'id': sid});
        return null;
      } 
    } catch (e) {
      AppLogger.error('Error fetching supermarket', error: e, data: {'id': sid});
      return null;
    }
  }

  Future<Supermarket?> getSupermarketByName(String name) async {
    // Code to retrieve a supermarket by its name from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _supermarkets
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return getSupermarketById(querySnapshot.docs.first.id);
      } else {
        AppLogger.warning('Supermarket with specified name not found', data: {'name': name});
        return null;
      }
    } catch (e) {
      AppLogger.error('Error fetching supermarket by name', error: e, data: {'name': name});
      return null;
    }
  }

  Future<List<Supermarket>> getAllSupermarkets() async {
    // Code to retrieve all supermarkets from the database
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _supermarkets.get();
      // Fetch all supermarkets in parallel
      List<Supermarket> supermarkets = (await Future.wait(
        querySnapshot.docs.map((doc) => getSupermarketById(doc.id))
      )).whereType<Supermarket>().toList();
      return supermarkets;
    } catch (e) {
      AppLogger.error('Error fetching supermarkets', error: e);
    }
    return [];
  }

  Future<List<Supermarket>> getVisibleSupermarkets() async {
    List<Supermarket> allSupermarkets = await getAllSupermarkets();
    return allSupermarkets.where((supermarket) => supermarket.isVisible).toList();
  }

}