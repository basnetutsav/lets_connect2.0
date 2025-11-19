import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/chat_service.dart';
import 'chat_page.dart';
class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String get currentUid => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
        backgroundColor: const Color(0xFF6C88BF),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'History'),
            Tab(text: 'Blocked Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildHistoryTab(),
          _buildBlockedUsersTab(),
        ],
      ),
    );
  }

  // Friends Tab
  Widget _buildFriendsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search friends...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(currentUid)
                .collection('friends')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No friends yet'),
                    ],
                  ),
                );
              }

              final friends = snapshot.data!.docs;
              final friendUids = friends.map((doc) => doc.id).toList();

              if (friendUids.isEmpty) {
                return const Center(child: Text('No friends'));
              }

              return FutureBuilder<QuerySnapshot>(
                future: _firestore
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: friendUids)
                    .get(),
                builder: (context, usersSnapshot) {
                  if (usersSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!usersSnapshot.hasData) return const SizedBox();

                  final userMap = {
                    for (var doc in usersSnapshot.data!.docs)
                      doc.id: doc.data() as Map<String, dynamic>
                  };

                  final filteredFriends = friends.where((friend) {
                    final userData = userMap[friend.id];
                    final name = userData?['name'] ?? '';
                    return name.toLowerCase().contains(_searchController.text.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friendDoc = filteredFriends[index];
                      final friendUid = friendDoc.id;
                      final userData = userMap[friendUid];

                      if (userData == null) return const SizedBox();

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userData['profilePicUrl'] != null
                                ? NetworkImage(userData['profilePicUrl'])
                                : null,
                            child: userData['profilePicUrl'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(userData['name'] ?? 'Unknown'),
                          subtitle: Text(userData['email'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.message, color: Color(0xFF6C88BF)),
                            onPressed: () async {
                              final chatId = ChatService().generateChatId(currentUid, friendUid);
                              await ChatService().createChatIfNotExists(chatId, [currentUid, friendUid]);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    chatId: chatId,
                                    otherUserName: userData['name'] ?? 'Unknown',
                                    otherUserUid: friendUid,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // History Tab (All requests)
  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('friendRequests')
          .doc(currentUid)
          .collection('requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No request history'),
                SizedBox(height: 8),
                Text(
                  'Friend requests you send or receive will appear here',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs;
        
        // Sort requests by timestamp (handle null timestamps)
        final sortedRequests = requests.toList()..sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['timestamp'] as Timestamp?;
          final bTimestamp = bData['timestamp'] as Timestamp?;
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          
          return bTimestamp.compareTo(aTimestamp);
        });
        
        final userUids = sortedRequests.map((r) {
          final data = r.data() as Map<String, dynamic>;
          return data['from'] == currentUid ? (data['to'] as String?) ?? data['from'] : data['from'] as String;
        }).toSet().toList();

        if (userUids.isEmpty) {
          return const Center(child: Text('No request history'));
        }

        return FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: userUids)
              .get(),
          builder: (context, usersSnapshot) {
            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!usersSnapshot.hasData) return const SizedBox();

            final userMap = {
              for (var doc in usersSnapshot.data!.docs)
                doc.id: doc.data() as Map<String, dynamic>
            };

            return ListView.builder(
              itemCount: sortedRequests.length,
              itemBuilder: (context, index) {
                final request = sortedRequests[index];
                final data = request.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'unknown';
                final otherUid = data['from'] == currentUid ? (data['to'] as String?) ?? data['from'] : data['from'] as String;
                final userData = userMap[otherUid];
                final isReceived = data['to'] == currentUid;

                if (userData == null) return const SizedBox();

                Color statusColor;
                IconData statusIcon;
                String statusText;

                switch (status) {
                  case 'accepted':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    statusText = 'Accepted';
                    break;
                  case 'declined':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    statusText = 'Declined';
                    break;
                  case 'blocked':
                    statusColor = Colors.grey;
                    statusIcon = Icons.block;
                    statusText = 'Blocked';
                    break;
                  case 'pending':
                    statusColor = Colors.orange;
                    statusIcon = Icons.pending;
                    statusText = 'Pending';
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusIcon = Icons.help;
                    statusText = status;
                }

                final timestamp = data['timestamp'] as Timestamp?;
                final dateTime = timestamp?.toDate();
                
                // Format time with relative time (e.g., "2 hours ago") and absolute time
                String timeDisplay;
                String relativeTime;
                
                if (dateTime != null) {
                  relativeTime = timeago.format(dateTime, locale: 'en_short');
                  final formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                  timeDisplay = '$relativeTime • $formattedDate';
                } else {
                  relativeTime = 'Unknown time';
                  timeDisplay = 'No timestamp available';
                }

                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 360;
                final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
                
                // Check if this is a pending request with actions
                final hasPendingActions = status == 'pending' && isReceived;
                
                // Responsive sizing - more compact for pending requests with actions
                final avatarRadius = isSmallScreen ? 16.0 : (hasPendingActions ? 18.0 : 20.0);
                final titleFontSize = isSmallScreen ? 12.0 : (hasPendingActions ? 13.0 : 14.0);
                final subtitleFontSize = isSmallScreen ? 10.0 : (hasPendingActions ? 11.0 : 12.0);
                final timeFontSize = isSmallScreen ? 9.0 : (hasPendingActions ? 9.0 : 10.0);
                final iconSize = isSmallScreen ? 12.0 : 14.0;
                final actionIconSize = isSmallScreen ? 18.0 : 20.0;
                final statusFontSize = isSmallScreen ? 10.0 : 11.0;
                final statusIconSize = isSmallScreen ? 12.0 : 14.0;
                
                return Card(
                  margin: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 2 : 3,
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : (hasPendingActions ? 8 : 12),
                      vertical: hasPendingActions ? 4 : (isSmallScreen ? 2 : 4),
                    ),
                    leading: CircleAvatar(
                      radius: avatarRadius,
                      backgroundImage: userData['profilePicUrl'] != null
                          ? NetworkImage(userData['profilePicUrl'])
                          : null,
                      child: userData['profilePicUrl'] == null
                          ? Icon(Icons.person, size: avatarRadius)
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            userData['name'] ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: titleFontSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          isReceived ? Icons.arrow_downward : Icons.arrow_upward,
                          size: iconSize,
                          color: isReceived ? Colors.blue : Colors.orange,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: hasPendingActions ? 2 : (isSmallScreen ? 1 : 2)),
                        Text(
                          isReceived
                              ? 'Received from ${userData['name'] ?? 'Unknown'}'
                              : 'Sent to ${userData['name'] ?? 'Unknown'}',
                          style: TextStyle(fontSize: subtitleFontSize),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1),
                        Text(
                          timeDisplay,
                          style: TextStyle(fontSize: timeFontSize, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: hasPendingActions
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _acceptRequest(request.id, otherUid, userData['name']),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.check, color: Colors.green, size: actionIconSize),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _declineRequest(request.id, otherUid, userData['name']),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.close, color: Colors.red, size: actionIconSize),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8,
                              vertical: isSmallScreen ? 3 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: statusIconSize, color: statusColor),
                                SizedBox(width: isSmallScreen ? 2 : 3),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: statusFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    isThreeLine: false,
                    dense: true,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Blocked Users Tab
  Widget _buildBlockedUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blockedUsers')
          .orderBy('blockedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No blocked users'),
              ],
            ),
          );
        }

        final blockedUsers = snapshot.data!.docs;
        final blockedUids = blockedUsers.map((doc) => doc.id).toList();

        if (blockedUids.isEmpty) {
          return const Center(child: Text('No blocked users'));
        }

        return FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: blockedUids)
              .get(),
          builder: (context, usersSnapshot) {
            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!usersSnapshot.hasData) return const SizedBox();

            final userMap = {
              for (var doc in usersSnapshot.data!.docs)
                doc.id: doc.data() as Map<String, dynamic>
            };

            return ListView.builder(
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                final blockedDoc = blockedUsers[index];
                final blockedUid = blockedDoc.id;
                final userData = userMap[blockedUid];

                if (userData == null) return const SizedBox();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['profilePicUrl'] != null
                          ? NetworkImage(userData['profilePicUrl'])
                          : null,
                      child: userData['profilePicUrl'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(userData['name'] ?? 'Unknown'),
                    subtitle: Text(userData['email'] ?? ''),
                    trailing: ElevatedButton.icon(
                      onPressed: () => _unblockUser(blockedUid, userData['name']),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Unblock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _acceptRequest(String requestId, String fromUid, String? userName) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(currentUid)
          .collection('requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Also update the sender's request status
      await _firestore
          .collection('friendRequests')
          .doc(fromUid)
          .collection('requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // Add to friends collections
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('friends')
          .doc(fromUid)
          .set({'addedAt': FieldValue.serverTimestamp()});

      await _firestore
          .collection('users')
          .doc(fromUid)
          .collection('friends')
          .doc(currentUid)
          .set({'addedAt': FieldValue.serverTimestamp()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Friend request from ${userName ?? 'User'} accepted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to accept request: $e')));
      }
    }
  }

  Future<void> _declineRequest(String requestId, String fromUid, String? userName) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(currentUid)
          .collection('requests')
          .doc(requestId)
          .update({'status': 'declined'});

      // Also update the sender's request status
      await _firestore
          .collection('friendRequests')
          .doc(fromUid)
          .collection('requests')
          .doc(requestId)
          .update({'status': 'declined'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Friend request from ${userName ?? 'User'} declined')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to decline request: $e')));
      }
    }
  }

  Future<void> _unblockUser(String blockedUid, String? userName) async {
    try {
      // Remove from blocked users
      await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blockedUsers')
          .doc(blockedUid)
          .delete();

      // Update any blocked requests to pending
      final blockedRequests = await _firestore
          .collection('friendRequests')
          .doc(currentUid)
          .collection('requests')
          .where('from', isEqualTo: blockedUid)
          .where('status', isEqualTo: 'blocked')
          .get();

      for (var doc in blockedRequests.docs) {
        await doc.reference.update({'status': 'pending'});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${userName ?? 'User'} has been unblocked')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
