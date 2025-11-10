import 'package:flutter/material.dart';

// Inbox screen showing only DM inboxes like WhatsApp
class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  // Demo DM inbox data (replace with real API data in production)
  final List<Map<String, String>> chats = const [
    {
      'name': 'Alice',
      'lastMessage': 'Hi there!',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'time': '10:30 AM',
    },
    {
      'name': 'Bob',
      'lastMessage': 'Are you free today?',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'time': 'Yesterday',
    },
    {
      'name': 'Charlie',
      'lastMessage': 'Lets meet!',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'time': '2 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Use app theme for dark/light mode

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.primaryColor, // Theme-aware (matches TopBar's 0xFF6C88BF)
        elevation: 0, // Flat look matching TopBar
        foregroundColor: Colors.white,
        // Optional: Add a back button or search if needed
      ),
      body: ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: theme.dividerColor, // Theme-aware divider
        ),
        itemBuilder: (context, index) {
          final chat = chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(chat['avatar']!),
              radius: 25,
              backgroundColor: theme.colorScheme.surfaceContainerHighest, // Theme-aware
              onBackgroundImageError: (_, __) {
                // Fallback if image fails to load
                print('Failed to load avatar for ${chat['name']}');
              },
            ),
            title: Text(
              chat['name']!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.onSurface, // Theme-aware
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat['lastMessage']!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, // Theme-aware
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  chat['time']!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7), // Theme-aware
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant, // Theme-aware
            ),
            dense: true,
            onTap: () {
              // Navigate directly to DM page for this user
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DMPage(chatName: chat['name']!),
                ),
              );
            },
          );
        },
      ),
      // Optional: Floating action button for new chat
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add logic to start new DM (e.g., show contact search)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Start new chat')),
          );
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}

// DM page for individual chat (simple demo like WhatsApp) - theme-aware and consistent with TopBar
class DMPage extends StatefulWidget {
  final String chatName;
  const DMPage({super.key, required this.chatName});

  @override
  State<DMPage> createState() => _DMPageState();
}

class _DMPageState extends State<DMPage> {
  // Declare as empty list (initialize in initState to access widget.chatName)
  List<String> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize messages here (widget.chatName is now available)
    messages = [
      'Hi ${widget.chatName}!',
      'This is a demo DM.',
      'You can scroll up and down.',
      'How are you today?',
      'Great, thanks!',
    ];
    // Scroll to bottom after initial messages are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(text); // Add sent message
      // Demo echo response - replace with real API in production
      messages.add('Echo: $text');
    });
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chatName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.primaryColor, // Theme-aware (matches TopBar)
        elevation: 0, // Flat look
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Add video call logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call not implemented')),
              );
            },
            tooltip: 'Video Call',
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Add call logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call not implemented')),
              );
            },
            tooltip: 'Call',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Add menu logic (e.g., show popup menu)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More options not implemented')),
              );
            },
            tooltip: 'More',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16), // Matching TopBar padding
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isMe = index % 2 == 0; // Alternate for demo (even: sent, odd: received)
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75, // Matching TopBar
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.primaryColor // Theme-aware sent bubble (blue)
                          : theme.colorScheme.surfaceContainerHighest, // Theme-aware received bubble
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      messages[index],
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : theme.colorScheme.onSurface, // Theme-aware text
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input area (theme-aware, matches TopBar style)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface, // Theme-aware background
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.emoji_emotions,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    // Add emoji picker logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Emoji picker not implemented')),
                    );
                  },
                  tooltip: 'Emoji',
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: theme.hintColor),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      onSubmitted: (_) => _sendMessage(), // Send on enter
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    // Add attachment logic (e.g., image picker)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attachment not implemented')),
                    );
                  },
                  tooltip: 'Attach',
                ),
                IconButton(
                  icon: Icon(
                    Icons.mic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    // Add voice message logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice message not implemented')),
                    );
                  },
                  tooltip: 'Voice',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: theme.primaryColor),
                  onPressed: _sendMessage,
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}