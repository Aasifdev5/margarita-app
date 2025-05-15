import 'package:flutter/material.dart';
import 'package:margarita/screens/shop.dart'; // Import ShopScreen
import 'package:margarita/screens/food_home.dart'; // Import FoodHomeScreen
import 'package:margarita/screens/menu.dart'; // Import MenuScreen
import 'package:margarita/screens/orderHistory.dart'; // Import OrderHistoryScreen
import 'package:margarita/screens/favourites.dart'; // Import FavouritesScreen

class OrderSuccessScreen extends StatelessWidget {
  final String orderNumber;
  final String paymentMethod;
  final String address;

  OrderSuccessScreen({
    required this.orderNumber,
    required this.paymentMethod,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    // Date and time updated: 01:06 PM IST on Thursday, May 15, 2025
    String orderDate = '15 de mayo de 2025';
    String orderTime = '01:06 PM';

    // Navigate to ShopScreen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ShopScreen()),
        (route) => false, // Remove all previous routes
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Icon(Icons.check_circle, size: 100, color: Colors.green),
              SizedBox(height: 16),
              // Success Message
              Text(
                '¡Tu pedido ha sido\nrealizado con éxito!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 24),
              // Order Details
              _buildDetailRow('Número de pedido', orderNumber),
              SizedBox(height: 8),
              _buildDetailRow('Fecha', orderDate),
              SizedBox(height: 8),
              _buildDetailRow('Hora', orderTime),
              SizedBox(height: 8),
              _buildDetailRow('Método de pago', paymentMethod),
              SizedBox(height: 8),
              _buildDetailRow('Dirección', address),
              SizedBox(height: 32),
              // Back to Home Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => ShopScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Volver al inicio',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // Home selected
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
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavouritesScreen()),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
