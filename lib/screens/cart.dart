import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:margarita/screens/checkout.dart';
import 'package:margarita/services/api_service.dart'; // Import ApiService

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartScreen({Key? key, required this.cartItems}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<Map<String, dynamic>> _items;
  double _total = 0.0;
  static const String baseUrl = 'http://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems);
    _calculateTotal();
  }

  void _calculateTotal() {
    _total = 0.0;
    for (var item in _items) {
      final price = item['price'] as String;
      final quantity = item['quantity'] as int;
      final priceValue = double.tryParse(price.replaceAll('\$', '')) ?? 0.0;
      _total += priceValue * quantity;
    }
  }

  Future<void> _updateQuantity(int index, int change) async {
    final item = _items[index];
    final newQuantity = (item['quantity'] as int) + change;

    if (newQuantity <= 0) {
      try {
        final headers = await ApiService.getHeaders();
        final response = await http.post(
          Uri.parse('$baseUrl/api/cart/remove'),
          headers: headers,
          body: json.encode({'product_id': item['id'], 'remove_all': true}),
        );
        print(
          'Remove from cart response: ${response.statusCode}, ${response.body}',
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _items.clear();
            _items.addAll(List<Map<String, dynamic>>.from(data['cart']));
            _calculateTotal();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el carrito')),
          );
        }
      } catch (e) {
        print('Error updating cart: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión')));
      }
      return;
    }

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/add'),
        headers: headers,
        body: json.encode({'product_id': item['id'], 'quantity': change}),
      );
      print('Update cart response: ${response.statusCode}, ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _items.clear();
          _items.addAll(List<Map<String, dynamic>>.from(data['cart']));
          _calculateTotal();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el carrito')),
        );
      }
    } catch (e) {
      print('Error updating cart: $e');
      setState(() {
        if (newQuantity > 0) {
          _items[index]['quantity'] = newQuantity;
        } else {
          _items.removeAt(index);
        }
        _calculateTotal();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Actualizado localmente debido a error')),
      );
    }
  }

  Future<void> _checkout() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('El carrito está vacío')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckoutScreen(cartItems: _items)),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Carrito de Compras',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.of(context).pop(_items),
        ),
      ),
      body:
          _items.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 100,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Tu carrito está vacío',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Añade productos para continuar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Cart items
                        ..._items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildCartItem(item, index),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  _buildCheckoutSection(),
                ],
              ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    // Prepend base URL to imageUrl
    final imageUrl =
        item['imageUrl'] != null && item['imageUrl'].isNotEmpty
            ? '$baseUrl/${item['imageUrl'].startsWith('/') ? item['imageUrl'].substring(1) : item['imageUrl']}'
            : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                imageUrl != null
                    ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget: (context, url, error) {
                        print('Image load error for URL: $url, Error: $error');
                        return const Icon(
                          Icons.broken_image,
                          size: 70,
                          color: Colors.grey,
                        );
                      },
                    )
                    : const Icon(
                      Icons.fastfood,
                      size: 70,
                      color: Colors.orange,
                    ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String? ?? 'Producto sin nombre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['price'] as String? ?? '\$0.00',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.orange,
                onPressed: () => _updateQuantity(index, -1),
              ),
              Text(
                '${item['quantity'] ?? 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.orange,
                onPressed: () => _updateQuantity(index, 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'REALIZAR PEDIDO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
