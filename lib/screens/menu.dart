import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:margarita/screens/profile.dart';
import 'package:margarita/screens/address.dart';
import 'package:margarita/screens/favourites.dart';
import 'package:margarita/screens/food_home.dart';
import 'package:margarita/screens/shop.dart';
import 'package:margarita/screens/orderHistory.dart';
import 'package:margarita/main.dart'; // Import LoginScreen

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late NavigatorState _navigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save a reference to the NavigatorState
    _navigator = Navigator.of(context);
  }

  // Function to perform logout API call and clear preferences
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final response = await http.post(
          Uri.parse('https://remoto.digital/api/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode != 200) {
          // Log error but proceed with local cleanup
          print('Logout API failed: ${response.body}');
        }
      }

      // Clear all stored preferences
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('whatsapp_number');

      // Navigate to LoginScreen and clear navigation stack
      if (mounted) {
        _navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Logout error: $e');
      // Clear preferences and navigate even if API call fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('whatsapp_number');

      if (mounted) {
        _navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // Function to show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Cierre de Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _logout(); // Perform logout
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: const Text(
          'Menú',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildMenuItem(
              icon: Icons.person,
              title: 'Perfil',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.location_on,
              title: 'Dirección',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddressScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.favorite,
              title: 'Favoritos',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavouritesScreen(favorites: []),
                  ),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Cerrar Sesión',
              onTap: _showLogoutDialog,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 4, // Menú selected
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FoodHomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ShopScreen(category: ''),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FavouritesScreen(favorites: []),
              ),
            );
          }
          // Index 4 is MenuScreen, no navigation needed
        },
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
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange, size: 30),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}
