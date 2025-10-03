import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // ✅ For Firebase UID
import 'package:spendsense/constants/api_constants.dart';

class TopCategories extends StatefulWidget {
  const TopCategories({super.key});

  @override
  State<TopCategories> createState() => _TopCategoriesState();
}

class _TopCategoriesState extends State<TopCategories> {
  bool expanded = false;
  bool isLoading = true;
  List<Map<String, dynamic>> categories = [];
  String? errorMessage;

  String? uid;

  @override
  void initState() {
    super.initState();
    getFirebaseUIDAndFetch();
  }

  Future<void> getFirebaseUIDAndFetch() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          errorMessage = "User not logged in";
          isLoading = false;
        });
        return;
      }

      uid = user.uid;
      await fetchCategories();
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching Firebase UID: $e";
        isLoading = false;
      });
    }
  }

  Future<void> fetchCategories() async {
    final String url = '${ApiConstants.baseUrl}/category-spending/$uid';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            categories = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'No data found';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load categories (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (categories.isEmpty) {
      return const Text("No categories found", style: TextStyle(fontSize: 16));
    }

    final topToShow = expanded ? categories : categories.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Top Categories",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...topToShow.map(
          (cat) => Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Icon(Icons.category, color: Colors.blue),
              title: Text(
                cat['category'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Text(
                '₹${cat['total_spent']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ),
        if (categories.length > 3)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() => expanded = !expanded);
              },
              child: Text(expanded ? 'Show Less' : 'Show More'),
            ),
          ),
      ],
    );
  }
}
