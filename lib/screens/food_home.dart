import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:margarita/screens/shop.dart';
import 'package:margarita/screens/menu.dart';
import 'package:margarita/screens/orderHistory.dart';
import 'package:margarita/screens/favourites.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // List of slider items
  final List<Map<String, dynamic>> sliderItems = [
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1513106580091-1d82408b8f8a',
      'title': '¡Pizza con 30% de descuento!',
      'onTap': (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopScreen(category: 'Pizza'),
          ),
        );
      },
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
      'title': '¡Hamburguesas irresistibles!',
      'onTap': (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopScreen(category: 'Hamburguesas'),
          ),
        );
      },
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1523049673857-eb18f78959f8',
      'title': '¡Tacos al mejor precio!',
      'onTap': (BuildContext context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopScreen(category: 'Tacos'),
          ),
        );
      },
    },
  ];

  // Define categories with their respective products and ShopScreen category mapping
  final List<Map<String, dynamic>> categories = [
    {
      'shopCategory': 'Pizza', // Maps to ShopScreen category
      'products': [
        {
          'imageUrl':
              'https://images.unsplash.com/photo-1513106580091-1d82408b8f8a',
          'name': 'Pizza',
        },
      ],
    },
    {
      'shopCategory': 'Postres', // Replaced Sushi with Postres
      'products': [
        {
          'imageUrl':
              'https://images.unsplash.com/photo-1576618141411-753f2356c48c',
          'name': 'Postres',
        },
      ],
    },
    {
      'shopCategory': 'Hamburguesas',
      'products': [
        {
          'imageUrl':
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
          'name': 'Burger',
        },
      ],
    },
    {
      'shopCategory': 'Tacos',
      'products': [
        {
          'imageUrl':
              'https://images.unsplash.com/photo-1523049673857-eb18f78959f8',
          'name': 'Tacos',
        },
      ],
    },
  ];

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
        MaterialPageRoute(builder: (context) => FavouritesScreen()),
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
                CarouselSlider(
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
                                margin: EdgeInsets.symmetric(horizontal: 5.0),
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
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        item['imageUrl'],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 180,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.local_pizza,
                                                  size: 100,
                                                  color: Colors.orange,
                                                ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
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
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildCategorySection(categories[0])),
                        SizedBox(width: 16),
                        Expanded(child: _buildCategorySection(categories[1])),
                      ],
                    ),
                    SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: _buildCategorySection(categories[2])),
                        SizedBox(width: 16),
                        Expanded(child: _buildCategorySection(categories[3])),
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
    // Use shopCategory for navigation to ShopScreen
    String shopCategory = category['shopCategory'];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopScreen(category: shopCategory),
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
              child: Image.network(
                imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.fastfood,
                        size: 60,
                        color: Colors.orange,
                      ),
                    ),
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
