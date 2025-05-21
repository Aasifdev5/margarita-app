// services/order_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:margarita/models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  static Future<List<Order>> fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Assuming token is stored here

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/orders'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((order) => Order.fromJson(order)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }
}
