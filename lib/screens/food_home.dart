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
  bool _hasShownLocationPopup = false;
  String _currentAddress = '123 Main St, Cityville';
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> sliderItems = [];
  bool _isSliderLoading = true;
  String? _sliderErrorMessage;
  final String baseUrl = 'https://remoto.digital'; // Base URL for the emulator

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownLocationPopup) {
        _showLocationPopup();
        _hasShownLocationPopup = true;
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          final List<dynamic> data = responseData['data'];
          setState(() {
            sliderItems =
                data.map((slider) {
                  // Check if the image is a full URL or a relative path
                  String imageUrl;
                  if (slider['image'].startsWith('http')) {
                    // If it's a full URL, replace 127.0.0.1 with 10.0.2.2 for emulator access
                    imageUrl = slider['image'].replaceFirst(
                      'http://127.0.0.1:8000',
                      baseUrl,
                    );
                  } else {
                    // If it's a relative path, prepend the base URL
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

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
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
                  'category_id': category['id'].toString(), // Store category_id
                  'name': category['name'], // Store name for display
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
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
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

  Future<Position?> _getUserLocation() async {
    var permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        return position;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener la ubicación: $e')),
        );
        return null;
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Permiso de ubicación denegado')));
      return null;
    }
  }

  Future<String> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      Placemark place = placemarks[0];
      return '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener la dirección: $e')),
      );
      return 'Dirección no disponible';
    }
  }

  Future<void> _shareLocationViaWhatsApp(
    double latitude,
    double longitude,
    String address,
  ) async {
    String googleMapsLink =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    String message =
        'Hola, aquí está mi ubicación para el envío:\n$address\n$googleMapsLink';
    String whatsappUrl = 'whatsapp://send?text=${Uri.encodeFull(message)}';
    String fallbackUrl = 'https://wa.me/?text=${Uri.encodeFull(message)}';

    try {
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
              onPressed: () {
                Navigator.of(context).pop();
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
                  Position? position = await _getUserLocation();
                  if (position != null) {
                    String address = await _getAddressFromCoordinates(
                      position.latitude,
                      position.longitude,
                    );
                    setState(() {
                      _currentAddress = address;
                    });
                    await _shareLocationViaWhatsApp(
                      position.latitude,
                      position.longitude,
                      address,
                    );
                  }
                } catch (e) {
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
