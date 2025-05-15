import 'package:flutter/material.dart';
import 'package:margarita/screens/menu.dart'; // Import MenuScreen
import 'package:margarita/screens/shop.dart'; // Import ShopScreen
import 'package:margarita/screens/food_home.dart'; // Import FoodHomeScreen

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data (initial values, replace with actual data from backend)
  String _fullName = 'John Doe';
  String _email = 'johndoe@example.com';
  String _phone = '+1 234 567 8900';

  // Controllers for editing fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // State to toggle between view and edit mode
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with initial values
    _nameController = TextEditingController(text: _fullName);
    _emailController = TextEditingController(text: _email);
    _phoneController = TextEditingController(text: _phone);
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Function to save updated data
  void _saveProfile() {
    setState(() {
      _fullName = _nameController.text.trim();
      _email = _emailController.text.trim();
      _phone = _phoneController.text.trim();
      _isEditing = false; // Exit edit mode
    });
    // Show confirmation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
    // Here you can add logic to save data to a backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.orange,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: NetworkImage(
                    'https://picsum.photos/120', // Placeholder image
                  ),
                  onBackgroundImageError:
                      (error, stackTrace) =>
                          Icon(Icons.person, size: 60, color: Colors.white),
                ),
              ),
              SizedBox(height: 16),
              // User Name
              Text(
                _fullName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              // User Email
              Text(
                _email,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              // User Details Card
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _isEditing
                          ? _buildEditableField(
                            icon: Icons.person,
                            label: 'Full Name',
                            controller: _nameController,
                          )
                          : _buildDetailRow(
                            icon: Icons.person,
                            label: 'Full Name',
                            value: _fullName,
                          ),
                      SizedBox(height: 16),
                      _isEditing
                          ? _buildEditableField(
                            icon: Icons.email,
                            label: 'Email',
                            controller: _emailController,
                          )
                          : _buildDetailRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: _email,
                          ),
                      SizedBox(height: 16),
                      _isEditing
                          ? _buildEditableField(
                            icon: Icons.phone,
                            label: 'Phone',
                            controller: _phoneController,
                          )
                          : _buildDetailRow(
                            icon: Icons.phone,
                            label: 'Phone',
                            value: _phone,
                          ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Edit/Save Profile Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_isEditing) {
                      _saveProfile(); // Save the updated data
                    } else {
                      _isEditing = true; // Enter edit mode
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Save Profile' : 'Edit Profile',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Cancel Button (visible only in edit mode)
              if (_isEditing) ...[
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      // Reset fields to original values
                      _nameController.text = _fullName;
                      _emailController.text = _email;
                      _phoneController.text = _phone;
                      _isEditing = false; // Exit edit mode
                    });
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 4, // Menu selected
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FoodHomeScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ShopScreen()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen()),
            );
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Pedidos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }

  // Widget for displaying static detail row (view mode)
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget for displaying editable field (edit mode)
  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
