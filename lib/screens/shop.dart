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
  String _categoryName = 'Productos';
  static const String baseUrl = 'https://remoto.digital';
  List<String> _dynamicTabs = [];
  Map<String, String> _categoryMapping = {};
  int _initialTabIndex = 0;

  List<Product> _lastLoadedProducts = [];
  bool _lastHasReachedMax = false;
  TabController? _tabController;

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
    if (mounted) {
      setState(() {
        _lastLoadedProducts = [];
        _lastHasReachedMax = false;
      });
    }
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
          if (mounted) {
            setState(() {
              _categoryName = data['name'] ?? 'Categoría ${widget.category}';
              print('Category name fetched: $_categoryName');
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _categoryName = 'Categoría ${widget.category}';
              print('Category name fallback: $_categoryName');
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _categoryName = 'Categoría ${widget.category}';
            print('Error fetching category name: $e');
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _categoryName = 'Productos';
          print('No category provided, using default: $_categoryName');
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/categories'));
      print('Fetching categories, status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Categories fetched: $data');
        List<String> newDynamicTabs = [];
        Map<String, String> newCategoryMapping = {};
        int newInitialTabIndex = 0;

        Map<String, dynamic>? selectedCategory;
        if (widget.category != null && widget.category!.isNotEmpty) {
          selectedCategory = data.firstWhere(
            (category) => category['id'].toString() == widget.category,
            orElse: () => null,
          );
          if (selectedCategory != null) {
            String categoryName = selectedCategory['name'];
            newDynamicTabs.add(categoryName);
            newCategoryMapping[categoryName] = widget.category!;
            print('Added selected category first: $categoryName');
          }
        }

        for (var category in data) {
          String categoryId = category['id'].toString();
          String categoryName = category['name'];
          if (categoryId != widget.category) {
            newDynamicTabs.add(categoryName);
            newCategoryMapping[categoryName] = categoryId;
          }
        }

        if (newDynamicTabs.isEmpty) {
          if (widget.category != null && widget.category!.isNotEmpty) {
            String nameToAdd =
                _categoryName != 'Productos' &&
                        _categoryName != 'Categoría ${widget.category}'
                    ? _categoryName
                    : 'Categoría ${widget.category}';
            newDynamicTabs.add(nameToAdd);
            newCategoryMapping[nameToAdd] = widget.category!;
            print('No categories found, added selected category: $nameToAdd');
          } else {
            print('No categories available and no specific category provided');
          }
        }

        if (mounted) {
          setState(() {
            _dynamicTabs = newDynamicTabs;
            _categoryMapping = newCategoryMapping;
            _initialTabIndex =
                newInitialTabIndex < _dynamicTabs.length
                    ? newInitialTabIndex
                    : 0;
            print('Dynamic tabs: $_dynamicTabs');
            print('Category mapping: $_categoryMapping');
            print('Initial tab index: $_initialTabIndex');
          });
        }
      } else {
        print('Failed to fetch categories: ${response.statusCode}');
        if (mounted) {
          setState(() {
            if (widget.category != null && widget.category!.isNotEmpty) {
              _dynamicTabs = [_categoryName];
              _categoryMapping = {_categoryName: widget.category!};
              _initialTabIndex = 0;
            } else {
              _dynamicTabs = [];
              _categoryMapping = {};
              _initialTabIndex = 0;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching categories: $e');
      if (mounted) {
        setState(() {
          if (widget.category != null && widget.category!.isNotEmpty) {
            _dynamicTabs = [_categoryName];
            _categoryMapping = {_categoryName: widget.category!};
            _initialTabIndex = 0;
          } else {
            _dynamicTabs = [];
            _categoryMapping = {};
            _initialTabIndex = 0;
          }
        });
      }
    }
  }

  Future<void> _fetchFavorites() async {
    if (!await ApiService.isLoggedIn()) return;
    try {
      final response = await ApiService.get('/api/favorites');
      if (mounted) {
        setState(() {
          favoriteItems.clear();
          favoriteItems.addAll(
            List<Map<String, dynamic>>.from(response['favorites']),
          );
          print('Favorites fetched: $favoriteItems');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar favoritos')),
        );
      }
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
        if (mounted) {
          setState(() {
            cartItems.clear();
            cartItems.addAll(List<Map<String, dynamic>>.from(data['cart']));
            print('Cart fetched: $cartItems');
          });
        }
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
            !_lastHasReachedMax &&
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
    _tabController?.removeListener(_handleTabSelection);
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      final selectedTab = _dynamicTabs[_tabController!.index];
      print('Tab changed to $selectedTab (Index: ${_tabController!.index})');
      final categoryId = _categoryMapping[selectedTab];
      context.read<ProductBloc>().add(FetchProducts(category: categoryId));
    }
  }

  // Check if the restaurant is open based on API response and restaurant ID
  Future<bool> _isRestaurantOpen(int restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/opening-hours/$restaurantId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> openingHours = json.decode(response.body);
        // Adjust for Bolivia time (UTC-4) from IST (UTC+5:30)
        final now = DateTime.now().toUtc().subtract(
          const Duration(hours: 9, minutes: 30),
        );
        final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
        final currentTime = TimeOfDay.fromDateTime(now);

        const dayMap = {
          1: 'Monday',
          2: 'Tuesday',
          3: 'Wednesday',
          4: 'Thursday',
          5: 'Friday',
          6: 'Saturday',
          7: 'Sunday',
        };

        final todaySchedule = openingHours.firstWhere(
          (schedule) => schedule['day'] == dayMap[currentDay],
          orElse: () => null,
        );

        if (todaySchedule == null) {
          print(
            'No schedule found for restaurant $restaurantId on ${dayMap[currentDay]}',
          );
          return false; // No schedule means closed
        }

        final openTimeParts = todaySchedule['open_time'].split(':');
        final closeTimeParts = todaySchedule['close_time'].split(':');
        final openTime = TimeOfDay(
          hour: int.parse(openTimeParts[0]),
          minute: int.parse(openTimeParts[1]),
        );
        final closeTime = TimeOfDay(
          hour: int.parse(closeTimeParts[0]),
          minute: int.parse(closeTimeParts[1]),
        );

        final currentMinutes = currentTime.hour * 60 + currentTime.minute;
        final openMinutes = openTime.hour * 60 + openTime.minute;
        final closeMinutes = closeTime.hour * 60 + closeTime.minute;

        bool isOpen;
        if (closeMinutes < openMinutes) {
          isOpen =
              currentMinutes >= openMinutes || currentMinutes < closeMinutes;
        } else {
          isOpen =
              currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
        }

        print(
          'Restaurant $restaurantId open: $isOpen for ${dayMap[currentDay]} from ${todaySchedule['open_time']} to ${todaySchedule['close_time']}',
        );
        return isOpen;
      } else {
        print(
          'Failed to fetch opening hours for restaurant $restaurantId: ${response.statusCode}',
        );
        return false; // Assume closed on API error
      }
    } catch (e) {
      print('Error checking opening hours for restaurant $restaurantId: $e');
      return false; // Assume closed on exception
    }
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    // Get restaurant ID from item
    final restaurantId =
        item['created_by_restaurant'] as int? ?? 1; // Fallback to 1
    // Check restaurant hours
    final isOpen = await _isRestaurantOpen(restaurantId);
    if (!isOpen && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lo sentimos, el restaurante ${restaurantId == 1 ? "Arsh" : "Bol"} está cerrado en este momento.',
          ),
        ),
      );
      return;
    }

    if (!await ApiService.isLoggedIn()) {
      if (mounted) {
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
      }
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
        if (mounted) {
          setState(() {
            cartItems.clear();
            cartItems.addAll(List<Map<String, dynamic>>.from(data['cart']));
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item['name']} añadido al carrito!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al añadir al carrito: ${response.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
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
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    final itemName = item['name'] as String;
    if (!await ApiService.isLoggedIn()) {
      if (mounted) {
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
      }
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
          if (mounted) {
            setState(() {
              favoriteItems.clear();
              favoriteItems.addAll(
                List<Map<String, dynamic>>.from(response['body']['favorites']),
              );
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$itemName eliminado de favoritos!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error al eliminar de favoritos: ${response['statusCode']}',
                ),
              ),
            );
          }
        }
      } else {
        final response = await ApiService.post('/api/favorites/add', {
          'product_id': item['id'],
        });
        if (response['statusCode'] == 200) {
          if (mounted) {
            setState(() {
              favoriteItems.clear();
              favoriteItems.addAll(
                List<Map<String, dynamic>>.from(response['body']['favorites']),
              );
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$itemName añadido a favoritos!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error al añadir a favoritos: ${response['statusCode']}',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
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
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        _loadInitialProducts();
      }
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
    if (mounted) {
      setState(() {
        _lastLoadedProducts = [];
        _lastHasReachedMax = false;
      });
    }
    context.read<ProductBloc>().add(SearchProducts(query: searchTerm));
  }

  List<Map<String, dynamic>> _getFilteredItems(
    String tabCategory,
    List<Product> products,
  ) {
    final productMaps =
        products.map((product) {
          String truncatedName =
              product.name.length > 30
                  ? '${product.name.substring(0, 27)}...'
                  : product.name;
          String truncatedDescription =
              product.description.length > 150
                  ? '${product.description.substring(0, 147)}...'
                  : product.description;

          return {
            'id': product.id,
            'category': product.category,
            'category_id': product.categoryId,
            'imageUrl': product.image,
            'name': product.name,
            'displayName': truncatedName,
            'description': product.description,
            'price':
                product.price != null
                    ? 'Bs. ${product.price!.toStringAsFixed(2)}'
                    : 'Precio no disponible',
            'created_by_restaurant':
                product.createdByRestaurant, // Add restaurant ID
            'original_item': product.toJson(),
          };
        }).toList();

    if (!_showSearch && _dynamicTabs.isNotEmpty) {
      final tabCategoryId = _categoryMapping[tabCategory];
      if (tabCategoryId != null) {
        return productMaps.where((item) {
          return item['category_id'].toString() == tabCategoryId;
        }).toList();
      }
    }
    return productMaps;
  }

  @override
  Widget build(BuildContext context) {
    if (_dynamicTabs.isEmpty && widget.category != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_categoryName)),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: _buildBottomNavBar(),
      );
    }

    return DefaultTabController(
      key: ValueKey(_dynamicTabs.join('-')),
      length: _dynamicTabs.length,
      initialIndex: _initialTabIndex,
      child: Builder(
        builder: (context) {
          final currentTabController = DefaultTabController.of(context);
          if (_tabController != currentTabController) {
            _tabController?.removeListener(_handleTabSelection);
            _tabController = currentTabController;
            _tabController?.addListener(_handleTabSelection);
          }

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
                        _categoryName,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8901)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions:
                  _showSearch
                      ? [
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFFFF8901),
                          ),
                          onPressed: _performSearch,
                        ),
                      ]
                      : [
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFFFF8901),
                          ),
                          onPressed: _toggleSearch,
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.shopping_cart,
                                color: Color(0xFFFF8901),
                              ),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CartScreen(cartItems: cartItems),
                                  ),
                                );
                                if (result != null &&
                                    result is List &&
                                    mounted) {
                                  setState(() {
                                    cartItems
                                      ..clear()
                                      ..addAll(
                                        result.cast<Map<String, dynamic>>(),
                                      );
                                  });
                                } else {
                                  _fetchCart();
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
                                    '${cartItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 0))}',
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
                  _dynamicTabs.isNotEmpty && !_showSearch
                      ? TabBar(
                        isScrollable: true,
                        labelColor: const Color(0xFFFF8901),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFFFF8901),
                        tabs:
                            _dynamicTabs.map((tab) => Tab(text: tab)).toList(),
                      )
                      : null,
            ),
            body: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is ProductLoaded) {
                  if (mounted) {
                    setState(() {
                      _lastLoadedProducts = state.products;
                      _lastHasReachedMax = state.hasReachedMax;
                    });
                  }
                } else if (state is ProductError) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${state.message}')),
                    );
                  }
                  print('ProductBloc error: ${state.message}');
                }
              },
              builder: (context, state) {
                print(
                  'BlocBuilder running. State: $state, LastLoaded: ${_lastLoadedProducts.length}',
                );

                final bool isLoadingMore =
                    state is ProductLoading &&
                    !_lastHasReachedMax &&
                    _lastLoadedProducts.isNotEmpty;

                if (state is ProductLoading && _lastLoadedProducts.isEmpty) {
                  print('Showing initial loading indicator.');
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ProductError && _lastLoadedProducts.isEmpty) {
                  print('Showing error state (no previous data).');
                  return Center(
                    child: Text('Error al cargar productos: ${state.message}'),
                  );
                }

                if (_lastLoadedProducts.isNotEmpty || state is ProductLoaded) {
                  print('Building content UI. isLoadingMore: $isLoadingMore');
                  List<Product> productsToShow = _lastLoadedProducts;
                  bool hasReachedMaxToShow = _lastHasReachedMax;

                  if (state is ProductLoaded) {
                    productsToShow = state.products;
                    hasReachedMaxToShow = state.hasReachedMax;
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      print('Pull to refresh initiated');
                      final currentTabIndex =
                          _tabController?.index ?? _initialTabIndex;
                      if (currentTabIndex >= 0 &&
                          currentTabIndex < _dynamicTabs.length) {
                        final selectedTabName = _dynamicTabs[currentTabIndex];
                        final categoryId = _categoryMapping[selectedTabName];
                        context.read<ProductBloc>().add(
                          FetchProducts(category: categoryId),
                        );
                      } else {
                        _loadInitialProducts();
                      }
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child:
                        _dynamicTabs.isNotEmpty && !_showSearch
                            ? TabBarView(
                              children:
                                  _dynamicTabs.map((tab) {
                                    return _buildTabContent(
                                      tab,
                                      productsToShow,
                                      hasReachedMaxToShow,
                                      isLoadingMore &&
                                          (_tabController?.index ==
                                              _dynamicTabs.indexOf(tab)),
                                    );
                                  }).toList(),
                            )
                            : _buildProductList(
                              productsToShow,
                              hasReachedMaxToShow,
                              isLoadingMore,
                            ),
                  );
                }

                print('Showing empty state (fallback).');
                return _buildEmptyState();
              },
            ),
            bottomNavigationBar: _buildBottomNavBar(),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(
    String tabCategory,
    List<Product> products,
    bool hasReachedMax,
    bool isLoadingMore,
  ) {
    final filteredItems = _getFilteredItems(tabCategory, products);

    if (filteredItems.isEmpty && !isLoadingMore) {
      print('No filtered items for tab: $tabCategory');
      return Center(
        child: Text('No hay productos disponibles para $tabCategory'),
      );
    }
    print(
      'Rendering ${filteredItems.length} items for tab: $tabCategory. isLoadingMore: $isLoadingMore',
    );

    return ListView.builder(
      key: PageStorageKey(tabCategory),
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredItems.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredItems.length && isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (index >= filteredItems.length) return const SizedBox.shrink();

        final item = filteredItems[index];
        final originalItemData =
            item['original_item'] as Map<String, dynamic>? ?? {};

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildFoodItem(
            imageUrl: item['imageUrl'] as String? ?? '',
            name: item['displayName'] as String? ?? 'N/A',
            description: item['description'] as String? ?? '',
            price: item['price'] as String? ?? '',
            isFavorite: favoriteItems.any((fav) => fav['id'] == item['id']),
            onAdd: () => _addToCart(originalItemData),
            onFavorite: () => _toggleFavorite(originalItemData),
          ),
        );
      },
    );
  }

  Widget _buildProductList(
    List<Product> products,
    bool hasReachedMax,
    bool isLoadingMore,
  ) {
    final items = _getFilteredItems("search_results", products);

    if (items.isEmpty && !isLoadingMore) {
      return const Center(child: Text('No hay productos disponibles.'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length && isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (index >= items.length) return const SizedBox.shrink();

        final item = items[index];
        final originalItemData =
            item['original_item'] as Map<String, dynamic>? ?? {};

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildFoodItem(
            imageUrl: item['imageUrl'] as String? ?? '',
            name: item['displayName'] as String? ?? 'N/A',
            description: item['description'] as String? ?? '',
            price: item['price'] as String? ?? '',
            isFavorite: favoriteItems.any((fav) => fav['id'] == item['id']),
            onAdd: () => _addToCart(originalItemData),
            onFavorite: () => _toggleFavorite(originalItemData),
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
              imageUrl:
                  imageUrl.isNotEmpty
                      ? imageUrl
                      : 'https://via.placeholder.com/80',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFFF8901),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8901),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Añadir',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('No hay productos para mostrar.'));
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFFF8901),
      unselectedItemColor: Colors.grey,
      currentIndex: 1,
      onTap: (index) {
        if (index == 1) return;

        Widget? destinationPage;
        switch (index) {
          case 0:
            destinationPage = FoodHomeScreen();
            break;
          case 2:
            destinationPage = const OrderHistoryScreen();
            break;
          case 3:
            destinationPage = FavouritesScreen(favorites: favoriteItems);
            break;
          case 4:
            destinationPage = MenuScreen();
            break;
        }

        if (destinationPage != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destinationPage!),
          );
        }
      },
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
    );
  }
}
