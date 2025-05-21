import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final int categoryId;
  final String code;
  final String name;
  final String description;
  final String image;
  final double? price;
  final String category;

  const Product({
    required this.id,
    required this.categoryId,
    required this.code,
    required this.name,
    required this.description,
    required this.image,
    this.price,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json, String baseUrl) {
    String getCategoryName(int categoryId) {
      const categoryMap = {
        1: 'Italian',
        2: 'Pizza',
        3: 'Burgers',
        4: 'Tacos',
        5: 'Snacks',
        6: 'Drinks',
        7: 'Desserts',
      };
      return categoryMap[categoryId] ?? 'Others';
    }

    final imageUrl =
        (json['image'] as String?)?.startsWith('http') == true
            ? json['image'] as String
            : '$baseUrl/${json['image'] ?? ''}';

    return Product(
      id: json['id'] as int? ?? 0,
      categoryId: json['category_id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      image: imageUrl,
      price:
          json['price'] != null
              ? double.tryParse(json['price'].toString())
              : null,
      category: getCategoryName(json['category_id'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'code': code,
      'name': name,
      'description': description,
      'image': image,
      'price': price,
      'category': category,
    };
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    code,
    name,
    description,
    image,
    price,
    category,
  ];
}
