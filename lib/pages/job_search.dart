import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class JobSearch extends StatefulWidget {
  const JobSearch({super.key});

  @override
  State<JobSearch> createState() => _JobSearchState();
}

class _JobSearchState extends State<JobSearch> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabs = ['🏠 General Chat', '🛍️ House Rent', '💼 Job Search', '📢 Announcements'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 8),
        child: AppBar(
          backgroundColor: const Color(0xFF6C88BF),
          automaticallyImplyLeading: false,
          elevation: 0,
          flexibleSpace: Align(
            alignment: Alignment.bottomCenter,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.map((tab) => ChatTab(tabName: tab)).toList(),
      ),
    );
  }
}

// ChatTab for each sub-tab
class ChatTab extends StatefulWidget {
  final String tabName;
  const ChatTab({super.key, required this.tabName});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String get chatId => widget.tabName.replaceAll(RegExp(r'\W'), '_');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var messages = snapshot.data!.docs;

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  bool isMe = message['senderId'] == _auth.currentUser!.uid;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[200] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: message['imageUrl'] != null
                          ? Image.network(message['imageUrl'])
                          : Text(
                              message['text'] ?? '',
                              style: const TextStyle(color: Colors.black),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
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
                  controller: _controller,
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
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String uid = _auth.currentUser!.uid;
    String name = _auth.currentUser!.displayName ?? _auth.currentUser!.email ?? "Anonymous";

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': uid,
      'senderName': name,
      'text': _controller.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': null,
    });

    _controller.clear();
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        height: 120,
        color: Colors.white,
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
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    String uid = _auth.currentUser!.uid;
    String name = _auth.currentUser!.displayName ?? _auth.currentUser!.email ?? "Anonymous";

    // For now, storing local path. In real app, upload to Firebase Storage
    String imageUrl = pickedFile.path;

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': uid,
      'senderName': name,
      'text': null,
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    });
  }
}
