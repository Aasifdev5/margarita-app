import 'package:flutter/material.dart';
import 'package:margarita/screens/cart.dart'; // Import the CartScreen
import 'package:margarita/screens/menu.dart'; // Import MenuScreen
import 'package:margarita/screens/food_home.dart'; // Import the FoodHomeScreen
import 'package:margarita/screens/orderHistory.dart'; // Import OrderHistoryScreen
import 'package:margarita/screens/favourites.dart'; // Import FavouritesScreen

class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Map<String, dynamic>> cartItems = [];
  // List to track favorite items
  List<String> favoriteItems = [];

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      bool itemExists = false;
      for (var cartItem in cartItems) {
        if (cartItem['name'] == item['name']) {
          cartItem['quantity'] += 1;
          itemExists = true;
          break;
        }
      }
      if (!itemExists) {
        cartItems.add({...item, 'quantity': 1});
      }
    });

    // Navigate to CartScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CartScreen(cartItems: cartItems)),
    );
  }

  void _toggleFavorite(String itemName) {
    setState(() {
      if (favoriteItems.contains(itemName)) {
        favoriteItems.remove(itemName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName removed from favorites!')),
        );
      } else {
        favoriteItems.add(itemName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName added to favorites!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Number of tabs
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Colors.grey[100],
            elevation: 0,
            title: Text(
              'Shop',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(text: 'Clásicos'),
                Tab(text: 'Snacks'),
                Tab(text: 'Bebidas'),
                Tab(text: 'Postres'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Clásicos Tab
            ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                _buildFoodItem(
                  imageUrl:
                      'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
                  name: 'Cheeseburger',
                  description: 'Lleva queso, lechuga y tomate',
                  price: '9,50 €',
                  onAdd:
                      () => _addToCart({
                        'imageUrl':
                            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
                        'name': 'Cheeseburger',
                        'price': '9,50 €',
                      }),
                ),
                SizedBox(height: 16),
                _buildFoodItem(
                  imageUrl:
                      'https://images.unsplash.com/photo-1513106580091-1d82408b8f8a',
                  name: 'Pizza Margarita',
                  description: 'Tomate, mozzarella y albahaca',
                  price: '12,00 €',
                  onAdd:
                      () => _addToCart({
                        'imageUrl':
                            'https://images.unsplash.com/photo-1513106580091-1d82408b8f8a',
                        'name': 'Pizza Margarita',
                        'price': '12,00 €',
                      }),
                ),
                SizedBox(height: 16),
                _buildFoodItem(
                  imageUrl:
                      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
                  name: 'Ensalada César',
                  description: 'Con lechuga romana, crutones y queso',
                  price: '7,50 €',
                  onAdd:
                      () => _addToCart({
                        'imageUrl':
                            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
                        'name': 'Ensalada César',
                        'price': '7,50 €',
                      }),
                ),
              ],
            ),
            // Snacks Tab (Placeholder)
            Center(child: Text('Snacks Tab')),
            // Bebidas Tab (Placeholder)
            Center(child: Text('Bebidas Tab')),
            // Postres Tab (Placeholder)
            Center(child: Text('Postres Tab')),
          ],
        ),
        // Bottom Navigation Bar
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          currentIndex: 1, // Shop selected
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FoodHomeScreen()),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem({
    required String imageUrl,
    required String name,
    required String description,
    required String price,
    required VoidCallback onAdd,
  }) {
    bool isFavorite = favoriteItems.contains(name);
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Icon(Icons.fastfood, size: 80, color: Colors.orange),
            ),
          ),
          SizedBox(width: 16),
          // Food Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(name),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Add Button
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
