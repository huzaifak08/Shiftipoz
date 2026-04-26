import 'dart:developer' as dev;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shiftipoz/helpers/constants.dart';
import 'package:shiftipoz/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfilePic(String uid, File imageFile) async {
    try {
      // Path: users/uid/profile_pic.jpg
      final ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('profile_pic.jpg');

      // Upload the file
      final uploadTask = await ref.putFile(imageFile);

      // Get the public URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      dev.log("Image Upload Error: $e");
      return null;
    }
  }

  Future<void> saveOrUpdateUser(UserModel user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      dev.log("Failed to sync user data to Firestore: $e");
      throw Exception("Failed to sync user data to Firestore: $e");
    }
  }

  /// 2. Fetch User Data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      dev.log("User data null found");
      return null;
    } catch (e) {
      dev.log("Failed to fetch user data: $e");
      throw Exception("Failed to fetch user data: $e");
    }
  }
}
