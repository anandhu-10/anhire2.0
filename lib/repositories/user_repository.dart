import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_model.dart';

final userRepositoryProvider = Provider((ref) => UserRepository(
      FirebaseFirestore.instance,
    ));

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Future<void> createProfile(ProfileModel profile) async {
    await _firestore
        .collection('profiles')
        .doc(profile.uid)
        .set(profile.toMap());
    
    // Also save basic user role
    await _firestore.collection('users').doc(profile.uid).set({
      'uid': profile.uid,
      'role': 'student',
    }, SetOptions(merge: true));
  }

  Future<ProfileModel?> getProfile(String uid) async {
    final doc = await _firestore.collection('profiles').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return ProfileModel.fromMap(doc.data()!);
    }
    return null;
  }

  Stream<ProfileModel?> profileStream(String uid) {
    return _firestore
        .collection('profiles')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return ProfileModel.fromMap(doc.data()!);
      }
      return null;
    });
  }
}
