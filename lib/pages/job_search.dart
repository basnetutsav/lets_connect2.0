import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class JobSearch extends StatefulWidget {
  const JobSearch({super.key});

  @override
  State<JobSearch> createState() => _JobSearchState();
}

class _JobSearchState extends State<JobSearch> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<TabPage> pages = const [
    TabPage(tabTitle: '🏠 General Chat'),
    TabPage(tabTitle: '🛍️ House Rent'),
    TabPage(tabTitle: '💼 Job Search'),
    TabPage(tabTitle: '📢 Announcements'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: pages.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    );
  }
}

// Tab Page Widget
class TabPage extends StatefulWidget {
  final String tabTitle;
  const TabPage({super.key, required this.tabTitle});

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  final List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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
              );
            },
          ),
        ),
        MessageInputBox(
          controller: _controller,
          onSend: _sendMessage,
          onSendImage: _sendImage,
          onTakePhoto: _takePhoto,
        ),
      ],
    );
  }
}

class Message {
  final String? text;
  final File? image;
  final bool isSentByMe;

  Message({this.text, this.image, required this.isSentByMe});
}

class MessageInputBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSendImage;
  final VoidCallback onTakePhoto;

  const MessageInputBox({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendImage,
    required this.onTakePhoto,
  });

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
                );
              },
              child: const CircleAvatar(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.add, color: Colors.white),
              ),
            ),
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
            ),
          ],
        ),
      ),
    );
  }
}
