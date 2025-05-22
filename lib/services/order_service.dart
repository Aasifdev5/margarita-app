import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:margarita/models/order.dart';
import 'package:margarita/services/api_service.dart';

class OrderService {
  static Future<List<Order>> fetchOrders() async {
    final headers = await ApiService.getHeaders();

    if (!await ApiService.isLoggedIn()) {
      throw Exception('No authentication token found. Please log in.');
    }

    final response = await http
        .get(Uri.parse('${ApiService.baseUrl}/api/orders'), headers: headers)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
              'Request timed out. Please check your network connection.',
            );
          },
        );

    if (response.statusCode == 200) {
      try {
        List<dynamic> data = json.decode(response.body);
        return data.map((order) => Order.fromJson(order)).toList();
      } catch (e) {
        throw Exception('Failed to parse orders: $e');
      }
    } else if (response.statusCode == 401) {
      await ApiService.clearToken();
      throw Exception('Unauthorized. Please log in again.');
    } else {
      throw Exception(
        'Failed to load orders: ${response.statusCode} ${response.body}',
      );
    }
  }
}
