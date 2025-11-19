import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import 'chat_page.dart';
import '../services/chat_service.dart';

class UsersListPage extends StatefulWidget {
  const UsersListPage({super.key});

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  final User currentUser = FirebaseAuth.instance.currentUser!;
  final UserService userService = UserService();
  final ChatService chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  List<String> friendUids = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    friendUids = await userService.getFriendUids(currentUser.uid);
    if (mounted) setState(() {});
  }

  Future<void> _sendFriendRequest(String toUid) async {
    try {
      await userService.sendFriendRequest(currentUser.uid, toUid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Users"),
        backgroundColor: const Color(0xFF6C88BF),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C88BF)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF6C88BF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF6C88BF), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: userService.getOtherUsers(currentUser.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var users = snapshot.data!.docs;

                // Filter users based on search query
                if (_searchQuery.isNotEmpty) {
                  users = users.where((user) {
                    final username = (user['username'] ?? '').toString().toLowerCase();
                    final email = (user['email'] ?? '').toString().toLowerCase();
                    final name = (user['name'] ?? '').toString().toLowerCase();
                    return username.contains(_searchQuery) || 
                           email.contains(_searchQuery) ||
                           name.contains(_searchQuery);
                  }).toList();
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No users found' : 'No results for "$_searchQuery"',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    bool isFriend = friendUids.contains(user['uid']);
                    final username = user['username'] ?? 'Unknown';
                    final email = user['email'] ?? '';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF6C88BF),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Text(
                                username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              if (isFriend)
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(email),
                        trailing: isFriend
                            ? const Chip(
                                label: Text('Friend', style: TextStyle(fontSize: 12)),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            : ElevatedButton(
                                onPressed: () => _sendFriendRequest(user['uid']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C88BF),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Add Friend'),
                              ),
                        onTap: () {
                          String chatId = chatService.generateChatId(currentUser.uid, user['uid']);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(chatId: chatId, otherUserName: username, otherUserUid: user['uid']),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
