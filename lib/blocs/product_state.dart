import 'package:equatable/equatable.dart';
import 'package:margarita/models/product.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  final bool isInitial;
  final List<Product>? products; // Add products to preserve current state
  final bool? hasReachedMax; // Add hasReachedMax to preserve current state

  const ProductLoading({
    this.isInitial = true,
    this.products,
    this.hasReachedMax,
  });

  @override
  List<Object?> get props => [isInitial, products, hasReachedMax];
}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final String? nextPageUrl;
  final bool hasReachedMax;
  final bool isSearchResult;

  const ProductLoaded({
    required this.products,
    this.nextPageUrl,
    this.hasReachedMax = false,
    this.isSearchResult = false,
  });

  ProductLoaded copyWith({
    List<Product>? products,
    String? nextPageUrl,
    bool? hasReachedMax,
    bool? isSearchResult,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      nextPageUrl: nextPageUrl ?? this.nextPageUrl,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isSearchResult: isSearchResult ?? this.isSearchResult,
    );
  }

  @override
  List<Object?> get props => [
    products,
    nextPageUrl,
    hasReachedMax,
    isSearchResult,
  ];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
