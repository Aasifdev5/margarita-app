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
import 'package:margarita/services/api_service.dart';

class ShopScreen extends StatefulWidget {
  final String? category; // Expected to be category_id (e.g., "30")

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
  static const String baseUrl = 'https://remoto.digital';
  List<String> _dynamicTabs = [];
  Map<String, String> _categoryMapping = {};

  @override
  void initState() {
    super.initState();
    print('ShopScreen initialized with category_id: ${widget.category}');
    _loadInitialProducts();
    _fetchCategoryName();
    _fetchCategories();
    _fetchFavorites();
    _fetchCart();
    _setupScrollController();
  }

  void _loadInitialProducts() {
    print('Loading initial products for category_id: ${widget.category}');
    context.read<ProductBloc>().add(FetchProducts(category: widget.category));
  }

  Future<void> _fetchCategoryName() async {
    if (widget.category != null && widget.category!.isNotEmpty) {
      try {
        var response = await http.get(
          Uri.parse('$baseUrl/api/category-name/${widget.category}'),
        );

        if (response.statusCode != 200) {
          response = await http.get(
            Uri.parse('$baseUrl/category-name/${widget.category}'),
          );
        }

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _categoryName = data['name'] ?? widget.category ?? 'Tienda';
            print('Category name fetched: $_categoryName');
          });
        } else {
          setState(() {
            _categoryName = widget.category ?? 'Tienda';
            print('Category name fallback: $_categoryName');
          });
        }
      } catch (e) {
        setState(() {
          _categoryName = widget.category ?? 'Tienda';
          print('Error fetching category name: $e');
        });
      }
    } else {
      setState(() {
        _categoryName = 'Tienda';
        print('No category provided, using default: $_categoryName');
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/categories'));
      print('Fetching categories, status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Categories fetched: $data');
        setState(() {
          _dynamicTabs = [];
          _categoryMapping = {};

          if (widget.category != null && widget.category!.isNotEmpty) {
            // If a main category is specified, only add the matching category
            for (var category in data) {
              String categoryName = category['name'];
              String categoryId = category['id'].toString();
              if (categoryId == widget.category) {
                _dynamicTabs.add(categoryName);
                _categoryMapping[categoryName] = categoryId;
              }
            }
            if (_dynamicTabs.isEmpty) {
              // Fallback if no matching category is found
              _dynamicTabs.add(_categoryName);
              _categoryMapping[_categoryName] = widget.category!;
              print('No matching categories, using fallback: $_categoryName');
            }
          } else {
            // If no main category, add all categories
            for (var category in data) {
              String categoryName = category['name'];
              String categoryId = category['id'].toString();
              _dynamicTabs.add(categoryName);
              _categoryMapping[categoryName] = categoryId;
            }
            if (_dynamicTabs.isEmpty) {
              _dynamicTabs.add('Tienda');
              _categoryMapping['Tienda'] = 'Tienda';
              print('No categories found, using default: Tienda');
            }
          }

          print('Dynamic tabs: $_dynamicTabs');
          print('Category mapping: $_categoryMapping');
        });
      } else {
        print('Failed to fetch categories: ${response.statusCode}');
        setState(() {
          _dynamicTabs = [_categoryName];
          _categoryMapping = {_categoryName: widget.category ?? _categoryName};
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        _dynamicTabs = [_categoryName];
        _categoryMapping = {_categoryName: widget.category ?? _categoryName};
      });
    }
  }

  Future<void> _fetchFavorites() async {
    if (!await ApiService.isLoggedIn()) return;
    try {
      final response = await ApiService.get('/api/favorites');
      setState(() {
        favoriteItems.clear();
        favoriteItems.addAll(
          List<Map<String, dynamic>>.from(response['favorites']),
        );
        print('Favorites fetched: $favoriteItems');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar favoritos')),
      );
      print('Error fetching favorites: $e');
    }
  }

  Future<void> _fetchCart() async {
    if (!await ApiService.isLoggedIn()) return;
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/cart'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cartItems.clear();
          cartItems.addAll(List<Map<String, dynamic>>.from(data['cart']));
          print('Cart fetched: $cartItems');
        });
      }
    } catch (e) {
      print('Error fetching cart: $e');
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
          print('Loading more products, next page: ${state.nextPageUrl}');
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

  Future<void> _addToCart(Map<String, dynamic> item) async {
    if (!await ApiService.isLoggedIn()) {
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
        SnackBar(
          content: Text(
            '${item['name']} añadido localmente, inicia sesión para sincronizar',
          ),
        ),
      );
      return;
    }

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/add'),
        headers: headers,
        body: json.encode({'product_id': item['id'], 'quantity': 1}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cartItems.clear();
          cartItems.addAll(List<Map<String, dynamic>>.from(data['cart']));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['name']} añadido al carrito!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al añadir al carrito: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
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
        SnackBar(
          content: Text('${item['name']} añadido localmente debido a error'),
        ),
      );
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    final itemName = item['name'] as String;
    if (!await ApiService.isLoggedIn()) {
      setState(() {
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
      return;
    }

    try {
      final existingIndex = favoriteItems.indexWhere(
        (fav) => fav['name'] == itemName,
      );

      if (existingIndex != -1) {
        final response = await ApiService.delete(
          '/api/favorites/remove/${item['id']}',
        );
        if (response['statusCode'] == 200) {
          setState(() {
            favoriteItems.clear();
            favoriteItems.addAll(
              List<Map<String, dynamic>>.from(response['body']['favorites']),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$itemName eliminado de favoritos!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al eliminar de favoritos: ${response['statusCode']}',
              ),
            ),
          );
        }
      } else {
        final response = await ApiService.post('/api/favorites/add', {
          'product_id': item['id'],
        });
        if (response['statusCode'] == 200) {
          setState(() {
            favoriteItems.clear();
            favoriteItems.addAll(
              List<Map<String, dynamic>>.from(response['body']['favorites']),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$itemName añadido a favoritos!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al añadir a favoritos: ${response['statusCode']}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        final existingIndex = favoriteItems.indexWhere(
          (fav) => fav['name'] == itemName,
        );

        if (existingIndex != -1) {
          favoriteItems.removeAt(existingIndex);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$itemName eliminado de favoritos localmente debido a error',
              ),
            ),
          );
        } else {
          favoriteItems.add(item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$itemName añadido a favoritos localmente debido a error',
              ),
            ),
          );
        }
      });
    }
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
    print('Performing search with term: $searchTerm');
    context.read<ProductBloc>().add(SearchProducts(query: searchTerm));
  }

  List<Map<String, dynamic>> _getFilteredItems(
    String tabCategory,
    List<Product> products,
  ) {
    final productMaps =
        products.map((product) {
          return {
            'id': product.id,
            'category': product.category,
            'category_id': product.categoryId,
            'imageUrl': product.image,
            'name': product.name,
            'description': product.description,
            'price':
                product.price != null
                    ? '\$${product.price!.toStringAsFixed(2)}'
                    : 'Precio no disponible',
          };
        }).toList();

    print('All products before filtering for tab $tabCategory: $productMaps');

    List<Map<String, dynamic>> filteredProducts = productMaps;

    // If widget.category is specified, filter by the main category
    if (widget.category != null && widget.category!.isNotEmpty) {
      filteredProducts =
          productMaps.where((item) {
            return item['category_id'].toString() == widget.category;
          }).toList();
      print(
        'Applied main category filter (ID: ${widget.category}): $filteredProducts',
      );
    }

    // If we have only one tab or widget.category matches the tab, no further filtering is needed
    final tabCategoryId = _categoryMapping[tabCategory];
    if (_dynamicTabs.length > 1 &&
        tabCategoryId != null &&
        tabCategoryId.isNotEmpty &&
        tabCategoryId != 'Tienda' &&
        (widget.category == null || widget.category != tabCategoryId)) {
      filteredProducts =
          filteredProducts.where((item) {
            return item['category_id'].toString() == tabCategoryId;
          }).toList();
      print(
        'Filtered products for tab $tabCategory (ID: $tabCategoryId): $filteredProducts',
      );
    }

    return filteredProducts;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _dynamicTabs.length,
      child: Builder(
        builder: (context) {
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              final selectedTab = _dynamicTabs[tabController.index];
              print('Tab changed to $selectedTab');
            }
          });
          return Scaffold(
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
                                  setState(() {
                                    cartItems
                                      ..clear()
                                      ..addAll(
                                        result.cast<Map<String, dynamic>>(),
                                      );
                                  });
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
              bottom:
                  _dynamicTabs.length > 1
                      ? TabBar(
                        labelColor: Colors.orange,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.orange,
                        tabs:
                            _dynamicTabs.map((tab) => Tab(text: tab)).toList(),
                      )
                      : null,
            ),
            body: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                print('Current ProductBloc state: $state');
                if (state is ProductLoading && state.isInitial) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ProductError) {
                  print('ProductBloc error: ${state.message}');
                  return _buildErrorWidget(state.message);
                } else if (state is ProductLoaded) {
                  print('ProductLoaded with ${state.products.length} products');
                  return RefreshIndicator(
                    onRefresh: () async {
                      _loadInitialProducts();
                      return Future.delayed(const Duration(seconds: 1));
                    },
                    child:
                        _dynamicTabs.length > 1
                            ? TabBarView(
                              children:
                                  _dynamicTabs
                                      .map(
                                        (tab) => _buildTabContent(tab, state),
                                      )
                                      .toList(),
                            )
                            : _buildTabContent(
                              _dynamicTabs.isNotEmpty
                                  ? _dynamicTabs[0]
                                  : _categoryName,
                              state,
                            ),
                  );
                }
                print('No products available for $_categoryName');
                return Center(
                  child: Text(
                    'No hay productos disponibles para $_categoryName',
                  ),
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
                  null,
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
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.store),
                  label: 'Tienda',
                ),
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
          );
        },
      ),
    );
  }

  Widget _buildTabContent(String tabCategory, ProductLoaded state) {
    final filteredItems = _getFilteredItems(tabCategory, state.products);
    if (filteredItems.isEmpty) {
      print('No filtered items for tab: $tabCategory');
      return Center(
        child: Text(
          'No hay productos disponibles para $tabCategory${_categoryName.isNotEmpty && _categoryName != 'Tienda' ? ' ($_categoryName)' : ''}',
        ),
      );
    }
    print('Rendering ${filteredItems.length} items for tab: $tabCategory');
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
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
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
