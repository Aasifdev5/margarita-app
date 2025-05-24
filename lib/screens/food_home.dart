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
import 'package:url_launcher/url_launcher.dart';
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
  final String baseUrl = 'https://remoto.digital'; // Base URL for the emulator
  final bool useRealLocation = false; // Toggle for real vs. hardcoded location
  String? _authToken; // Store the authentication token

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

    // Fetch categories and sliders from API
    _fetchCategories();
    _fetchSliders();

    // Load auth token and check location popup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        // Load token (replace with your actual token retrieval logic)
        _authToken = prefs.getString('auth_token');
        print('Loaded auth token: $_authToken');
        bool hasShownLocationPopup =
            prefs.getBool('hasShownLocationPopup') ?? false;
        if (!hasShownLocationPopup) {
          _showLocationPopup();
        }
      } catch (e) {
        print('Error checking SharedPreferences: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al verificar preferencias: $e')),
        );
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
                  String imageUrl;
                  if (slider['image'].startsWith('http')) {
                    imageUrl = slider['image'].replaceFirst(
                      'http://127.0.0.1:8000',
                      baseUrl,
                    );
                  } else {
                    imageUrl = '$baseUrl/${slider['image']}';
                  }
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
                String imagePath = category['image'];
                if (imagePath.contains('storage/')) {
                  print('Warning: Image path contains /storage/: $imagePath');
                  imagePath = imagePath.replaceFirst('storage/', '');
                }
                String imageUrl = '$baseUrl/$imagePath';
                print('Category Image URL: $imageUrl');
                return {
                  'category_id': category['id'].toString(),
                  'name': category['name'],
                  'products': [
                    {'imageUrl': imageUrl, 'name': category['name']},
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

  Future<void> _saveAddressToApi(
    String label,
    String street,
    String city,
    String coordinates,
  ) async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, inicia sesión para guardar la dirección'),
        ),
      );
      // Optionally navigate to login screen
      // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
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
      print('AddressesCHER API response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _currentAddress =
              '${responseData['address']['street']}, ${responseData['address']['city']}';
        });
        // Mark popup as shown
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasShownLocationPopup', true);
        print('Address saved successfully: $_currentAddress');
      } else if (response.statusCode == 302) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Redirección detectada. Por favor, verifica tu sesión',
            ),
          ),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sesión inválida. Por favor, inicia sesión nuevamente',
            ),
          ),
        );
        // Optionally clear token and navigate to login screen
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        _authToken = null;
        // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      } else if (response.statusCode == 422) {
        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body);
          final errors = responseData['errors'] ?? {};
          String errorMsg =
              errors.isNotEmpty
                  ? errors.entries
                      .map((e) => '${e.key}: ${e.value.join(', ')}')
                      .join('; ')
                  : responseData['message'] ?? 'Validation error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de validación: $errorMsg')),
          );
        } catch (e) {
          print('Error decoding validation response: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al procesar la respuesta del servidor'),
            ),
          );
        }
      } else {
        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          responseData = {};
          print('Error decoding API response: $e');
        }
        final errorMsg =
            responseData['message'] ?? 'Status code: ${response.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la dirección: $errorMsg')),
        );
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
        SnackBar(content: Text('Por favor, ingresa un término de búsqueda')),
      );
    }
  }

  Future<Map<String, dynamic>?> _getUserLocationData() async {
    if (useRealLocation) {
      // Future implementation with real location
      var permissionStatus = await Permission.location.request();
      if (permissionStatus.isGranted) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          Placemark place = placemarks[0];
          String address =
              '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
          return {
            'street': place.street ?? 'Unknown Street',
            'city': place.locality ?? 'Unknown City',
            'coordinates': '${position.latitude},${position.longitude}',
            'address': address,
          };
        } catch (e) {
          print('Error getting real location: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al obtener la ubicación: $e')),
          );
          return null;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permiso de ubicación denegado')),
        );
        return null;
      }
    } else {
      // Hardcoded location data
      print('Using hardcoded location data');
      return {
        'street': '123 Main Street',
        'city': 'Cityville',
        'coordinates':
            '40.7128,-74.0060', // Example coordinates (New York City)
        'address': '123 Main Street, Cityville',
      };
    }
  }

  Future<void> _shareLocationViaWhatsApp(
    String address,
    String coordinates,
  ) async {
    try {
      List<String> coords = coordinates.split(',');
      double latitude = double.parse(coords[0]);
      double longitude = double.parse(coords[1]);
      String googleMapsLink =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      String message =
          'Hola, aquí está mi ubicación para el envío:\n$address\n$googleMapsLink';
      String whatsappUrl = 'whatsapp://send?text=${Uri.encodeFull(message)}';
      String fallbackUrl = 'https://wa.me/?text=${Uri.encodeFull(message)}';

      print('Attempting to share location via WhatsApp: $message');

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      } else if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
        await launchUrl(
          Uri.parse(fallbackUrl),
          mode: LaunchMode.platformDefault,
        );
      } else {
        throw 'No se pudo abrir WhatsApp ni el navegador.';
      }
    } catch (e) {
      print('Error sharing location via WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al intentar abrir WhatsApp. Asegúrate de tener WhatsApp instalado.',
          ),
        ),
      );
    }
  }

  void _showLocationPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.orange,
          content: Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              onPressed: () async {
                try {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setBool('hasShownLocationPopup', true);
                  print('Location popup dismissed, flag set to true');
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error setting SharedPreferences: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al cerrar el popup: $e')),
                  );
                }
              },
              child: Text(
                'X',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Map<String, dynamic>? locationData =
                      await _getUserLocationData();
                  if (locationData != null) {
                    // Save address to API
                    await _saveAddressToApi(
                      'Home',
                      locationData['street'],
                      locationData['city'],
                      locationData['coordinates'],
                    );
                    // Share via WhatsApp
                    await _shareLocationViaWhatsApp(
                      locationData['address'],
                      locationData['coordinates'],
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('No se pudo obtener la ubicación'),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error in location popup action: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al activar la ubicación: $e'),
                    ),
                  );
                } finally {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Activar',
                style: TextStyle(
                  color: Colors.orange,
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
                      icon: Icon(Icons.close),
                      onPressed: _toggleSearch,
                    ),
                  ),
                  onSubmitted: (value) => _performSearch(),
                )
                : GestureDetector(
                  onTap: _showLocationPopup,
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange, size: 24),
                      SizedBox(width: 8),
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
                              style: TextStyle(
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
            icon: Icon(Icons.search, color: Colors.orange, size: 28),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isSliderLoading
                    ? Center(child: CircularProgressIndicator())
                    : _sliderErrorMessage != null
                    ? Center(
                      child: Column(
                        children: [
                          Text(
                            _sliderErrorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _fetchSliders,
                            child: Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                    : sliderItems.isEmpty
                    ? Center(child: Text('No se encontraron sliders'))
                    : CarouselSlider(
                      options: CarouselOptions(
                        height: 180,
                        autoPlay: true,
                        autoPlayInterval: Duration(seconds: 3),
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
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
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
                                                (context, url) => Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            errorWidget: (context, url, error) {
                                              print(
                                                'Slider image loading error for $url: $error',
                                              );
                                              return Icon(
                                                Icons.local_pizza,
                                                size: 100,
                                                color: Colors.orange,
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
                                                style: TextStyle(
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
                SizedBox(height: 24),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _fetchCategories,
                            child: Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                    : categories.isEmpty
                    ? Center(child: Text('No se encontraron categorías'))
                    : Column(
                      children: [
                        Row(
                          children: [
                            if (categories.length > 0)
                              Expanded(
                                child: _buildCategorySection(categories[0]),
                              ),
                            if (categories.length > 1) SizedBox(width: 16),
                            if (categories.length > 1)
                              Expanded(
                                child: _buildCategorySection(categories[1]),
                              ),
                          ],
                        ),
                        if (categories.length > 2) SizedBox(height: 32),
                        if (categories.length > 2)
                          Row(
                            children: [
                              if (categories.length > 2)
                                Expanded(
                                  child: _buildCategorySection(categories[2]),
                                ),
                              if (categories.length > 3) SizedBox(width: 16),
                              if (categories.length > 3)
                                Expanded(
                                  child: _buildCategorySection(categories[3]),
                                ),
                            ],
                          ),
                      ],
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
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
    String categoryName = category['name'];
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) =>
                        Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) {
                  print('Category image loading error for $url: $error');
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[300],
                    child: Icon(Icons.fastfood, size: 60, color: Colors.orange),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
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
