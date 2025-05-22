class Order {
  final String orderNumber;
  final String date;
  final String total;
  final List<Map<String, dynamic>> items;

  Order({
    required this.orderNumber,
    required this.date,
    required this.total,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> items;
    if (json['items'] is List &&
        json['items'].isNotEmpty &&
        json['items'][0] is String) {
      // Handle legacy format where items is List<String>
      items =
          (json['items'] as List<dynamic>)
              .map((name) => {'name': name, 'quantity': 1, 'price': '0.00'})
              .toList()
              .cast<Map<String, dynamic>>();
    } else {
      // Handle new format where items is List<Map<String, dynamic>>
      items =
          (json['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    }
    return Order(
      orderNumber: json['orderNumber']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      total: json['total']?.toString() ?? '0.00',
      items: items,
    );
  }
}
