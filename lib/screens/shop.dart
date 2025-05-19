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
    'Japonesa': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1528731708534-816fe59f90cb',
        'name': 'Sushi',
        'description': 'Variedad de sushi fresco',
        'price': '15,00 €',
      },
    ],
    'Americana': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
        'name': 'Cheeseburger',
        'description': 'Lleva queso, lechuga y tomate',
        'price': '9,50 €',
      },
    ],
    'Mexicana': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1523049673857-eb18f78959f8',
        'name': 'Tacos',
        'description': 'Tacos con carne y salsa',
        'price': '8,00 €',
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
        existing['quantity'] += 1;
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

  List<Map<String, dynamic>> _getFilteredItems() {
    if (widget.category.isEmpty) {
      final seen = <String>{};
      return categoryItems.values.expand((items) => items).where((item) {
        final name = item['name'];
        if (seen.contains(name)) return false;
        seen.add(name);
        return true;
      }).toList();
    } else {
      return categoryItems[widget.category] ?? [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(100.0),
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
                          icon: Icon(Icons.close),
                          onPressed: _toggleSearch,
                        ),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    )
                    : Text(
                      widget.category.isEmpty ? 'Tienda' : widget.category,
                      style: TextStyle(
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
                        icon: Icon(Icons.search, color: Colors.orange),
                        onPressed: _performSearch,
                      ),
                    ]
                    : [
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.orange),
                        onPressed: _toggleSearch,
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
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
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
            bottom: TabBar(
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
            ListView(
              padding: EdgeInsets.all(16.0),
              children:
                  filteredItems
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildFoodItem(
                            imageUrl: item['imageUrl'],
                            name: item['name'],
                            description: item['description'],
                            price: item['price'],
                            onAdd: () => _addToCart(item),
                          ),
                        ),
                      )
                      .toList(),
            ),
            Center(child: Text('Snacks Tab')),
            Center(child: Text('Bebidas Tab')),
            Center(child: Text('Postres Tab')),
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

  Widget _buildFoodItem({
    required String imageUrl,
    required String name,
    required String description,
    required String price,
    required VoidCallback onAdd,
  }) {
    final isFavorite = favoriteItems.contains(name);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) =>
                      Icon(Icons.fastfood, size: 80, color: Colors.orange),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
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
                SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text(price, style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
