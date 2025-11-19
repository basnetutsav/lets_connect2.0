import 'package:flutter/material.dart';
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
<<<<<<< HEAD
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
=======

  final List<TabPage> pages = const [
    TabPage(tabTitle: '🏠 General Chat'),
    TabPage(tabTitle: '🛍️ House Rent'),
    TabPage(tabTitle: '💼 Job Search'),
    TabPage(tabTitle: '📢 Announcements'),
  ];
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _tabController = TabController(length: tabs.length, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
=======
    _tabController = TabController(length: pages.length, vsync: this);
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)
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
        title: Center(child: Text(name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Picture
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
            const SizedBox(height: 20),
            // Action Buttons - Centered
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Block/Unblock Button
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore
                      .collection('users')
                      .doc(_auth.currentUser!.uid)
                      .collection('blockedUsers')
                      .doc(userId)
                      .get(),
                  builder: (context, blockSnapshot) {
                    final isBlocked = blockSnapshot.hasData && blockSnapshot.data!.exists;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (isBlocked) {
                            await _unblockUser(userId, name);
                          } else {
                            await _blockUserFromProfile(userId, name);
                          }
                        },
                        icon: Icon(
                          isBlocked ? Icons.check_circle : Icons.block,
                          size: 18,
                        ),
                        label: Text(isBlocked ? 'Unblock' : 'Block'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBlocked ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Add Friend Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Friend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C88BF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // DM Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('DM'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
<<<<<<< HEAD
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isTabBarVisible ? (isSmallScreen ? 48 : 56) : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isTabBarVisible ? 1.0 : 0.0,
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: isSmallScreen,
                labelColor: const Color(0xFF6C88BF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF6C88BF),
                labelStyle: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(fontSize: isSmallScreen ? 11 : 13),
                labelPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 10 : 12,
                ),
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
=======
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              tabs: const [
                Tab(icon: Icon(Icons.home), text: 'General Chat'),
                Tab(icon: Icon(Icons.storefront), text: 'House Rent'),
                Tab(icon: Icon(Icons.work), text: 'Job Search'),
                Tab(icon: Icon(Icons.campaign), text: 'Announcements'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: pages,
      ),
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)
    );
  }
}

<<<<<<< HEAD
class ChatTab extends StatefulWidget {
  final String tabName;
  final ScrollController scrollController;
  const ChatTab({super.key, required this.tabName, required this.scrollController});
=======
// Tab Page Widget
class TabPage extends StatefulWidget {
  final String tabTitle;
  const TabPage({super.key, required this.tabTitle});
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  final List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      messages.insert(0, Message(text: _controller.text.trim(), isSentByMe: true));
      messages.insert(
        0,
        Message(
          text: "Demo reply: ${_controller.text.trim()}",
          isSentByMe: false,
        ),
      );
    });

    _controller.clear();
    _scrollToTop();
  }

  Future<void> _sendImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      messages.insert(0, Message(image: File(pickedFile.path), isSentByMe: true));
    });

    _scrollToTop();
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() {
      messages.insert(0, Message(image: File(pickedFile.path), isSentByMe: true));
    });

    _scrollToTop();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Page title at the top of messages
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            widget.tabTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Colors.grey),
        Expanded(
<<<<<<< HEAD
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
=======
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(10),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return Align(
                alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: message.isSentByMe ? Colors.blue[400] : Colors.grey[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: message.image != null
                      ? Image.file(message.image!)
                      : Text(
                          message.text ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)
              );
            },
          ),
        ),
<<<<<<< HEAD
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
=======
        MessageInputBox(
          controller: _controller,
          onSend: _sendMessage,
          onSendImage: _sendImage,
          onTakePhoto: _takePhoto,
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)
        ),
      ],
    );
  }
}

class Message {
  final String? text;
  final File? image;
  final bool isSentByMe;

<<<<<<< HEAD
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
=======
  Message({this.text, this.image, required this.isSentByMe});
}

class MessageInputBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSendImage;
  final VoidCallback onTakePhoto;
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)

  const MessageInputBox({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendImage,
    required this.onTakePhoto,
  });

<<<<<<< HEAD
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
        title: Center(child: Text(name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Picture
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
=======
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: Colors.black,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => Container(
                    color: Colors.black87,
                    height: 120,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_camera, color: Colors.white),
                          title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pop(context);
                            onTakePhoto();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library, color: Colors.white),
                          title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pop(context);
                            onSendImage();
                          },
                        ),
                      ],
                    ),
                  ),
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)
                );
              },
              child: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
<<<<<<< HEAD
            const SizedBox(height: 20),
            // Action Buttons - Centered
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Block/Unblock Button
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore
                      .collection('users')
                      .doc(_auth.currentUser!.uid)
                      .collection('blockedUsers')
                      .doc(userId)
                      .get(),
                  builder: (context, blockSnapshot) {
                    final isBlocked = blockSnapshot.hasData && blockSnapshot.data!.exists;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (isBlocked) {
                            await _unblockUser(userId, name);
                          } else {
                            await _blockUserFromProfile(userId, name);
                          }
                        },
                        icon: Icon(
                          isBlocked ? Icons.check_circle : Icons.block,
                          size: 18,
                        ),
                        label: Text(isBlocked ? 'Unblock' : 'Block'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBlocked ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Add Friend Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add Friend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C88BF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // DM Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('DM'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ),
              ],
=======
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF6C88BF),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: onSend,
              ),
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD

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

=======
>>>>>>> parent of 63276ed ( create account login works, live chat in progress, inbox chat not working at the momment)
}
