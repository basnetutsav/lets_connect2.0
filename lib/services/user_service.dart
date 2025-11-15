import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save user info after signup
  Future<void> saveUserToFirestore(User user, {String? username}) async {
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'username': username ?? user.email?.split('@')[0], // default username
      'profilePicture': null, // optional, can be updated later
      'location': 'Canada', // you can make dynamic later
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all users except current
  Stream<QuerySnapshot> getOtherUsers(String currentUid) {
    return _db.collection('users')
      .where('uid', isNotEqualTo: currentUid)
      .orderBy('createdAt', descending: false) // optional: order by join date
      .snapshots();
  }

  // Get user by UID
  Future<DocumentSnapshot> getUserByUid(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }
}
