// top_bar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'job_search.dart';
import 'chat_page.dart';
import 'settings.dart';
import 'friend_request.dart';
import 'notification.dart';
import '../services/chat_service.dart';

class TopBar extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkMode;

  const TopBar({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _userName = 'User';
  String _selectedLocation = 'Ontario';
  bool _loading = true;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();

    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      if (user == null && mounted) {
        // User signed out, redirect to login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
          ),
          (route) => false,
        );
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _userName = (doc.data() ?? {})['name'] ?? 'User';
        _selectedLocation = (doc.data() ?? {})['location'] ?? 'Ontario';
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
      ),
    );
    if (result != null && result is String) setState(() => _selectedLocation = result);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // User not authenticated, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
          ),
          (route) => false,
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    final currentUid = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C88BF),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $_userName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(_selectedLocation, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings),

          // NOTIFICATION ICON (Bell) - Shows notification dialog
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('notifications')
                .doc(currentUid)
                .collection('notifications')
                .where('seen', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      NotificationDialog.show(context);
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // FRIEND REQUEST ICON - Shows friend request page
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendRequestPage()),
              );
            },
          ),
          // SIGN OUT ICON
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(icon: Icon(Icons.home), text: 'Home'),
          Tab(icon: Icon(Icons.chat), text: 'Chat'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        const JobSearch(),
        _buildChatListTab(),
      ]),
    );
  }

  Widget _buildChatListTab() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Center(child: Text('User not logged in'));

    return FutureBuilder<List<String>>(
      future: _getAllChatAndFriendUserIds(currentUser.uid),
      builder: (context, userIdsSnapshot) {
        if (!userIdsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final userIds = userIdsSnapshot.data!;
        if (userIds.isEmpty) return const Center(child: Text('No friends or chats yet'));

        // Limit to 10 users to avoid Firestore whereIn limit
        final limitedUserIds = userIds.take(10).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').where('uid', whereIn: limitedUserIds).snapshots(),
          builder: (context, usersSnapshot) {
            if (!usersSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            final users = usersSnapshot.data!.docs;

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final otherUid = user['uid'] ?? '';
                final otherName = user['name'] ?? 'Unknown';
                final chatId = ChatService().generateChatId(currentUser.uid, otherUid);

                return FutureBuilder<int>(
                  future: ChatService().getUnreadCount(chatId, currentUser.uid),
                  builder: (context, unreadSnapshot) {
                    final unreadCount = unreadSnapshot.data ?? 0;
                    final hasUnread = unreadCount > 0;

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        otherName,
                        style: TextStyle(
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          color: hasUnread ? Colors.black : null,
                        ),
                      ),
                      trailing: hasUnread
                          ? CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId, otherUserName: otherName, otherUserUid: otherUid)),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<String>> _getAllChatAndFriendUserIds(String currentUid) async {
    // Get friends
    final friendsSnapshot = await _firestore.collection('users').doc(currentUid).collection('friends').get();
    final friendIds = friendsSnapshot.docs.map((doc) => doc.id).toSet();

    // Get chat users (include both friends and non-friends with existing chats)
    final chatsSnapshot = await _firestore.collection('chats').where('users', arrayContains: currentUid).get();
    final chatUserIds = <String>{};
    for (var chat in chatsSnapshot.docs) {
      final users = List<String>.from(chat['users']);
      chatUserIds.addAll(users.where((uid) => uid != currentUid));
    }

    // Combine friends and chat users, prioritize friends
    final allUserIds = {...friendIds, ...chatUserIds}.toList();
    return allUserIds;
  }

  void _signOut() async {
    await _auth.signOut();
    // Auth state listener will handle navigation to login
  }

}
