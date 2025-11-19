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

  // Get list of friend UIDs (accepted friend requests)
  Future<List<String>> getFriendUids(String currentUid) async {
    final requests = await _db
        .collection('friendRequests')
        .doc(currentUid)
        .collection('requests')
        .where('status', isEqualTo: 'accepted')
        .get();

    final friendUids = <String>{};

    for (var doc in requests.docs) {
      final data = doc.data();
      final otherUid = data['from'] == currentUid ? data['to'] : data['from'];
      friendUids.add(otherUid);
    }

    return friendUids.toList();
  }

  // Send friend request
  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    final requestId = '${fromUid}_$toUid';
    await _db.collection('friendRequests').doc(fromUid).collection('requests').doc(requestId).set({
      'from': fromUid,
      'to': toUid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Also create the request in the recipient's collection for easier querying
    final recipientRequestId = '${fromUid}_$toUid';
    await _db.collection('friendRequests').doc(toUid).collection('requests').doc(recipientRequestId).set({
      'from': fromUid,
      'to': toUid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
