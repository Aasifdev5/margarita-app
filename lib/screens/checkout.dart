import 'package:flutter/material.dart';
import 'package:margarita/screens/ordersuccess.dart'; // Import OrderSuccessScreen
import 'package:margarita/screens/food_home.dart'; // Import FoodHomeScreen
import 'package:margarita/screens/menu.dart'; // Import MenuScreen
import 'package:margarita/screens/shop.dart'; // Import ShopScreen

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double shippingCost;

  CheckoutScreen({required this.cartItems, this.shippingCost = 2.00});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Efectivo'; // Default payment method
  String _location = '123 Main St, City'; // Updated default location
  String _note = ''; // Note field

  double _calculateSubtotal() {
    return widget.cartItems.fold(0.0, (sum, item) {
      String priceStr = item['price'].replaceAll(' €', '').replaceAll(',', '.');
      double price = double.parse(priceStr);
      return sum + price;
    });
  }

  double _calculateTotal() {
    return _calculateSubtotal() + widget.shippingCost;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ordered Items
                ...widget.cartItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  return _buildOrderItem(
                    imageUrl: item['imageUrl'] as String?,
                    name: item['name'],
                    price: item['price'],
                  );
                }).toList(),
                SizedBox(height: 24),
                // Cost Breakdown
                _buildCostRow(
                  'Subtotal',
                  '${_calculateSubtotal().toStringAsFixed(2)} €',
                ),
                SizedBox(height: 8),
                _buildCostRow(
                  'Envío',
                  '${widget.shippingCost.toStringAsFixed(2)} €',
                ),
                SizedBox(height: 8),
                _buildCostRow(
                  'Total',
                  '${_calculateTotal().toStringAsFixed(2)} €',
                  isTotal: true,
                ),
                SizedBox(height: 24),
                // Payment Method
                Text(
                  'Pago',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildPaymentOption(
                      'Efectivo',
                      'Efectivo' == _paymentMethod,
                    ),
                    SizedBox(width: 16),
                    _buildPaymentOption('QR', 'QR' == _paymentMethod),
                  ],
                ),
                SizedBox(height: 24),
                // Location
                Text(
                  'Ubicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Handle location change
                    setState(() {
                      _location = '123 Main St, City'; // Update this as needed
                    });
                  },
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        _location,
                        style: TextStyle(fontSize: 16, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Add Note
                Text(
                  'Añadir una nota',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _note = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Añadir una nota',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 24),
                // Place Order Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => OrderSuccessScreen(
                              orderNumber: '123456', // Example order number
                              paymentMethod: _paymentMethod,
                              address: _location,
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
                    'Realizar pedido',
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
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ), // Changed to Menu
        ],
      ),
    );
  }

  Widget _buildOrderItem({
    String? imageUrl,
    required String name,
    required String price,
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
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Icons.fastfood,
                            size: 60,
                            color: Colors.orange,
                          ),
                    )
                    : Icon(Icons.fastfood, size: 60, color: Colors.orange),
          ),
          SizedBox(width: 16),
          // Food Details
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          // Price
          Text(
            price,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _paymentMethod = label;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? Colors.orange : Colors.grey),
            borderRadius: BorderRadius.circular(10),
            color:
                isSelected
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: label,
                groupValue: _paymentMethod,
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
                activeColor: Colors.orange,
              ),
              Text(label, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
