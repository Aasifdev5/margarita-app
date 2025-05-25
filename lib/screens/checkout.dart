import 'package:flutter/material.dart';
import 'package:margarita/screens/ordersuccess.dart';
import 'package:margarita/screens/food_home.dart';
import 'package:margarita/screens/menu.dart';
import 'package:margarita/screens/shop.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:margarita/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CheckoutScreen({Key? key, required this.cartItems}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Efectivo';
  String _deliveryAddress = ''; // Stores address ID
  String _note = '';
  bool _isLoadingLocation = false;
  bool _isLoadingAddresses = true;
  List<Map<String, dynamic>> _savedAddresses = [];
  static const String baseUrl = 'https://remoto.digital';

  @override
  void initState() {
    super.initState();
    print('CheckoutScreen initState called');
    _validateCart();
    _fetchSavedAddresses();
  }

  Future<void> _validateCart() async {
    if (widget.cartItems.isEmpty) {
      print('Cart is empty, navigating back');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El carrito está vacío')));
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);
    } else {
      print('Cart items: ${widget.cartItems}');
    }
  }

  Future<void> _fetchSavedAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/addresses'),
        headers: headers,
      );

      print('Addresses API response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> addresses = data['addresses'] ?? [];
        setState(() {
          _savedAddresses =
              addresses.map((addr) {
                return {
                  'id': addr['id'].toString(),
                  'label': addr['label'],
                  'street': addr['street'],
                  'city': addr['city'],
                  'coordinates': addr['coordinates'],
                  'is_default': addr['is_default'] ?? false,
                  'display':
                      '${addr['label']}: ${addr['street']}, ${addr['city']}',
                };
              }).toList();

          // Set default address
          final defaultAddress = _savedAddresses.firstWhere(
            (addr) => addr['is_default'] == true,
            orElse:
                () =>
                    _savedAddresses.isNotEmpty
                        ? _savedAddresses.first
                        : {
                          'id': '',
                          'display': 'No hay direcciones guardadas',
                          'street': '',
                          'city': '',
                          'coordinates': '',
                        },
          );
          _deliveryAddress = defaultAddress['id'];
          _isLoadingAddresses = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, inicia sesión nuevamente')),
        );
        setState(() {
          _deliveryAddress = '';
          _isLoadingAddresses = false;
        });
      } else {
        setState(() {
          _deliveryAddress = '';
          _isLoadingAddresses = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar direcciones: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      print('Error fetching addresses: $e');
      setState(() {
        _deliveryAddress = '';
        _isLoadingAddresses = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  Future<void> _saveNewAddress(
    String label,
    String street,
    String city,
    String coordinates,
  ) async {
    try {
      final headers = await ApiService.getHeaders();
      final requestBody = {
        'label': label,
        'street': street,
        'city': city,
        'coordinates': coordinates,
        'is_default': false,
      };
      print('Saving new address: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/api/addresses'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Save address response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newAddress = data['address'];
        setState(() {
          final newAddr = {
            'id': newAddress['id'].toString(),
            'label': newAddress['label'],
            'street': newAddress['street'],
            'city': newAddress['city'],
            'coordinates': newAddress['coordinates'],
            'is_default': newAddress['is_default'] ?? false,
            'display':
                '${newAddress['label']}: ${newAddress['street']}, ${newAddress['city']}',
          };
          _savedAddresses.add(newAddr);
          _deliveryAddress = newAddr['id'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar la nueva dirección: ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving new address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión al guardar la dirección: $e'),
        ),
      );
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
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de ubicación denegados')),
          );
          setState(() {
            _isLoadingLocation = false;
          });
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
        setState(() {
          _isLoadingLocation = false;
        });
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
        String street = place.street ?? 'Calle desconocida';
        String city = place.locality ?? 'Ciudad desconocida';
        String coordinates = '${position.latitude},${position.longitude}';

        // Save the new address
        await _saveNewAddress('Ubicación actual', street, city, coordinates);

        setState(() {
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _deliveryAddress = '';
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la dirección')),
        );
      }
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _deliveryAddress = '';
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener la ubicación: $e')),
      );
    }
  }

  Future<void> _confirmOrder() async {
    if (_deliveryAddress.isEmpty) {
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

      // Find selected address for display
      final selectedAddress = _savedAddresses.firstWhere(
        (addr) => addr['id'] == _deliveryAddress,
        orElse: () => {'display': 'Dirección no encontrada'},
      );

      // Add form fields
      request.fields['payment_mode'] =
          _paymentMethod == 'Efectivo' ? 'cash' : 'upi';
      request.fields['order_type'] = 'delivery';
      request.fields['delivery_address'] = selectedAddress['display'];
      request.fields['notes'] = _note;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Checkout response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => OrderSuccessScreen(
                  orderNumber: data['order_number'] ?? 'UNKNOWN',
                  paymentMethod: _paymentMethod,
                  address: selectedAddress['display'],
                  total: _calculateSubtotal(),
                  orderItems: widget.cartItems,
                ),
          ),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, inicia sesión nuevamente')),
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
    final fullImageUrl =
        imageUrl != null && imageUrl.isNotEmpty
            ? '$baseUrl${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}'
            : null;
    print('Loading image URL: $fullImageUrl');

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
    print('Building CheckoutScreen');
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
                  'Total parcial',
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
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    value:
                        _deliveryAddress.isNotEmpty &&
                                _savedAddresses.any(
                                  (addr) => addr['id'] == _deliveryAddress,
                                )
                            ? _deliveryAddress
                            : null,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: Text(
                      _isLoadingAddresses
                          ? 'Cargando...'
                          : 'Seleccione una dirección',
                    ),
                    isExpanded: true,
                    items: [
                      ..._savedAddresses.map((addr) {
                        return DropdownMenuItem<String>(
                          value: addr['id'],
                          child: Text(
                            addr['display'],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: 'current_location',
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Usar ubicación actual',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value == 'current_location') {
                        await _getCurrentLocation();
                      } else if (value != null) {
                        setState(() {
                          _deliveryAddress = value;
                        });
                      }
                    },
                  ),
                ),
                if (_isLoadingLocation)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Center(child: CircularProgressIndicator()),
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
                      _paymentMethod == 'Efectivo',
                    ),
                    const SizedBox(width: 16),
                    _buildPaymentOption('QR', _paymentMethod == 'QR'),
                  ],
                ),
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
              MaterialPageRoute(builder: (context) => ShopScreen(category: '')),
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
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Productos'),
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
