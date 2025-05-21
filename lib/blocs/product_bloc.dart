import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:margarita/blocs/product_event.dart';
import 'package:margarita/blocs/product_state.dart';
import 'package:margarita/models/product.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  static const String baseUrl = 'http://10.0.2.2:8000';

  ProductBloc() : super(const ProductInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<SearchProducts>(_onSearchProducts);
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(
        ProductLoading(
          isInitial: event.isRefresh ? false : state is! ProductLoaded,
        ),
      );

      // Updated API URL logic to use RESTful endpoints
      final String apiUrl =
          event.category != null && event.category!.isNotEmpty
              ? '$baseUrl/api/products/${Uri.encodeComponent(event.category!)}'
              : '$baseUrl/api/products';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final productsData = responseData['data'] as List<dynamic>? ?? [];
        final products =
            productsData
                .map(
                  (json) =>
                      Product.fromJson(json as Map<String, dynamic>, baseUrl),
                )
                .toList();

        emit(
          ProductLoaded(
            products: products,
            nextPageUrl: responseData['next_page_url'] as String?,
            hasReachedMax: responseData['next_page_url'] == null,
          ),
        );
      } else {
        emit(
          ProductError('Failed to load products: HTTP ${response.statusCode}'),
        );
      }
    } catch (e, stackTrace) {
      emit(ProductError('Connection error: $e\n$stackTrace'));
    }
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is! ProductLoaded) return;
    final currentState = state as ProductLoaded;
    if (currentState.hasReachedMax) return;

    try {
      final response = await http.get(Uri.parse(event.nextPageUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final productsData = responseData['data'] as List<dynamic>? ?? [];
        final newProducts =
            productsData
                .map(
                  (json) =>
                      Product.fromJson(json as Map<String, dynamic>, baseUrl),
                )
                .toList();

        emit(
          currentState.copyWith(
            products: [...currentState.products, ...newProducts],
            nextPageUrl: responseData['next_page_url'] as String?,
            hasReachedMax: responseData['next_page_url'] == null,
          ),
        );
      } else {
        emit(
          ProductError(
            'Failed to load more products: HTTP ${response.statusCode}',
          ),
        );
      }
    } catch (e, stackTrace) {
      emit(
        ProductError('Connection error while loading more: $e\n$stackTrace'),
      );
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<ProductState> emit,
  ) async {
    try {
      emit(const ProductLoading(isInitial: false));

      // Keep search functionality using query parameter
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/products?search=${Uri.encodeComponent(event.query)}',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final productsData = responseData['data'] as List<dynamic>? ?? [];
        final products =
            productsData
                .map(
                  (json) =>
                      Product.fromJson(json as Map<String, dynamic>, baseUrl),
                )
                .toList();

        emit(
          ProductLoaded(
            products: products,
            hasReachedMax: true,
            isSearchResult: true,
          ),
        );
      } else {
        emit(ProductError('Search failed: HTTP ${response.statusCode}'));
      }
    } catch (e, stackTrace) {
      emit(ProductError('Search error: $e\n$stackTrace'));
    }
  }
}
