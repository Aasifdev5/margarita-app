import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:margarita/blocs/product_event.dart';
import 'package:margarita/blocs/product_state.dart';
import 'package:margarita/models/product.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  static const String baseUrl = 'https://remoto.digital';

  ProductBloc() : super(ProductInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<SearchProducts>(_onSearchProducts);
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading(isInitial: true));
    try {
      final apiUrl =
          event.category != null && event.category!.isNotEmpty
              ? '$baseUrl/api/products?category_id=${Uri.encodeComponent(event.category!)}'
              : '$baseUrl/api/products';
      print('Fetching products from: $apiUrl');

      final response = await http.get(Uri.parse(apiUrl));
      print('Product fetch response status: ${response.statusCode}');
      print('Product fetch response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> productsData = data['data'] ?? [];
        final products =
            productsData
                .map(
                  (json) =>
                      Product.fromJson(json as Map<String, dynamic>, baseUrl),
                )
                .toList();
        print('Fetched ${products.length} products: $products');

        emit(
          ProductLoaded(
            products: products,
            hasReachedMax: products.isEmpty || data['next_page_url'] == null,
            nextPageUrl: data['next_page_url'],
          ),
        );
      } else if (response.statusCode == 404) {
        print(
          'No products found for category ${event.category}, returning empty list',
        );
        emit(
          ProductLoaded(products: [], hasReachedMax: true, nextPageUrl: null),
        );
      } else {
        emit(
          ProductError('Failed to load products: HTTP ${response.statusCode}'),
        );
      }
    } catch (e) {
      print('Error fetching products: $e');
      emit(ProductError('Failed to load products: $e'));
    }
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProducts event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProductLoaded && !currentState.hasReachedMax) {
      emit(
        ProductLoading(
          isInitial: false,
          products: currentState.products,
          hasReachedMax: currentState.hasReachedMax,
        ),
      );

      try {
        print('Loading more products from: ${event.nextPageUrl}');
        final response = await http.get(Uri.parse(event.nextPageUrl));
        print('Load more response status: ${response.statusCode}');
        print('Load more response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> productsData = data['data'] ?? [];
          final newProducts =
              productsData
                  .map(
                    (json) =>
                        Product.fromJson(json as Map<String, dynamic>, baseUrl),
                  )
                  .toList();
          print('Loaded ${newProducts.length} more products: $newProducts');

          emit(
            ProductLoaded(
              products: [...currentState.products, ...newProducts],
              hasReachedMax:
                  newProducts.isEmpty || data['next_page_url'] == null,
              nextPageUrl: data['next_page_url'],
            ),
          );
        } else {
          emit(
            ProductError(
              'Failed to load more products: HTTP ${response.statusCode}',
            ),
          );
        }
      } catch (e) {
        print('Error loading more products: $e');
        emit(ProductError('Failed to load more products: $e'));
      }
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading(isInitial: true));

    try {
      final apiUrl =
          '$baseUrl/api/products/search?query=${Uri.encodeComponent(event.query)}';
      print('Searching products with URL: $apiUrl');
      final response = await http.get(Uri.parse(apiUrl));
      print('Search response status: ${response.statusCode}');
      print('Search response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> productsData = data['data'] ?? [];
        final products =
            productsData
                .map(
                  (json) =>
                      Product.fromJson(json as Map<String, dynamic>, baseUrl),
                )
                .toList();
        print('Search returned ${products.length} products: $products');

        emit(
          ProductLoaded(
            products: products,
            hasReachedMax: products.isEmpty || data['next_page_url'] == null,
            nextPageUrl: data['next_page_url'],
            isSearchResult: true,
          ),
        );
      } else {
        emit(
          ProductError(
            'Failed to search products: HTTP ${response.statusCode}',
          ),
        );
      }
    } catch (e) {
      print('Error searching products: $e');
      emit(ProductError('Failed to search products: $e'));
    }
  }
}
