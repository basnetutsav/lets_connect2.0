import 'package:flutter/material.dart';
import 'job_search.dart';
import 'inbox_chat.dart';
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
  String _selectedLocation = "Ontario"; // Default location

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
    _tabController = TabController(length: 2, vsync: this);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C88BF),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lets Connect',
              style: TextStyle(
                fontSize: 16, // smaller main title
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  _selectedLocation,
                  style: const TextStyle(
                    fontSize: 12, // smaller subtitle
                    color: Colors.white70,
                  ),
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
        children: const [
          JobSearch(),
          InboxPage(),
        ],
      ),
    );
  }
}
