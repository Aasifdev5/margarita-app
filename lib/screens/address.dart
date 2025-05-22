import 'package:flutter/material.dart';
import 'package:margarita/screens/menu.dart';
import 'package:margarita/screens/shop.dart';
import 'package:margarita/screens/food_home.dart';
import 'package:margarita/screens/orderHistory.dart';
import 'package:margarita/screens/favourites.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:margarita/services/api_service.dart';

class AddressScreen extends StatefulWidget {
  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/api/addresses');
      print('Addresses response: $response');

      setState(() {
        _addresses = List<Map<String, dynamic>>.from(response['addresses']);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading addresses: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar direcciones: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, habilita los servicios de ubicación'),
          ),
        );
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permisos de ubicación denegados')),
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permisos de ubicación denegados permanentemente'),
          ),
        );
        return null;
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
        return {
          'street': place.street ?? 'Calle desconocida',
          'city':
              '${place.locality ?? ''}${place.locality != null && place.country != null ? ', ' : ''}${place.country ?? ''}',
          'coordinates': '${position.latitude},${position.longitude}',
        };
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener la ubicación: $e')),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }

    return null;
  }

  Future<void> _addAddress(Map<String, dynamic> addressData) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post('/api/addresses', addressData);

      if (response['statusCode'] == 201) {
        await _loadAddresses();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('¡Dirección agregada!')));
      } else {
        throw Exception(
          response['body']['message'] ?? 'Error al agregar dirección',
        );
      }
    } catch (e) {
      print('Error adding address: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al agregar dirección: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAddress(
    int addressId,
    Map<String, dynamic> addressData,
  ) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.put(
        '/api/addresses/$addressId',
        addressData,
      );

      if (response['statusCode'] == 200) {
        await _loadAddresses();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('¡Dirección actualizada!')));
      } else {
        throw Exception(
          response['body']['message'] ?? 'Error al actualizar dirección',
        );
      }
    } catch (e) {
      print('Error updating address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar dirección: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(int addressId) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.delete('/api/addresses/$addressId');

      if (response['statusCode'] == 200) {
        await _loadAddresses();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('¡Dirección eliminada!')));
      } else {
        throw Exception(
          response['body']['message'] ?? 'Error al eliminar dirección',
        );
      }
    } catch (e) {
      print('Error deleting address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar dirección: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showAddressDialog({Map<String, dynamic>? address}) {
    final isEditing = address != null;
    final labelController = TextEditingController(
      text: isEditing ? address['label'] : '',
    );
    final streetController = TextEditingController(
      text: isEditing ? address['street'] : '',
    );
    final cityController = TextEditingController(
      text: isEditing ? address['city'] : '',
    );
    bool isDefault = isEditing ? address['is_default'] ?? false : false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Dirección' : 'Agregar Dirección'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        labelText: 'Etiqueta (por ejemplo, Casa, Trabajo)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: streetController,
                      decoration: InputDecoration(
                        labelText: 'Dirección de la Calle',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: cityController,
                      decoration: InputDecoration(
                        labelText: 'Ciudad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          activeColor: Colors.orange,
                          onChanged: (value) {
                            setState(() {
                              isDefault = value ?? false;
                            });
                          },
                        ),
                        Flexible(
                          child: Text(
                            'Establecer como dirección predeterminada',
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final location = await _getCurrentLocation();
                        if (location != null) {
                          streetController.text = location['street']!;
                          cityController.text = location['city']!;
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child:
                          _isGettingLocation
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                'Usar Ubicación Actual',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    final addressData = {
                      'label': labelController.text.trim(),
                      'street': streetController.text.trim(),
                      'city': cityController.text.trim(),
                      'coordinates':
                          isEditing ? address['coordinates'] : '0.0,0.0',
                      'is_default': isDefault,
                    };

                    if (addressData['label']!.isEmpty ||
                        addressData['street']!.isEmpty ||
                        addressData['city']!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Por favor, completa todos los campos'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context).pop();

                    if (isEditing) {
                      _updateAddress(address['id'], addressData);
                    } else {
                      _addAddress(addressData);
                    }
                  },
                  child: Text(
                    isEditing ? 'Actualizar' : 'Agregar',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAddress(Map<String, dynamic> address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Dirección'),
          content: Text(
            '¿Estás seguro de que quieres eliminar esta dirección?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAddress(address['id']);
              },
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
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
        title: Text(
          'Dirección',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MenuScreen()),
              ),
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.orange))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _showAddressDialog(),
                        icon: Icon(Icons.add, color: Colors.orange),
                        label: Text(
                          'Agregar Nueva Dirección',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child:
                          _addresses.isEmpty
                              ? Center(
                                child: Text(
                                  'No se encontraron direcciones. ¡Agrega una nueva dirección!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                              : RefreshIndicator(
                                onRefresh: _loadAddresses,
                                child: ListView.builder(
                                  itemCount: _addresses.length,
                                  itemBuilder: (context, index) {
                                    final address = _addresses[index];
                                    return Card(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      margin: EdgeInsets.only(bottom: 16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          address['label'],
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.black,
                                                          ),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                      if (address['is_default'] ==
                                                          true)
                                                        Container(
                                                          margin:
                                                              EdgeInsets.only(
                                                                left: 8,
                                                              ),
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors.orange,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            'Predeterminada',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.edit,
                                                        color: Colors.orange,
                                                      ),
                                                      onPressed:
                                                          () =>
                                                              _showAddressDialog(
                                                                address:
                                                                    address,
                                                              ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed:
                                                          () =>
                                                              _confirmDeleteAddress(
                                                                address,
                                                              ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              address['street'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              address['city'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Coordenadas: ${address['coordinates']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 4,
        onTap: (index) => _onBottomNavItemTapped(index),
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

  void _onBottomNavItemTapped(int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = FoodHomeScreen();
        break;
      case 1:
        screen = ShopScreen(category: '');
        break;
      case 2:
        screen = OrderHistoryScreen();
        break;
      case 3:
        screen = FavouritesScreen(favorites: []);
        break;
      case 4:
        screen = MenuScreen();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
