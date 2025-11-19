import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lets_connect/notification_service.dart';

class NotificationDialog {
  static void show(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      NotificationService.show('Error', 'User not logged in.');
      return;
    }
    final currentUid = currentUser.uid;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Notifications',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        content: SizedBox(
          width: isSmallScreen ? screenWidth * 0.9 : 340,
          height: isSmallScreen ? screenHeight * 0.6 : 420,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .doc(currentUid)
                .collection('notifications')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading notifications'),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications yet'),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No notifications'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data =
                      docs[index].data() as Map<String, dynamic>? ?? {};
                  final type = data['type'] ?? 'unknown';
                  final fromName = data['fromName'] ?? 'Unknown User';
                  final fromUid = data['fromUid'] ?? '';
                  final requestId = data['requestId'] ?? '';
                  final message = data['message'] ?? 'No message';
                  final notifId = docs[index].id;
                  final seen = data['seen'] is bool
                      ? data['seen'] as bool
                      : false;

                  String subtitle = '';
                  List<Widget> actions = [];

                  if (type == 'request_sent') {
                    subtitle = message.isNotEmpty ? message : '$fromName sent you a friend request';
                    actions = [
                      IconButton(
                        onPressed: () async {
                          await _acceptFriendRequest(
                            requestId,
                            fromUid,
                            fromName,
                            notifId,
                          );
                          NotificationService.show(
                            'Friend Request',
                            'You accepted $fromName\'s request',
                          );
                        },
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Accept',
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: () async {
                          await _declineFriendRequest(requestId, notifId);
                          NotificationService.show(
                            'Friend Request',
                            'You declined $fromName\'s request',
                          );
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Decline',
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: () async {
                          await _blockUser(fromUid, notifId);
                          NotificationService.show(
                            'User Blocked',
                            'You blocked $fromName',
                          );
                        },
                        icon: const Icon(Icons.block, color: Colors.grey),
                        tooltip: 'Block',
                        iconSize: 20,
                      ),
                    ];
                  } else if (type == 'request_accepted') {
                    subtitle = message.isNotEmpty ? message : '$fromName accepted your friend request';
                  } else if (type == 'request_sent_confirm') {
                    subtitle = message.isNotEmpty ? message : 'You sent a friend request to $fromName';
                  } else {
                    subtitle = message.isNotEmpty ? message : 'New notification';
                  }

                  // Skip rendering if essential data is missing
                  if (fromName.isEmpty && message.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    color: seen ? null : Colors.grey[100],
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: InkWell(
                      onTap: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(currentUid)
                              .collection('notifications')
                              .doc(notifId)
                              .delete();
                        } catch (e) {
                          NotificationService.show(
                            'Error',
                            'Failed to remove notification: $e',
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main content (title and subtitle)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    fromName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 13 : 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Action buttons (if any)
                            if (actions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: actions,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --------------------- ACTIONS ---------------------
  static Future<void> _acceptFriendRequest(
    String requestId,
    String fromUid,
    String fromName,
    String notifId,
  ) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('friendRequests')
          .doc(currentUid)
          .collection('requests')
          .doc(requestId)
          .update({
            'status': 'accepted',
            'timestamp': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('friends')
          .doc(fromUid)
          .set({'uid': fromUid});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUid)
          .collection('friends')
          .doc(currentUid)
          .set({'uid': currentUid});

      final meDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();
      final myName = meDoc.data()?['name'] ?? 'Someone';

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(fromUid)
          .collection('notifications')
          .add({
            'uid': fromUid,
            'to': fromUid,
            'fromUid': currentUid,
            'fromName': myName,
            'type': 'request_accepted',
            'requestId': requestId,
            'message': '$myName accepted your friend request',
            'timestamp': FieldValue.serverTimestamp(),
            'seen': false,
          });

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(currentUid)
          .collection('notifications')
          .doc(notifId)
          .delete();
    } catch (e) {
      NotificationService.show('Error', 'Failed to accept request: $e');
    }
  }

  static Future<void> _declineFriendRequest(
    String requestId,
    String notifId,
  ) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('friendRequests')
          .doc(currentUid)
          .collection('requests')
          .doc(requestId)
          .update({'status': 'declined'});
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(currentUid)
          .collection('notifications')
          .doc(notifId)
          .delete();
    } catch (e) {
      NotificationService.show('Error', 'Failed to decline request: $e');
    }
  }

  static Future<void> _blockUser(String fromUid, String notifId) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('blockedUsers')
          .doc('${currentUid}_$fromUid')
          .set({
            'blockedBy': currentUid,
            'blockedUser': fromUid,
            'createdAt': FieldValue.serverTimestamp(),
          });

      final pending = await FirebaseFirestore.instance
          .collection('friendRequests')
          .doc(currentUid)
          .collection('requests')
          .where('from', isEqualTo: fromUid)
          .get();

      for (var d in pending.docs) {
        await FirebaseFirestore.instance
            .collection('friendRequests')
            .doc(currentUid)
            .collection('requests')
            .doc(d.id)
            .update({'status': 'blocked'});
      }

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(currentUid)
          .collection('notifications')
          .doc(notifId)
          .delete();
    } catch (e) {
      NotificationService.show('Error', 'Failed to block user: $e');
    }
  }
}
