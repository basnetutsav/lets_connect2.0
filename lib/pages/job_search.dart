import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/chat_service.dart';
import 'chat_page.dart';

class JobSearch extends StatefulWidget {
  const JobSearch({super.key});

  @override
  State<JobSearch> createState() => _JobSearchState();
}

class _JobSearchState extends State<JobSearch>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _isTabBarVisible = true;
  double _lastScrollOffset = 0;
  
  final List<String> tabs = [
    '🏠 General Chat',
    '🛍️ House Rent',
    '💼 Job Search',
    '📢 Announcements',
  ];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentScrollOffset = _scrollController.offset;

    if (currentScrollOffset > _lastScrollOffset && currentScrollOffset > 50) {
      // Scrolling down - show tabs
      if (!_isTabBarVisible) {
        setState(() {
          _isTabBarVisible = true;
        });
      }
    } else if (currentScrollOffset < _lastScrollOffset) {
      // Scrolling up - hide tabs
      if (_isTabBarVisible) {
        setState(() {
          _isTabBarVisible = false;
        });
      }
    }

    _lastScrollOffset = currentScrollOffset;
  }



  void _showUserProfile(String userId, String name, String? profilePic) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .collection('friends')
                  .doc(userId)
                  .get(),
              builder: (context, friendSnapshot) {
                final isFriend = friendSnapshot.hasData && friendSnapshot.data!.exists;
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: profilePic != null
                          ? ClipOval(
                              child: Image.network(
                                profilePic,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 36, color: Colors.white),
                            ),
                    ),
                    if (isFriend)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          // Check if user is blocked and show Block/Unblock button
          FutureBuilder<DocumentSnapshot>(
            future: _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('blockedUsers')
                .doc(userId)
                .get(),
            builder: (context, blockSnapshot) {
              final isBlocked = blockSnapshot.hasData && blockSnapshot.data!.exists;

              return TextButton.icon(
                onPressed: () async {
                  if (isBlocked) {
                    // Unblock user
                    await _unblockUser(userId, name);
                  } else {
                    // Block user
                    await _blockUserFromProfile(userId, name);
                  }
                },
                icon: Icon(
                  isBlocked ? Icons.check_circle : Icons.block,
                  color: isBlocked ? Colors.green : Colors.red,
                ),
                label: Text(
                  isBlocked ? 'Unblock' : 'Block',
                  style: TextStyle(
                    color: isBlocked ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () async {
              final currentUser = _auth.currentUser!;
              final currentUid = currentUser.uid;
              final currentName =
                  currentUser.displayName ?? currentUser.email ?? 'Someone';

              try {
                // Check if user is blocked
                final isBlockedByMe = await _firestore
                    .collection('users')
                    .doc(currentUid)
                    .collection('blockedUsers')
                    .doc(userId)
                    .get();

                if (isBlockedByMe.exists) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You have blocked this user')),
                  );
                  return;
                }

                // Check if already friends
                final friendDoc = await _firestore
                    .collection('users')
                    .doc(currentUid)
                    .collection('friends')
                    .doc(userId)
                    .get();

                if (friendDoc.exists) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are already friends')),
                  );
                  return;
                }

                // Check if request already sent
                final existingRequest = await _firestore
                    .collection('friendRequests')
                    .doc(userId)
                    .collection('requests')
                    .where('from', isEqualTo: currentUid)
                    .where('status', isEqualTo: 'pending')
                    .get();

                if (existingRequest.docs.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Friend request already sent')),
                  );
                  return;
                }

                // Check if blocked by them
                final blockedDoc = await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('blockedUsers')
                    .doc(currentUid)
                    .get();

                if (blockedDoc.exists) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to send friend request')),
                  );
                  return;
                }

                // Create notifications parent document for receiver if it doesn't exist
                await _firestore.collection('notifications').doc(userId).set({
                  'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                // Create notifications parent document for sender if it doesn't exist
                await _firestore.collection('notifications').doc(currentUid).set({
                  'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                // Use consistent request ID format
                final requestId = '${currentUid}_$userId';

                // Send friend request to receiver
                await _firestore
                    .collection('friendRequests')
                    .doc(userId)
                    .collection('requests')
                    .doc(requestId)
                    .set({
                      'from': currentUid,
                      'to': userId,
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                // Also add to sender's history
                await _firestore
                    .collection('friendRequests')
                    .doc(currentUid)
                    .collection('requests')
                    .doc(requestId)
                    .set({
                      'from': currentUid,
                      'to': userId,
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                // Send notification to receiver
                await _firestore
                    .collection('notifications')
                    .doc(userId)
                    .collection('notifications')
                    .add({
                      'fromUid': currentUid,
                      'fromName': currentName,
                      'type': 'request_sent',
                      'requestId': requestId,
                      'message': '$currentName sent you a friend request',
                      'timestamp': FieldValue.serverTimestamp(),
                      'seen': false,
                    });

                // Send confirmation notification to sender
                await _firestore
                    .collection('notifications')
                    .doc(currentUid)
                    .collection('notifications')
                    .add({
                      'fromUid': userId,
                      'fromName': name,
                      'type': 'request_sent_confirm',
                      'requestId': requestId,
                      'message': 'You sent a friend request to $name',
                      'timestamp': FieldValue.serverTimestamp(),
                      'seen': false,
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend request sent')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sending request: $e')),
                );
              }
            },
            child: const Text('Add Friend'),
          ),
          TextButton(
            onPressed: () async {
              final chatId = ChatService().generateChatId(_auth.currentUser!.uid, userId);
              await ChatService().createChatIfNotExists(chatId, [_auth.currentUser!.uid, userId]);
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    chatId: chatId,
                    otherUserName: name,
                    otherUserUid: userId,
                  ),
                ),
              );
            },
            child: const Text('DM'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUserFromProfile(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block $userName? They will not be able to send you messages or friend requests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final currentUid = _auth.currentUser!.uid;

      // Add to blocked users
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blockedUsers')
          .doc(userId)
          .set({
            'uid': userId,
            'blockedAt': FieldValue.serverTimestamp(),
          });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName has been blocked')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _unblockUser(String userId, String userName) async {
    try {
      final currentUid = _auth.currentUser!.uid;

      // Remove from blocked users
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blockedUsers')
          .doc(userId)
          .delete();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName has been unblocked')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isTabBarVisible ? 56 : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isTabBarVisible ? 1.0 : 0.0,
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: const Color(0xFF6C88BF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF6C88BF),
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                tabs: tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: tabs.map((tab) => ChatTab(
              tabName: tab,
              scrollController: _scrollController,
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class ChatTab extends StatefulWidget {
  final String tabName;
  final ScrollController scrollController;
  const ChatTab({super.key, required this.tabName, required this.scrollController});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
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
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              var messages = snapshot.data!.docs;

              return ListView.builder(
                controller: widget.scrollController,
                reverse: true,
                padding: const EdgeInsets.all(10),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  bool isMe = message['senderId'] == _auth.currentUser!.uid;

                  final data =
                      message.data() as Map<String, dynamic>?; // null-safe
                  String senderName = data?['senderName'] ?? "Anonymous";
                  String text =
                      (data != null &&
                          data.containsKey('text') &&
                          data['text'] != null)
                      ? data['text'].toString()
                      : '';

                  Widget avatar = InkWell(
                    onTap: () {
                      if (!isMe)
                        _showUserProfile(
                          message['senderId'],
                          senderName,
                          data?['profilePicUrl'],
                        );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: isMe ? Colors.blueAccent : Colors.grey,
                      child: data?['profilePicUrl'] != null
                          ? ClipOval(
                              child: Image.network(
                                data!['profilePicUrl'],
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              senderName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) avatar,
                        if (!isMe) const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[200] : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(isMe ? 12 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 12),
                              ),
                            ),
                            child: text.isNotEmpty
                                ? Text(
                                    text,
                                    style: const TextStyle(color: Colors.black),
                                  )
                                : Container(
                                    height: 80,
                                    alignment: Alignment.center,
                                    color: Colors.grey[400],
                                    child: const Text(
                                      'Image (not available in test mode)',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.grey[100],
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Color(0xFF6C88BF)),
                onPressed: () => _showImageOptions(),
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
    String name =
        _auth.currentUser!.displayName ??
        _auth.currentUser!.email ??
        "Anonymous";

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': uid,
          'senderName': name,
          'text': _controller.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'profilePicUrl': _auth.currentUser!.photoURL,
        });

    _controller.clear();
  }

  void _showImageOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image sending is disabled in test mode')),
    );
  }

  void _showUserProfile(String userId, String name, String? profilePic) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .collection('friends')
                  .doc(userId)
                  .get(),
              builder: (context, friendSnapshot) {
                final isFriend = friendSnapshot.hasData && friendSnapshot.data!.exists;
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: profilePic != null
                          ? ClipOval(
                              child: Image.network(
                                profilePic,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 36, color: Colors.white),
                            ),
                    ),
                    if (isFriend)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          // Check if user is blocked and show Block/Unblock button
          FutureBuilder<DocumentSnapshot>(
            future: _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('blockedUsers')
                .doc(userId)
                .get(),
            builder: (context, blockSnapshot) {
              final isBlocked = blockSnapshot.hasData && blockSnapshot.data!.exists;

              return TextButton.icon(
                onPressed: () async {
                  if (isBlocked) {
                    // Unblock user
                    await _unblockUser(userId, name);
                  } else {
                    // Block user
                    await _blockUserFromProfile(userId, name);
                  }
                },
                icon: Icon(
                  isBlocked ? Icons.check_circle : Icons.block,
                  color: isBlocked ? Colors.green : Colors.red,
                ),
                label: Text(
                  isBlocked ? 'Unblock' : 'Block',
                  style: TextStyle(
                    color: isBlocked ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () async {
              final currentUser = _auth.currentUser!;
              final currentUid = currentUser.uid;
              final currentName =
                  currentUser.displayName ?? currentUser.email ?? 'Someone';

              try {
                // Check if user is blocked
                final isBlockedByMe = await _firestore
                    .collection('users')
                    .doc(currentUid)
                    .collection('blockedUsers')
                    .doc(userId)
                    .get();

                if (isBlockedByMe.exists) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You have blocked this user')),
                  );
                  return;
                }

                // Check if already friends
                final friendDoc = await _firestore
                    .collection('users')
                    .doc(currentUid)
                    .collection('friends')
                    .doc(userId)
                    .get();

                if (friendDoc.exists) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are already friends')),
                  );
                  return;
                }

                // Check if request already sent
                final existingRequest = await _firestore
                    .collection('friendRequests')
                    .doc(userId)
                    .collection('requests')
                    .where('from', isEqualTo: currentUid)
                    .where('status', isEqualTo: 'pending')
                    .get();

                if (existingRequest.docs.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Friend request already sent')),
                  );
                  return;
                }

                // Check if blocked by them
                final blockedDoc = await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection('blockedUsers')
                    .doc(currentUid)
                    .get();

                if (blockedDoc.exists) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to send friend request')),
                  );
                  return;
                }

                // Create notifications parent document for receiver if it doesn't exist
                await _firestore.collection('notifications').doc(userId).set({
                  'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                // Create notifications parent document for sender if it doesn't exist
                await _firestore.collection('notifications').doc(currentUid).set({
                  'createdAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                // Use consistent request ID format
                final requestId = '${currentUid}_$userId';

                // Send friend request to receiver
                await _firestore
                    .collection('friendRequests')
                    .doc(userId)
                    .collection('requests')
                    .doc(requestId)
                    .set({
                      'from': currentUid,
                      'to': userId,
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                // Also add to sender's history
                await _firestore
                    .collection('friendRequests')
                    .doc(currentUid)
                    .collection('requests')
                    .doc(requestId)
                    .set({
                      'from': currentUid,
                      'to': userId,
                      'status': 'pending',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                // Send notification to receiver
                await _firestore
                    .collection('notifications')
                    .doc(userId)
                    .collection('notifications')
                    .add({
                      'fromUid': currentUid,
                      'fromName': currentName,
                      'type': 'request_sent',
                      'requestId': requestId,
                      'message': '$currentName sent you a friend request',
                      'timestamp': FieldValue.serverTimestamp(),
                      'seen': false,
                    });

                // Send confirmation notification to sender
                await _firestore
                    .collection('notifications')
                    .doc(currentUid)
                    .collection('notifications')
                    .add({
                      'fromUid': userId,
                      'fromName': name,
                      'type': 'request_sent_confirm',
                      'requestId': requestId,
                      'message': 'You sent a friend request to $name',
                      'timestamp': FieldValue.serverTimestamp(),
                      'seen': false,
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Friend request sent')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sending request: $e')),
                );
              }
            },
            child: const Text('Add Friend'),
          ),
          TextButton(
            onPressed: () async {
              final chatId = ChatService().generateChatId(_auth.currentUser!.uid, userId);
              await ChatService().createChatIfNotExists(chatId, [_auth.currentUser!.uid, userId]);
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    chatId: chatId,
                    otherUserName: name,
                    otherUserUid: userId,
                  ),
                ),
              );
            },
            child: const Text('DM'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUserFromProfile(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block $userName? They will not be able to send you messages or friend requests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final currentUid = _auth.currentUser!.uid;
      
      // Add to blocked users
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blockedUsers')
          .doc(userId)
          .set({
            'uid': userId,
            'blockedAt': FieldValue.serverTimestamp(),
          });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName has been blocked')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _unblockUser(String userId, String userName) async {
    try {
      final currentUid = _auth.currentUser!.uid;

      // Remove from blocked users
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blockedUsers')
          .doc(userId)
          .delete();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$userName has been unblocked')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

}
