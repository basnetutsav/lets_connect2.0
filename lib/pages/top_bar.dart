import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'job_search.dart';
import 'chat_page.dart';
import 'settings.dart';

class TopBar extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkMode;

  const TopBar({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _darkMode = false;
  String _userName = "User";
  String _selectedLocation = "Ontario";
  bool _loading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userName = doc['username'] ?? "User";
            _selectedLocation = doc['location'] ?? "Ontario";
            _loading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          toggleTheme: widget.toggleTheme,
          isDarkMode: _darkMode,
        ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xFF6C88BF),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $_userName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          _selectedLocation,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _openSettings,
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.home), text: 'Home'),
                    Tab(icon: Icon(Icons.chat), text: 'Chat'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  const JobSearch(), // group chats per tab
                  _buildChatListTab(), // 1-on-1 chat list
                ],
              ),
            ),
    );
  }

  // 1-on-1 Chat List
  Widget _buildChatListTab() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('User not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('uid', isNotEqualTo: currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;
        if (users.isEmpty) return const Center(child: Text('No other users found'));

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final otherUid = user['uid'];
            final otherName = user['username'];

            // Generate 1-on-1 chatId
            final chatId = currentUser.uid.hashCode <= otherUid.hashCode
                ? '${currentUser.uid}_$otherUid'
                : '${otherUid}_${currentUser.uid}';

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(otherName),
              subtitle: Text(user['email']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(chatId: chatId, otherUserName: otherName),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
