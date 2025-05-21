import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:margarita/blocs/product_bloc.dart';
import 'package:margarita/blocs/product_event.dart';
import 'package:margarita/blocs/product_state.dart';
import 'package:margarita/models/product.dart';
import 'package:margarita/screens/cart.dart';
import 'package:margarita/screens/food_home.dart';
import 'package:margarita/screens/orderHistory.dart';
import 'package:margarita/screens/favourites.dart';
import 'package:margarita/screens/menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShopScreen extends StatefulWidget {
  final String? category;

  const ShopScreen({super.key, this.category});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final List<Map<String, dynamic>> cartItems = [];
  final List<Map<String, dynamic>> favoriteItems = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  final ScrollController _scrollController = ScrollController();
  String _categoryName = '';
  static const String baseUrl =
      'http://10.0.2.2:8000'; // Base URL for the emulator

  @override
  void initState() {
    super.initState();
    _loadInitialProducts();
    _fetchCategoryName();
    _setupScrollController();
  }

  void _loadInitialProducts() {
    context.read<ProductBloc>().add(FetchProducts(category: widget.category));
  }

  Future<void> _fetchCategoryName() async {
    print('Fetching category name for category: ${widget.category}');
    if (widget.category != null && widget.category!.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/category-name/${widget.category}'),
        );
        print(
          'Response status: ${response.statusCode}, body: ${response.body}',
        );
        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            if (data is Map<String, dynamic>) {
              setState(() {
                _categoryName =
                    data['name'] ??
                    (data['category'] != null
                        ? data['category']['name']
                        : null) ??
                    widget.category ??
                    'Tienda';
              });
              print('Category name set to: $_categoryName');
            } else {
              print('Error: Response is not a JSON object');
              setState(() {
                _categoryName = widget.category ?? 'Tienda';
              });
            }
          } catch (e) {
            print('JSON decode error: $e');
            setState(() {
              _categoryName = widget.category ?? 'Tienda';
            });
          }
        } else {
          print(
            'Failed to fetch category name: ${response.statusCode}, body: ${response.body}',
          );
          setState(() {
            _categoryName = widget.category ?? 'Tienda';
          });
        }
      } catch (e) {
        print('HTTP request error: $e');
        setState(() {
          _categoryName = widget.category ?? 'Tienda';
        });
      }
    } else {
      print('Category is null or empty, setting to Tienda');
      setState(() {
        _categoryName = 'Tienda';
      });
    }
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_scrollController.position.outOfRange) {
        final state = context.read<ProductBloc>().state;
        if (state is ProductLoaded &&
            !state.hasReachedMax &&
            state.nextPageUrl != null) {
          context.read<ProductBloc>().add(LoadMoreProducts(state.nextPageUrl!));
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existingIndex = cartItems.indexWhere(
        (cartItem) => cartItem['name'] == item['name'],
      );

      if (existingIndex != -1) {
        cartItems[existingIndex]['quantity'] =
            (cartItems[existingIndex]['quantity'] as int) + 1;
      } else {
        cartItems.add({...item, 'quantity': 1});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} añadido al carrito!')),
    );
  }

  void _toggleFavorite(Map<String, dynamic> item) {
    setState(() {
      final itemName = item['name'] as String;
      final existingIndex = favoriteItems.indexWhere(
        (fav) => fav['name'] == itemName,
      );

      if (existingIndex != -1) {
        favoriteItems.removeAt(existingIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName eliminado de favoritos!')),
        );
      } else {
        favoriteItems.add(item);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName añadido a favoritos!')),
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
    if (searchTerm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, introduce un término de búsqueda'),
        ),
      );
      return;
    }
    context.read<ProductBloc>().add(SearchProducts(query: searchTerm));
  }

  List<Map<String, dynamic>> _getFilteredItems(
    String tabCategory,
    List<Product> products,
  ) {
    const tabToCategory = {
      'Clásicos': ['Italian', 'Pizza', 'Burgers', 'Tacos'],
      'Snacks': ['Snacks'],
      'Bebidas': ['Drinks'],
      'Postres': ['Desserts'],
    };

    final productMaps =
        products.map((product) {
          return {
            'id': product.id,
            'category': product.category,
            'imageUrl': product.image,
            'name': product.name,
            'description': product.description,
            'price':
                product.price != null
                    ? '\$${product.price!.toStringAsFixed(2)}'
                    : 'Precio no disponible',
          };
        }).toList();

    if (tabCategory == 'Todos') {
      if (_categoryName != 'Tienda' &&
          widget.category != null &&
          widget.category!.isNotEmpty) {
        return productMaps;
      }
      return productMaps;
    }

    final categories = tabToCategory[tabCategory] ?? [];
    return productMaps
        .where((item) => categories.contains(item['category']))
        .toList();
  }

  static const tabs = [
    Tab(text: 'Todos'),
    Tab(text: 'Clásicos'),
    Tab(text: 'Snacks'),
    Tab(text: 'Bebidas'),
    Tab(text: 'Postres'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          title:
              _showSearch
                  ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _toggleSearch,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  )
                  : Text(
                    _categoryName.isNotEmpty ? _categoryName : 'Tienda',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.orange),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
                            if (result != null && result is List) {
                              setState(
                                () =>
                                    cartItems
                                      ..clear()
                                      ..addAll(
                                        result.cast<Map<String, dynamic>>(),
                                      ),
                              );
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
            tabs: tabs,
          ),
        ),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading && state.isInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProductError) {
              return _buildErrorWidget(state.message);
            } else if (state is ProductLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  _loadInitialProducts();
                  return Future.delayed(const Duration(seconds: 1));
                },
                child: TabBarView(
                  children:
                      tabs
                          .asMap()
                          .entries
                          .map(
                            (entry) =>
                                _buildTabContent(tabs[entry.key].text!, state),
                          )
                          .toList(),
                ),
              );
            }
            return Center(
              child: Text('No hay productos disponibles para $_categoryName'),
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          currentIndex: 1,
          onTap: (index) {
            if (index == 1) return;
            final pages = [
              FoodHomeScreen(),
              null, // current
              OrderHistoryScreen(),
              FavouritesScreen(favorites: favoriteItems),
              MenuScreen(),
            ];
            if (pages[index] != null) {
              Navigator.pushReplacement(
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
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menú'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String tabCategory, ProductLoaded state) {
    final filteredItems = _getFilteredItems(tabCategory, state.products);
    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          'No hay productos disponibles para $tabCategory${_categoryName.isNotEmpty && _categoryName != 'Tienda' ? ' ($_categoryName)' : ''}',
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredItems.length + (state.hasReachedMax ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == filteredItems.length && !state.hasReachedMax) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = filteredItems[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildFoodItem(
            imageUrl: item['imageUrl'] as String,
            name: item['name'] as String,
            description: item['description'] as String,
            price: item['price'] as String,
            isFavorite: favoriteItems.any((fav) => fav['name'] == item['name']),
            onAdd: () => _addToCart(item),
            onFavorite: () => _toggleFavorite(item),
          ),
        );
      },
    );
  }

  Widget _buildFoodItem({
    required String imageUrl,
    required String name,
    required String description,
    required String price,
    required bool isFavorite,
    required VoidCallback onAdd,
    required VoidCallback onFavorite,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget:
                  (context, url, error) => const Icon(
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
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: onFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Añadir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadInitialProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
