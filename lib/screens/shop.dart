import 'package:flutter/material.dart';
import 'package:margarita/screens/cart.dart';
import 'package:margarita/screens/menu.dart';
import 'package:margarita/screens/food_home.dart';
import 'package:margarita/screens/orderHistory.dart';
import 'package:margarita/screens/favourites.dart';

class ShopScreen extends StatefulWidget {
  final String category;

  const ShopScreen({Key? key, this.category = ''}) : super(key: key);

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Map<String, dynamic>> cartItems = [];
  List<String> favoriteItems = [];
  TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  final Map<String, List<Map<String, dynamic>>> categoryItems = {
    'Italiana': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1513106580091-1d82408b8f8a',
        'name': 'Pizza Margarita',
        'description': 'Tomate, mozzarella y albahaca',
        'price': '12,00 €',
      },
    ],
    'Pizza': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1513106580091-1d82408b8f8a',
        'name': 'Pizza Margarita',
        'description': 'Tomate, mozzarella y albahaca',
        'price': '12,00 €',
      },
    ],
    'Hamburguesas': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
        'name': 'Cheeseburger',
        'description': 'Lleva queso, lechuga y tomate',
        'price': '9,50 €',
      },
    ],
    'Tacos': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1523049673857-eb18f78959f8',
        'name': 'Tacos',
        'description': 'Tacos con carne y salsa',
        'price': '8,00 €',
      },
    ],
    'Snacks': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1626700051175-9f77c845a7e0',
        'name': 'Papas Fritas',
        'description': 'Papas crujientes con salsa',
        'price': '4,50 €',
      },
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1629121520897-3472a6e4b1f0',
        'name': 'Nachos',
        'description': 'Nachos con queso fundido y jalapeños',
        'price': '6,00 €',
      },
    ],
    'Bebidas': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b',
        'name': 'Refresco',
        'description': 'Cola, limonada o naranja',
        'price': '2,50 €',
      },
      {
        'imageUrl': 'https://images.unsplash.com/photo-1544140708-514c08d36e72',
        'name': 'Agua Mineral',
        'description': 'Agua con o sin gas',
        'price': '1,50 €',
      },
    ],
    'Postres': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1576618141411-753f2356c48c',
        'name': 'Tarta de Queso',
        'description': 'Tarta cremosa con base de galleta',
        'price': '5,00 €',
      },
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1586789070921-31a080e3b4f0',
        'name': 'Helado',
        'description': 'Helado de vainilla o chocolate',
        'price': '3,50 €',
      },
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existing = cartItems.firstWhere(
        (cartItem) => cartItem['name'] == item['name'],
        orElse: () => {},
      );

      if (existing.isNotEmpty) {
        existing['quantity'] = (existing['quantity'] as int? ?? 0) + 1;
      } else {
        cartItems.add({...item, 'quantity': 1});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} agregado al carrito!')),
    );
  }

  void _toggleFavorite(String itemName) {
    setState(() {
      if (favoriteItems.contains(itemName)) {
        favoriteItems.remove(itemName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName eliminado de favoritos!')),
        );
      } else {
        favoriteItems.add(itemName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName agregado a favoritos!')),
        );
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) _searchController.clear();
    });
  }

  void _performSearch() {
    final searchTerm = _searchController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          searchTerm.isEmpty
              ? 'Por favor, ingresa un término de búsqueda'
              : 'Buscando "$searchTerm"...',
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredItems(String tabCategory) {
    print('Filtering for tab: $tabCategory, category: ${widget.category}');

    // Validate category
    if (widget.category.isNotEmpty &&
        !categoryItems.containsKey(widget.category)) {
      print('Invalid category: ${widget.category}');
      return [];
    }

    // If a specific category is passed, show only that category's items
    if (widget.category.isNotEmpty) {
      final items = categoryItems[widget.category] ?? [];
      final validItems = items.where(_isValidItem).toList();
      print('Specific category items for ${widget.category}: $validItems');
      return validItems;
    }

    // Map tabs to their respective categories
    final tabToCategory = {
      'Clásicos': ['Italiana', 'Pizza', 'Hamburguesas', 'Tacos'],
      'Snacks': ['Snacks'],
      'Bebidas': ['Bebidas'],
      'Postres': ['Postres'],
    };

    // Get items for the current tab's category
    final categories = tabToCategory[tabCategory] ?? [];
    final seen = <String>{};
    final items =
        categoryItems.entries
            .where((entry) => categories.contains(entry.key))
            .expand((entry) => entry.value)
            .where((item) {
              if (!_isValidItem(item)) {
                print('Invalid item found: $item');
                return false;
              }
              final name = item['name'] as String;
              if (seen.contains(name)) return false;
              seen.add(name);
              return true;
            })
            .toList();
    print('Tab $tabCategory items: $items');
    return items;
  }

  bool _isValidItem(Map<String, dynamic> item) {
    final isValid =
        item['imageUrl'] is String &&
        item['name'] is String &&
        item['description'] is String &&
        item['price'] is String &&
        item['imageUrl']?.isNotEmpty == true &&
        item['name']?.isNotEmpty == true &&
        item['description']?.isNotEmpty == true &&
        item['price']?.isNotEmpty == true;
    if (!isValid) {
      print('Invalid item: $item');
    }
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex =
        {
          'Italiana': 0,
          'Pizza': 0,
          'Hamburguesas': 0,
          'Tacos': 0,
          'Snacks': 1,
          'Bebidas': 2,
          'Postres': 3,
        }[widget.category] ??
        0;

    return DefaultTabController(
      length: 4,
      initialIndex: tabIndex,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 2,
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
                      onSubmitted: (_) => _performSearch(),
                    )
                    : Text(
                      widget.category.isEmpty ? 'Tienda' : widget.category,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
            centerTitle: true,
            actions:
                _showSearch
                    ? [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.orange),
                        onPressed: _performSearch,
                      ),
                    ]
                    : [
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.orange),
                        onPressed: _toggleSearch,
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.shopping_cart,
                              color: Colors.orange,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => CartScreen(cartItems: cartItems),
                                ),
                              );
                              if (result != null) {
                                setState(() => cartItems = result);
                              }
                            },
                          ),
                          if (cartItems.isNotEmpty)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Text(
                                  '${cartItems.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
            bottom: const TabBar(
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(text: 'Clásicos'),
                Tab(text: 'Snacks'),
                Tab(text: 'Bebidas'),
                Tab(text: 'Postres'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabContent('Clásicos'),
            _buildTabContent('Snacks'),
            _buildTabContent('Bebidas'),
            _buildTabContent('Postres'),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          currentIndex: 1,
          onTap: (index) {
            final pages = [
              FoodHomeScreen(),
              null, // current
              OrderHistoryScreen(),
              FavouritesScreen(),
              MenuScreen(),
            ];
            if (index != 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => pages[index]!),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Tienda'),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt),
              label: 'Pedidos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String tabCategory) {
    final filteredItems = _getFilteredItems(tabCategory);
    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          'No hay productos disponibles para $tabCategory${widget.category.isNotEmpty ? ' (${widget.category})' : ''}',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children:
          filteredItems.map((item) {
            // Safe access with fallbacks
            final imageUrl = item['imageUrl'] as String? ?? '';
            final name = item['name'] as String? ?? 'Unknown';
            final description = item['description'] as String? ?? '';
            final price = item['price'] as String? ?? '0,00 €';
            if (!_isValidItem(item)) {
              print('Skipping invalid item in build: $item');
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildFoodItem(
                imageUrl: imageUrl,
                name: name,
                description: description,
                price: price,
                onAdd: () => _addToCart(item),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildFoodItem({
    required String imageUrl,
    required String name,
    required String description,
    required String price,
    required VoidCallback onAdd,
  }) {
    final isFavorite = favoriteItems.contains(name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl.isEmpty ? 'https://via.placeholder.com/80' : imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => const Icon(
                    Icons.fastfood,
                    size: 80,
                    color: Colors.orange,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(name),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
