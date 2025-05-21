import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class FetchProducts extends ProductEvent {
  final String? category;
  final bool isRefresh;

  const FetchProducts({this.category, this.isRefresh = false});

  @override
  List<Object?> get props => [category, isRefresh];
}

class LoadMoreProducts extends ProductEvent {
  final String nextPageUrl;

  const LoadMoreProducts(this.nextPageUrl);

  @override
  List<Object?> get props => [nextPageUrl];
}

class SearchProducts extends ProductEvent {
  final String query;

  const SearchProducts({required this.query});

  @override
  List<Object?> get props => [query];
}
