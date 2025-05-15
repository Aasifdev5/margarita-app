import 'package:flutter/material.dart';
import 'package:margarita/screens/checkout.dart'; // Import the CheckoutScreen
import 'package:margarita/screens/food_home.dart'; // Import FoodHomeScreen
import 'package:margarita/screens/menu.dart'; // Import MenuScreen
import 'package:margarita/screens/shop.dart'; // Import ShopScreen
import 'package:margarita/screens/orderHistory.dart'; // Import OrderHistoryScreen
import 'package:margarita/screens/favourites.dart'; // Import FavouritesScreen

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  CartScreen({required this.cartItems});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<Map<String, dynamic>> _cartItems;
  final double shippingCost = 2.00; // Define shipping cost

  @override
  void initState() {
    super.initState();
    _cartItems = widget.cartItems;
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      int newQuantity = _cartItems[index]['quantity'] + change;
      if (newQuantity >= 1) {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });
  }

  double _calculateTotal() {
    return _cartItems.fold(0.0, (sum, item) {
      double price = double.parse(
        item['price'].replaceAll(' €', '').replaceAll(',', '.'),
      );
      return sum + (price * item['quantity']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(
          'Carrito',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                return _buildCartItem(
                  imageUrl: _cartItems[index]['imageUrl'] as String?,
                  name: _cartItems[index]['name'],
                  price: _cartItems[index]['price'],
                  quantity: _cartItems[index]['quantity'],
                  onDecrease: () => _updateQuantity(index, -1),
                  onIncrease: () => _updateQuantity(index, 1),
                );
              },
            ),
          ),
          // Total and Order Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_calculateTotal().toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CheckoutScreen(
                              cartItems: _cartItems,
                              shippingCost: shippingCost,
                            ),
                      ),
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
                    'Hacer pedido',
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
        ],
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

  Widget _buildCartItem({
    String? imageUrl,
    required String name,
    required String price,
    required int quantity,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // Food Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                imageUrl != null
                    ? Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Icons.fastfood,
                            size: 80,
                            color: Colors.orange,
                          ),
                    )
                    : Icon(Icons.fastfood, size: 80, color: Colors.orange),
          ),
          SizedBox(width: 16),
          // Food Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ),
          // Quantity Controls
          Row(
            children: [
              IconButton(
                onPressed: onDecrease,
                icon: Icon(Icons.remove_circle, color: Colors.grey),
              ),
              Text('$quantity', style: TextStyle(fontSize: 16)),
              IconButton(
                onPressed: onIncrease,
                icon: Icon(Icons.add_circle, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
