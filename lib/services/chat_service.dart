import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Send message with sender name
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await _db.collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'senderName': senderName, // include sender name
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // Listen to messages in real-time
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db.collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Generate a consistent chatId (1-on-1 chat)
  String generateChatId(String uid1, String uid2) {
    List<String> uids = [uid1, uid2];
    uids.sort(); // ensures same chatId for both users
    return uids.join('_');
  }

  // Create chat document if it doesn't exist
  Future<void> createChatIfNotExists(String chatId, List<String> users) async {
    var chatDoc = _db.collection('chats').doc(chatId);
    var docSnapshot = await chatDoc.get();

    if (!docSnapshot.exists) {
      await chatDoc.set({
        'users': users,
        'createdAt': FieldValue.serverTimestamp(),
        'readStatus': {for (var user in users) user: FieldValue.serverTimestamp()}, // Initialize read status for each user
      });
    }
  }

  // Update read status for a user in a chat
  Future<void> updateReadStatus(String chatId, String userId) async {
    await _db.collection('chats').doc(chatId).update({
      'readStatus.$userId': FieldValue.serverTimestamp(),
    });
  }

  // Get unread message count for a user in a chat
  Future<int> getUnreadCount(String chatId, String userId) async {
    var chatDoc = await _db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return 0;

    var readStatus = chatDoc.data()?['readStatus']?[userId];
    if (readStatus == null) return 0; // If never read, all messages are unread

    var messages = await _db.collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isGreaterThan: readStatus)
        .get();

    return messages.docs.length;
  }
}
