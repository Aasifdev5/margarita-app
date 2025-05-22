import 'package:flutter/material.dart';
import 'package:margarita/screens/menu.dart';
import 'package:margarita/screens/shop.dart';
import 'package:margarita/screens/food_home.dart';
import 'package:margarita/screens/orderHistory.dart';
import 'package:margarita/screens/favourites.dart';
import 'package:margarita/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = 'Loading...';
  String _email = 'Loading...';
  String _phone = 'Loading...';
  String _profileImage = 'https://picsum.photos/120';

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/api/user/profile');
      print('Profile response: $response');
      setState(() {
        _fullName = response['name'] ?? 'No name provided';
        _email = response['email'] ?? 'No email provided';
        _phone = response['phone'] ?? 'No phone provided';
        _profileImage = response['profile_image'] ?? _profileImage;

        _nameController.text = _fullName;
        _emailController.text = _email;
        _phoneController.text = _phone;
      });
    } catch (e) {
      print('Error loading profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/api/user/profile', {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (response['statusCode'] == 200) {
        final userData = response['body']['user'] ?? response['body'];
        setState(() {
          _fullName = userData['name'] ?? _nameController.text.trim();
          _email = userData['email'] ?? _emailController.text.trim();
          _phone = userData['phone'] ?? _phoneController.text.trim();
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        throw Exception(
          response['body']['message'] ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: Text(
          'Perfil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MenuScreen()),
              ),
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.orange))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileImage(),
                      SizedBox(height: 16),
                      Text(
                        _fullName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _email,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 24),
                      _buildProfileDetailsCard(),
                      SizedBox(height: 24),
                      _buildActionButton(),
                      if (_isEditing) _buildCancelButton(),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProfileImage() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.orange,
      child: CircleAvatar(
        radius: 56,
        backgroundImage: NetworkImage(_profileImage),
        onBackgroundImageError:
            (_, __) => Icon(Icons.person, size: 60, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileDetailsCard() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(
              icon: Icons.person,
              label: 'Nombre Completo',
              value: _fullName,
              controller: _nameController,
              isEditing: _isEditing,
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.email,
              label: 'Correo Electrónico',
              value: _email,
              controller: _emailController,
              isEditing: _isEditing,
            ),
            SizedBox(height: 16),
            _buildDetailRow(
              icon: Icons.phone,
              label: 'Teléfono',
              value: _phone,
              controller: _phoneController,
              isEditing: _isEditing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
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
              isEditing
                  ? TextField(
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
                  )
                  : Text(
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

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed:
          _isLoading
              ? null
              : () {
                if (_isEditing) {
                  _saveProfile();
                } else {
                  setState(() => _isEditing = true);
                }
              },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        _isEditing ? 'Guardar Perfil' : 'Editar Perfil',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextButton(
        onPressed: () {
          setState(() {
            _nameController.text = _fullName;
            _emailController.text = _email;
            _phoneController.text = _phone;
            _isEditing = false;
          });
        },
        child: Text(
          'Cancelar',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      currentIndex: 4,
      onTap: (index) => _onBottomNavItemTapped(index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Tienda'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Pedidos'),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Favoritos',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menú'),
      ],
    );
  }

  void _onBottomNavItemTapped(int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = FoodHomeScreen();
        break;
      case 1:
        screen = ShopScreen(category: '');
        break;
      case 2:
        screen = OrderHistoryScreen();
        break;
      case 3:
        screen = FavouritesScreen(favorites: []);
        break;
      case 4:
        screen = MenuScreen();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
