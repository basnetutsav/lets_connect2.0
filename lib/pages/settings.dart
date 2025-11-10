import 'package:flutter/material.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkMode;

  const SettingsPage({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _darkMode;
  String _selectedLocation = 'please select one location in settings'; // Default

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
  }

  void _openLocationSelector() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationSelectorPage()),
    );

    if (result != null && result is String) {
      setState(() {
        _selectedLocation = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location set to $_selectedLocation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _selectedLocation);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: const Color(0xFF6C88BF),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Profile clicked!'))),
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Notifications clicked!'))),
              ),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Privacy'),
                onTap: () => ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Privacy clicked!'))),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Location'),
                subtitle: Text(_selectedLocation),
                onTap: _openLocationSelector,
              ),
              const Divider(height: 30),
              SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: const Icon(Icons.dark_mode),
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                    widget.toggleTheme(_darkMode);
                  });
                },
              ),
              const Spacer(),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(
                          toggleTheme: widget.toggleTheme,
                          isDarkMode: _darkMode,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationSelectorPage extends StatelessWidget {
  const LocationSelectorPage({super.key});

  static const List<String> provinces = [
    'Alberta',
    'British Columbia',
    'Manitoba',
    'New Brunswick',
    'Newfoundland and Labrador',
    'Nova Scotia',
    'Ontario',
    'Prince Edward Island',
    'Quebec',
    'Saskatchewan',
    'Northwest Territories',
    'Nunavut',
    'Yukon',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: const Color(0xFF6C88BF),
      ),
      body: ListView.builder(
        itemCount: provinces.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(provinces[index]),
            onTap: () {
              Navigator.pop(context, provinces[index]); // return selected province
            },
          );
        },
      ),
    );
  }
}
