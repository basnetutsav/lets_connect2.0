import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/chat_service.dart';
import '../notification_service.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserUid; // optional for profile bubble

  const ChatPage({super.key, required this.chatId, required this.otherUserName, this.otherUserUid});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatService.updateReadStatus(widget.chatId, _auth.currentUser!.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: widget.otherUserUid != null ? [
          FutureBuilder<bool>(
            future: _isFriend(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final isFriend = snapshot.data!;
              if (isFriend) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: _sendFriendRequest,
              );
            },
          ),
        ] : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message['senderId'] == _auth.currentUser!.uid;
                    String senderName = message['senderName'] ?? 'Anonymous';

                    Widget avatar = GestureDetector(
                      onTapDown: (details) => _showProfileBubble(message['senderId']),
                      child: CircleAvatar(
                        radius: 18,
                        child: Text(senderName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                        backgroundColor: isMe ? Colors.blueAccent : Colors.grey,
                      ),
                    );

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) avatar,
                          if (!isMe) const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue[200] : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 12),
                                ),
                              ),
                              child: Text(message['text'] ?? ''),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 6),
                          if (isMe) avatar,
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[100],
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6C88BF)),
            onPressed: _showImageOptions,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF6C88BF)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String uid = _auth.currentUser!.uid;
    String name = _auth.currentUser!.displayName ?? "Anonymous";

    // Create chat document if it doesn't exist
    await _chatService.createChatIfNotExists(widget.chatId, [uid, widget.otherUserUid ?? '']);

    await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
      'senderId': uid,
      'senderName': name,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _showProfileBubble(String senderId) async {
    final doc = await _firestore.collection('users').doc(senderId).get();
    final name = doc['name'] ?? 'Unknown';
    final location = doc['location'] ?? 'No location';
    final email = doc['email'] ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Location: $location'),
            Text('Email: $email'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SizedBox(
        height: 120,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _sendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _sendImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    String uid = _auth.currentUser!.uid;
    String name = _auth.currentUser!.displayName ?? "Anonymous";

    // Create chat document if it doesn't exist
    await _chatService.createChatIfNotExists(widget.chatId, [uid, widget.otherUserUid ?? '']);

    // For now, we just send the local path; replace with Firebase Storage in production
    String imagePath = pickedFile.path;

    await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
      'senderId': uid,
      'senderName': name,
      'text': null,
      'imageUrl': imagePath,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> _isFriend() async {
    if (widget.otherUserUid == null) return false;
    final currentUid = _auth.currentUser!.uid;
    final friendDoc = await _firestore.collection('users').doc(currentUid).collection('friends').doc(widget.otherUserUid).get();
    return friendDoc.exists;
  }

  Future<void> _sendFriendRequest() async {
    if (widget.otherUserUid == null) return;
    final currentUid = _auth.currentUser!.uid;
    final currentUserDoc = await _firestore.collection('users').doc(currentUid).get();
    final currentName = currentUserDoc.data()?['name'] ?? 'Someone';

    // Check if request already exists
    final existingRequest = await _firestore.collection('friendRequests').doc(widget.otherUserUid).collection('requests').where('from', isEqualTo: currentUid).get();
    if (existingRequest.docs.isNotEmpty) {
      NotificationService.show('Friend Request', 'Request already sent');
      return;
    }

    // Add to recipient's collection
    final docRef = await _firestore.collection('friendRequests').doc(widget.otherUserUid).collection('requests').add({
      'from': currentUid,
      'fromName': currentName,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Add to sender's collection with the same ID
    await _firestore.collection('friendRequests').doc(currentUid).collection('requests').doc(docRef.id).set({
      'from': currentUid,
      'to': widget.otherUserUid,
      'fromName': currentName,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('notifications').doc(widget.otherUserUid).collection('notifications').add({
      'uid': widget.otherUserUid,
      'to': widget.otherUserUid,
      'fromUid': currentUid,
      'fromName': currentName,
      'type': 'request_sent',
      'message': '$currentName sent you a friend request',
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });

    NotificationService.show('Friend Request', 'Request sent to ${widget.otherUserName}');
  }
}
