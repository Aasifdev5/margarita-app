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
  final int createdByRestaurant; // Added field

  const Product({
    required this.id,
    required this.categoryId,
    required this.code,
    required this.name,
    required this.description,
    required this.image,
    this.price,
    required this.category,
    required this.createdByRestaurant, // Added to constructor
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
        30: 'Pizza', // From products table (e.g., Pizza Hawaiana)
        31: 'Sandwiches', // From products table (e.g., Doble pechuga)
        36: 'Combos', // From products table (e.g., Pollo, Combo 6 Alitas)
        49: 'Family Combos', // From products table (e.g., COMBO FERIADO)
        52: 'Desserts', // From products table (e.g., Helado de vainilla)
        53: 'Beverages', // From products table (e.g., Frappé de mango)
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
      createdByRestaurant: json['created_by_restaurant'] as int? ?? 1, // Added
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
      'created_by_restaurant': createdByRestaurant, // Added
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
    createdByRestaurant, // Added to props
  ];
}
