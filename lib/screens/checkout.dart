import 'package:flutter/material.dart';
import 'package:margarita/screens/ordersuccess.dart';
import 'package:margarita/screens/food_home.dart';
import 'package:margarita/screens/menu.dart';
import 'package:margarita/screens/shop.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:margarita/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CheckoutScreen({Key? key, required this.cartItems}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Efectivo';
  File? _paymentReceipt;
  String _deliveryAddress = 'Seleccionar ubicación';
  String _note = '';
  bool _isLoadingLocation = false;
  static const String baseUrl = 'https://remoto.digital';

  @override
  void initState() {
    super.initState();
    _validateCart();
  }

  Future<void> _validateCart() async {
    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);
    }
  }

  double _calculateSubtotal() {
    return widget.cartItems.fold(0.0, (sum, item) {
      String priceStr = (item['price'] ?? '\$0.00')
          .replaceAll('\$', '')
          .replaceAll(',', '.');
      double price = double.tryParse(priceStr) ?? 0.0;
      int quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }

  Future<void> _pickPaymentReceipt() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _paymentReceipt = File(pickedFile.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor active los servicios de ubicación'),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de ubicación denegados')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Los permisos de ubicación están permanentemente denegados',
            ),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            [
                  place.street,
                  place.locality,
                  place.administrativeArea,
                  place.country,
                ]
                .where((element) => element != null && element.isNotEmpty)
                .join(', ')
                .trim();
        setState(() {
          _deliveryAddress =
              address.isNotEmpty ? address : 'Dirección no disponible';
        });
      } else {
        setState(() {
          _deliveryAddress = 'No se pudo obtener la dirección';
        });
      }
    } catch (e) {
      print('Location error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener la ubicación: $e')),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _confirmOrder() async {
    if (_deliveryAddress == 'Seleccionar ubicación' ||
        _deliveryAddress == 'No se pudo obtener la dirección' ||
        _deliveryAddress == 'Dirección no disponible') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione una ubicación válida'),
        ),
      );
      return;
    }

    try {
      final headers = await ApiService.getHeaders();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/cart/checkout'),
      );

      // Add headers
      request.headers.addAll(headers);

      // Add form fields
      request.fields['payment_mode'] =
          _paymentMethod == 'Efectivo' ? 'cash' : 'upi';
      request.fields['order_type'] = 'delivery';
      request.fields['delivery_address'] = _deliveryAddress;
      request.fields['notes'] = _note;

      // Add payment receipt if QR and file selected
      if (_paymentMethod == 'QR' && _paymentReceipt != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'payment_receipt',
            _paymentReceipt!.path,
            filename: _paymentReceipt!.path.split('/').last,
          ),
        );
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Checkout response: ${response.statusCode}, ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => OrderSuccessScreen(
                  orderNumber: data['order_number'] ?? 'UNKNOWN',
                  paymentMethod: _paymentMethod,
                  address: _deliveryAddress,
                  total: _calculateSubtotal(), // Pass total
                  orderItems: widget.cartItems, // Pass cart items
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar el pedido: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      print('Checkout error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  Widget _buildOrderItem({
    String? imageUrl,
    required String name,
    required String price,
    int quantity = 1,
  }) {
    // Prepend base URL to imageUrl
    final fullImageUrl =
        imageUrl != null && imageUrl.isNotEmpty
            ? '$baseUrl${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}'
            : null;
    print('Loading image URL: $fullImageUrl'); // Debug log

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child:
                fullImageUrl != null
                    ? CachedNetworkImage(
                      imageUrl: fullImageUrl,
                      width: 60,
                      height: 60,
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
                          size: 60,
                          color: Colors.grey,
                        );
                      },
                    )
                    : const Icon(
                      Icons.fastfood,
                      size: 60,
                      color: Colors.orange,
                    ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$quantity x $price',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '\$${(double.parse(price.replaceAll('\$', '').replaceAll(',', '.')) * quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
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
      ),
    );
  }

  Widget _buildPaymentOption(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _paymentMethod = label;
            if (label != 'QR') {
              _paymentReceipt = null; // Clear receipt if not QR
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                    if (value != 'QR') {
                      _paymentReceipt = null; // Clear receipt if not QR
                    }
                  });
                },
                activeColor: Colors.orange,
              ),
              Text(label, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verificar'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu pedido',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...widget.cartItems.map(
                  (item) => _buildOrderItem(
                    imageUrl: item['imageUrl'] as String?,
                    name: item['name'] ?? 'Producto sin nombre',
                    price: item['price'] ?? '\$0.00',
                    quantity: item['quantity'] ?? 1,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                _buildCostRow(
                  'total parcial',
                  '\$${_calculateSubtotal().toStringAsFixed(2)}',
                ),
                const SizedBox(height: 16),
                _buildCostRow(
                  'Total',
                  '\$${_calculateSubtotal().toStringAsFixed(2)}',
                  isTotal: true,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Dirección de entrega',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _isLoadingLocation ? null : _getCurrentLocation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _isLoadingLocation
                            ? const CircularProgressIndicator()
                            : const Icon(
                              Icons.location_on,
                              color: Colors.orange,
                            ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _deliveryAddress,
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Notas (Opcional)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _note = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: 'Añade notas para tu pedido',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Método de pago',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPaymentOption(
                      'Efectivo',
                      'Efectivo' == _paymentMethod,
                    ),
                    const SizedBox(width: 16),
                    _buildPaymentOption('QR', 'QR' == _paymentMethod),
                  ],
                ),
                if (_paymentMethod == 'QR') ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Subir comprobante de pago',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickPaymentReceipt,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _paymentReceipt == null
                                  ? 'Seleccionar comprobante'
                                  : _paymentReceipt!.path.split('/').last,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Confirmar pedido',
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FoodHomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ShopScreen()),
            );
          } else if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MenuScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Tienda'),
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
}
