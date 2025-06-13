import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:margarita/screens/shop.dart';
import 'package:margarita/screens/menu.dart';
import 'package:margarita/screens/orderHistory.dart';
import 'package:margarita/screens/favourites.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FoodHomeScreen extends StatefulWidget {
  @override
  _FoodHomeScreenState createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _currentAddress = '123 Main St, Cityville';
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> sliderItems = [];
  bool _isSliderLoading = true;
  String? _sliderErrorMessage;
  List<Map<String, dynamic>> _savedAddresses = [];
  bool _isLoadingLocation = false;
  final String baseUrl = 'https://remoto.digital';
  final bool useRealLocation = true;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _fetchCategories();
    _fetchSliders();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        _authToken = prefs.getString('auth_token');
        print('Loaded auth token: $_authToken');

        await _fetchSavedAddresses();
        bool hasDefaultAddress = _savedAddresses.any(
          (addr) => addr['is_default'] == true,
        );
        bool hasShownLocationPopup =
            prefs.getBool('hasShownLocationPopup') ?? false;
        print(
          'hasDefaultAddress: $hasDefaultAddress, hasShownLocationPopup: $hasShownLocationPopup',
        );

        if (!hasDefaultAddress && !hasShownLocationPopup) {
          print('Showing location popup (no default address)');
          _showLocationPopup();
        } else {
          print('Skipping location popup');
          setState(() {
            if (hasDefaultAddress) {
              final defaultAddress = _savedAddresses.firstWhere(
                (addr) => addr['is_default'] == true,
              );
              _currentAddress =
                  '${defaultAddress['street']}, ${defaultAddress['city']}';
            }
          });
        }
      } catch (e) {
        print('Error initializing: $e');
        setState(() {
          _currentAddress = 'Error al obtener ubicación';
        });
        bool hasDefaultAddress = _savedAddresses.any(
          (addr) => addr['is_default'] == true,
        );
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool hasShownLocationPopup =
            prefs.getBool('hasShownLocationPopup') ?? false;
        if (!hasDefaultAddress && !hasShownLocationPopup) {
          print('Showing location popup due to error (no default address)');
          _showLocationPopup();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSliders() async {
    setState(() {
      _isSliderLoading = true;
      _sliderErrorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sliders'));
      print('Sliders API response status: ${response.statusCode}');
      print('Sliders API response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> data = responseData['data'];
          setState(() {
            sliderItems =
                data.map((slider) {
                  String imageUrl =
                      slider['image'].startsWith('http')
                          ? slider['image'].replaceFirst(
                            'http://127.0.0.1:8000',
                            baseUrl,
                          )
                          : '$baseUrl/${slider['image']}';
                  print('Slider Image URL: $imageUrl');
                  return {
                    'imageUrl': imageUrl,
                    'title': slider['title1'],
                    'onTap': (BuildContext context) {
                      final categoryId = slider['link'].split('/').last;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ShopScreen(category: categoryId),
                        ),
                      );
                    },
                  };
                }).toList();
            _isSliderLoading = false;
          });
        } else {
          setState(() {
            _sliderErrorMessage =
                'Error al cargar los sliders: ${responseData['message']}';
            _isSliderLoading = false;
          });
        }
      } else {
        setState(() {
          _sliderErrorMessage =
              'Error al cargar los sliders: ${response.statusCode}';
          _isSliderLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching sliders: $e');
      setState(() {
        _sliderErrorMessage = 'Error de conexión: $e';
        _isSliderLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/categories'));
      print('Categories API response status: ${response.statusCode}');
      print('Categories API response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          categories =
              data.map((category) {
                String imagePath =
                    category['image']?.replaceFirst('storage/', '') ??
                    'default.jpg';
                String imageUrl = '$baseUrl/$imagePath';
                print('Category Image URL: $imageUrl');
                return {
                  'category_id': category['id']?.toString() ?? '0',
                  'name': category['name'] ?? 'Sin nombre',
                  'products': [
                    {
                      'imageUrl': imageUrl,
                      'name': category['name'] ?? 'Sin nombre',
                    },
                  ],
                };
              }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Error al cargar las categorías: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSavedAddresses() async {
    if (_authToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/addresses'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
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
                };
              }).toList();
        });
      } else {
        print('Failed to fetch addresses: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching addresses: $e');
    }
  }

  Future<void> _saveAddressToApi(
    String label,
    String street,
    String city,
    String coordinates,
  ) async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, inicia sesión para guardar la dirección'),
        ),
      );
      return;
    }

    try {
      final requestBody = {
        'label': label,
        'street': street,
        'city': city,
        'coordinates': coordinates,
        'is_default': true,
      };
      print('Saving address to API: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/api/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('Addresses API response status: ${response.statusCode}');
      print('Addresses API response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _currentAddress =
              '${responseData['address']['street']}, ${responseData['address']['city']}';
          _savedAddresses.add({
            'id': responseData['address']['id'].toString(),
            'label': responseData['address']['label'],
            'street': responseData['address']['street'],
            'city': responseData['address']['city'],
            'coordinates': responseData['address']['coordinates'],
            'is_default': responseData['address']['is_default'] ?? false,
          });
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasShownLocationPopup', true);
        await prefs.setString('lastAddress', _currentAddress);
        print('Address saved successfully: $_currentAddress');
      } else {
        String errorMsg =
            'Error al guardar la dirección: ${response.statusCode}';
        if (response.statusCode == 302) {
          errorMsg = 'Redirección detectada. Por favor, verifica tu sesión';
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          errorMsg = 'Sesión inválida. Por favor, inicia sesión nuevamente';
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          _authToken = null;
        } else if (response.statusCode == 422) {
          final responseData = jsonDecode(response.body);
          final errors = responseData['errors'] ?? {};
          errorMsg =
              errors.isNotEmpty
                  ? errors.entries
                      .map((e) => '${e.key}: ${e.value.join(', ')}')
                      .join('; ')
                  : responseData['message'] ?? 'Validation error';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      print('Error saving address to API: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión al guardar la dirección: $e'),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Already on FoodHomeScreen
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ShopScreen(category: '')),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FavouritesScreen(favorites: []),
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MenuScreen()),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
      }
    });
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buscando "${_searchController.text}"...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un término de búsqueda'),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _getUserLocationData() async {
    if (!useRealLocation) {
      print('Using hardcoded location data');
      return {
        'street': '123 Main Street',
        'city': 'Cityville',
        'coordinates': '40.7128,-74.0060',
        'address': '123 Main Street, Cityville',
      };
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Por favor, habilita los servicios de ubicación',
            ),
            action: SnackBarAction(
              label: 'Configuración',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return null;
      }

      var permissionStatus = await Permission.location.status;
      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.location.request();
        if (permissionStatus.isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permiso de ubicación denegado'),
              action: SnackBarAction(
                label: 'Configuración',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
          return null;
        }
      }
      if (permissionStatus.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permiso de ubicación denegado permanentemente',
            ),
            action: SnackBarAction(
              label: 'Configuración',
              onPressed: () => openAppSettings(),
            ),
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
      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();
      String street = place.street ?? 'Calle desconocida';
      String city = place.locality ?? 'Ciudad desconocida';
      String subLocality = place.subLocality ?? '';
      String postalCode = place.postalCode ?? '';
      String country = place.country ?? '';
      String name = place.name ?? '';

      List<String> addressParts = [];
      if (name.isNotEmpty && name != street && name != subLocality)
        addressParts.add(name);
      if (street.isNotEmpty) addressParts.add(street);
      if (subLocality.isNotEmpty) addressParts.add(subLocality);
      String fullStreetAddress = addressParts.join(',').trim();
      if (fullStreetAddress.isEmpty)
        fullStreetAddress = 'Dirección desconocida';

      List<String> displayAddressParts = List.from(addressParts);
      if (city.isNotEmpty) displayAddressParts.add(city);
      if (postalCode.isNotEmpty) displayAddressParts.add(postalCode);
      if (country.isNotEmpty) displayAddressParts.add(country);
      String address = displayAddressParts.join(', ').trim();
      if (address.isEmpty) address = 'Ubicación desconocida';

      return {
        'street': fullStreetAddress,
        'city': city,
        'coordinates': '${position.latitude},${position.longitude}',
        'address': address,
      };
    } catch (e) {
      print('Error getting real location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener la ubicación: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showLocationPopup() {
    print('Displaying location popup');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Color(0xFFFF8901),
          content: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ACTIVA TU UBICACIÓN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Comparte tu ubicación para realizar el envío',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('Location popup dismissed');
                Navigator.of(context).pop();
              },
              child: const Text(
                'X',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed:
                  _isLoadingLocation
                      ? null
                      : () async {
                        try {
                          Map<String, dynamic>? locationData =
                              await _getUserLocationData();
                          if (locationData != null) {
                            await _saveAddressToApi(
                              'Home',
                              locationData['street'],
                              locationData['city'],
                              locationData['coordinates'],
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo obtener la ubicación',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error in location popup action: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al activar la ubicación: $e',
                              ),
                            ),
                          );
                        } finally {
                          Navigator.of(context).pop();
                        }
                      },
              child: const Text(
                'Activar',
                style: TextStyle(
                  color: Color(0xFFFF8901),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
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
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
        title:
            _showSearch
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar comida...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _toggleSearch,
                    ),
                  ),
                  onSubmitted: (value) => _performSearch(),
                )
                : GestureDetector(
                  onTap: _showLocationPopup,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFFF8901),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entregar en',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _currentAddress,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFFF8901), size: 28),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _isSliderLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _sliderErrorMessage != null
                    ? Center(
                      child: Column(
                        children: [
                          Text(
                            _sliderErrorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _fetchSliders,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                    : CarouselSlider(
                      options: CarouselOptions(
                        height: 180,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 3),
                        enlargeCenterPage: true,
                        viewportFraction: 0.9,
                        aspectRatio: 2.0,
                      ),
                      items:
                          sliderItems.map((item) {
                            return Builder(
                              builder: (BuildContext context) {
                                return GestureDetector(
                                  onTap: () => item['onTap'](context),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: item['imageUrl'],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 180,
                                            placeholder:
                                                (context, url) => const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            errorWidget: (context, url, error) {
                                              print(
                                                'Slider image loading error for $url: $error',
                                              );
                                              return const Icon(
                                                Icons.local_pizza,
                                                size: 100,
                                                color: Color(0xFFFF8901),
                                              );
                                            },
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black.withOpacity(0.6),
                                                Colors.transparent,
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['title'],
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                    ),
                const SizedBox(height: 16),
                const Text(
                  '¿Qué vamos a pedir hoy?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8901),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _fetchCategories,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                    : categories.isEmpty
                    ? const Center(child: Text('No se encontraron categorías'))
                    : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (categories.length / 2).ceil(),
                      itemBuilder: (context, index) {
                        int firstIndex = index * 2;
                        int secondIndex = firstIndex + 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (firstIndex < categories.length)
                                Expanded(
                                  child: _buildCategorySection(
                                    categories[firstIndex],
                                  ),
                                ),
                              if (secondIndex < categories.length)
                                const SizedBox(width: 16),
                              if (secondIndex < categories.length)
                                Expanded(
                                  child: _buildCategorySection(
                                    categories[secondIndex],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFFF8901),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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

  Widget _buildCategorySection(Map<String, dynamic> category) {
    String categoryId = category['category_id'];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopScreen(category: categoryId),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  (category['products'] as List<Map<String, dynamic>>)
                      .asMap()
                      .entries
                      .map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> product = entry.value;
                        bool isLastItem =
                            index == (category['products'] as List).length - 1;
                        return Padding(
                          padding: EdgeInsets.only(
                            right: isLastItem ? 0 : 16.0,
                            left: 16.0,
                          ),
                          child: _buildFoodCard(
                            imageUrl: product['imageUrl'],
                            label: product['name'],
                          ),
                        );
                      })
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard({required String imageUrl, required String label}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) {
                    print('Category image loading error for $url: $error');
                    return Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.fastfood,
                        size: 60,
                        color: Color(0xFFFF8901),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8901),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
