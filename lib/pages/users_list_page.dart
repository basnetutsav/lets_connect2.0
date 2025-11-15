import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import 'chat_page.dart';
import '../services/chat_service.dart';

class UsersListPage extends StatelessWidget {
  UsersListPage({super.key});

  final User currentUser = FirebaseAuth.instance.currentUser!;
  final UserService userService = UserService();
  final ChatService chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users in Canada")),
      body: StreamBuilder<QuerySnapshot>(
        stream: userService.getOtherUsers(currentUser.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(user['username']),
                subtitle: Text(user['email']),
                onTap: () {
                  String chatId = chatService.generateChatId(currentUser.uid, user['uid']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(chatId: chatId, otherUserName: user['username']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
