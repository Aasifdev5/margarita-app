import 'package:flutter/material.dart';
import 'package:margarita/screens/shop.dart';
import 'package:margarita/screens/food_home.dart';
import 'package:margarita/screens/menu.dart';
import 'package:margarita/screens/orderHistory.dart';
import 'package:margarita/screens/favourites.dart';
import 'package:intl/intl.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderNumber;
  final String paymentMethod;
  final String address;
  final double total;
  final List<Map<String, dynamic>> orderItems;

  const OrderSuccessScreen({
    Key? key,
    required this.orderNumber,
    required this.paymentMethod,
    required this.address,
    required this.total,
    required this.orderItems,
  }) : super(key: key);

  @override
  _OrderSuccessScreenState createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  bool _autoNavigate = true;

  @override
  void initState() {
    super.initState();
    // Log order details for debugging
    print(
      'OrderSuccessScreen: orderNumber=${widget.orderNumber}, '
      'paymentMethod=${widget.paymentMethod}, address=${widget.address}, '
      'total=${widget.total}, items=${widget.orderItems.length}',
    );

    // Auto-navigate after 5 seconds if not cancelled
    if (_autoNavigate) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_autoNavigate && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ShopScreen()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoNavigate = false; // Prevent navigation after dispose
    super.dispose();
  }

  String _formatDateTime() {
    final now = DateTime.now();
    final dateFormat = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es');
    final timeFormat = DateFormat('hh:mm a', 'es');
    return '${dateFormat.format(now)} • ${timeFormat.format(now)}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            semanticsLabel: label,
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              semanticsLabel: value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Producto sin nombre';
    final price = item['price']?.toString() ?? '\$0.00';
    final quantity = item['quantity']?.toString() ?? '1';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$quantity x $name',
              style: const TextStyle(fontSize: 14),
              semanticsLabel: '$quantity unidades de $name',
            ),
          ),
          Text(
            price,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            semanticsLabel: 'Precio $price',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderDateTime = _formatDateTime();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon with Animation
              AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 500),
                child: Semantics(
                  label: 'Pedido confirmado',
                  child: const Icon(
                    Icons.check_circle,
                    size: 100,
                    color: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Success Message
              Semantics(
                header: true,
                child: Text(
                  '¡Tu pedido ha sido\nrealizado con éxito!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Order Details
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles del Pedido',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Número de pedido',
                        widget.orderNumber.isNotEmpty
                            ? widget.orderNumber
                            : 'Desconocido',
                      ),
                      _buildDetailRow('Fecha y Hora', orderDateTime),
                      _buildDetailRow('Método de pago', widget.paymentMethod),
                      _buildDetailRow(
                        'Dirección',
                        widget.address.isNotEmpty
                            ? widget.address
                            : 'No especificada',
                      ),
                      _buildDetailRow(
                        'Total',
                        '\$${widget.total.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Artículos',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.orderItems.map(_buildOrderItem),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Auto-Navigation Info
              if (_autoNavigate)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Redirigiendo a la tienda en 5 segundos...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _autoNavigate = false;
                        });
                      },
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              // Back to Shop Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _autoNavigate = false;
                  });
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ShopScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Volver a la tienda',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  semanticsLabel: 'Volver a la tienda',
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 2, // Highlight 'Pedidos' tab
        onTap: (index) {
          Widget destination;
          switch (index) {
            case 0:
              destination = FoodHomeScreen();
              break;
            case 1:
              destination = const ShopScreen();
              break;
            case 2:
              destination = OrderHistoryScreen();
              break;
            case 3:
              destination = const FavouritesScreen(favorites: []);
              break;
            case 4:
              destination = MenuScreen();
              break;
            default:
              return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
            tooltip: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Shop',
            tooltip: 'Tienda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Pedidos',
            tooltip: 'Historial de pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favoritos',
            tooltip: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
            tooltip: 'Menú',
          ),
        ],
      ),
    );
  }
}
