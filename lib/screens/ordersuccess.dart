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

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Log order details for debugging
    print(
      'OrderSuccessScreen: orderNumber=${widget.orderNumber}, '
      'paymentMethod=${widget.paymentMethod}, address=${widget.address}, '
      'total=${widget.total}, items=${widget.orderItems.length}',
    );

    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              semanticsLabel: value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Producto sin nombre';
    final rawPrice = item['price']?.toString() ?? '0.00';
    final price = 'Bs. $rawPrice';
    final quantity = item['quantity']?.toString() ?? '1';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '$quantity x $name',
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              semanticsLabel: '$quantity unidades de $name',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    child: Semantics(
                      label: 'Pedido confirmado',
                      child: const Icon(
                        Icons.check_circle,
                        size: 120,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    header: true,
                    child: Text(
                      '¡Tu pedido ha sido\nrealizado con éxito!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detalles del Pedido',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Número de pedido',
                            widget.orderNumber.isNotEmpty
                                ? widget.orderNumber
                                : 'Desconocido',
                          ),
                          _buildDetailRow('Fecha y Hora', orderDateTime),
                          _buildDetailRow(
                            'Método de pago',
                            widget.paymentMethod,
                          ),
                          _buildDetailRow(
                            'Dirección',
                            widget.address.isNotEmpty
                                ? widget.address
                                : 'No especificada',
                          ),
                          _buildDetailRow(
                            'Total',
                            'Bs. ${widget.total.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 32, thickness: 1),
                          Text(
                            'Artículos',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.orderItems.map(_buildOrderItem),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: screenWidth * 0.9,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FoodHomeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Volver a Inicio',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        semanticsLabel: 'Volver a la página de inicio',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: screenWidth * 0.9,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShopScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Volver a la Tienda',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                        semanticsLabel: 'Volver a la tienda',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
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
