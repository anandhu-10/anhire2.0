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
    final docRef = _firestore.collection('profiles').doc(profile.uid);
    final existingDoc = await docRef.get();

    final mapData = profile.toMap();

    if (profile.resumeCloudinaryUrl == null &&
        existingDoc.exists &&
        existingDoc.data() != null &&
        existingDoc.data()!['resumeCloudinaryUrl'] != null) {
      mapData['resumeCloudinaryUrl'] = existingDoc.data()!['resumeCloudinaryUrl'];
    }

    if (profile.resumeScore == null &&
        existingDoc.exists &&
        existingDoc.data() != null &&
        existingDoc.data()!['resumeScore'] != null) {
      mapData['resumeScore'] = existingDoc.data()!['resumeScore'];
    }

    await docRef.set(mapData, SetOptions(merge: true));

    // Also save basic user role and onboarding completion flag
    await _firestore.collection('users').doc(profile.uid).set({
      'uid': profile.uid,
      'role': 'student',
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
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
