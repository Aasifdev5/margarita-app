// models/order.dart
class Order {
  final String orderNumber;
  final String date;
  final String total;
  final List<String> items;

  Order({
    required this.orderNumber,
    required this.date,
    required this.total,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderNumber: json['orderNumber'],
      date: json['date'],
      total: json['total'],
      items: List<String>.from(json['items']),
    );
  }
}
