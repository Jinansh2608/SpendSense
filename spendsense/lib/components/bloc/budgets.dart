import 'dart:convert';
import 'package:http/http.dart' as http;

class BudgetService {
  final String baseUrl = "http://192.168.1.103:5000/api"; // Change for production

  /// Fetch all budgets for a user
  Future<List<dynamic>> getBudgets(String uid) async {
    final url = Uri.parse('$baseUrl/budgets/$uid');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['budgets'] ?? [];
    } else {
      throw Exception('Failed to fetch budgets');
    }
  }

  /// Create a new budget
  Future<bool> createBudget(String uid, String name, double cap, String period) async {
    final url = Uri.parse('$baseUrl/budgets');
    final body = {
      "uid": uid,
      "name": name,
      "cap": cap,
      "period": period, // Example: "2025-09"
      "currency": "INR"
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return response.statusCode == 201;
  }

  /// Update an existing budget
  Future<bool> updateBudget(int id, String name, double cap, String period) async {
    final url = Uri.parse('$baseUrl/budgets/$id');
    final body = {
      "name": name,
      "cap": cap,
      "period": period,
      "currency": "INR"
    };

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  /// Delete a budget
  Future<bool> deleteBudget(int id) async {
    final url = Uri.parse('$baseUrl/budgets/$id');
    final response = await http.delete(url);

    return response.statusCode == 200;
  }
}
