import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String currentName;
  final String currentLocation;

  const ProfilePage({
    super.key,
    required this.currentName,
    required this.currentLocation,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  String _selectedLocation = '';

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _selectedLocation = widget.currentLocation;
  }

  void _selectLocation() async {
    final newLocation = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: provinces.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(provinces[index]),
              onTap: () {
                Navigator.pop(context, provinces[index]);
              },
            );
          },
        );
      },
    );

    if (newLocation != null) {
      setState(() {
        _selectedLocation = newLocation;
      });
    }
  }

  void _saveProfile() {
    Navigator.pop(context, {
      'name': _nameController.text,
      'location': _selectedLocation,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF6C88BF),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Name', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 30),

            const Text('Location', style: TextStyle(fontSize: 16)),
            ListTile(
              leading: const Icon(Icons.map),
              title: Text(_selectedLocation),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectLocation,
            ),

            const Spacer(),

            Center(
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C88BF),
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
