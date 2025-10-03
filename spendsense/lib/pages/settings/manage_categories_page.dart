import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spendsense/constants/colors/colors.dart';

import 'package:spendsense/constants/api_constants.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _fetchCategories() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/categories/$_userId'),
      );
      if (response.statusCode == 200) {
        setState(() => _categories = jsonDecode(response.body)['categories']);
      } else {
        _showError('Failed to load categories.');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _addCategory(String name) async {
    if (name.isEmpty || _userId == null) return;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'user_id': _userId}),
      );
      if (response.statusCode == 201) {
        _fetchCategories(); // Refresh list
      } else {
        _showError('Failed to add category.');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  Future<void> _editCategory(String id, String newName) async {
    if (newName.isEmpty) return;
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/categories/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': newName}),
      );
      if (response.statusCode == 200) {
        _fetchCategories(); // Refresh list
      } else {
        _showError('Failed to update category.');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  Future<void> _deleteCategory(String id) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}/categories/$id'));
      if (response.statusCode == 200) {
        _fetchCategories(); // Refresh list
      } else {
        _showError('Failed to delete category.');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Ycolor.gray,
        elevation: 0,
      ),
      backgroundColor: Ycolor.gray,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: Ycolor.primarycolor,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCategories,
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ListTile(
                    leading: Icon(Icons.label_outline, color: Ycolor.gray10),
                    title: Text(
                      category['name'],
                      style: TextStyle(color: Ycolor.whitee),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Ycolor.gray60),
                          onPressed: () =>
                              _showCategoryDialog(category: category),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () =>
                              _deleteCategory(category['id'].toString()),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final textController = TextEditingController(text: category?['name']);
    final isEditing = category != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Ycolor.gray70,
        title: Text(
          isEditing ? 'Edit Category' : 'New Category',
          style: TextStyle(color: Ycolor.whitee),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(color: Ycolor.whitee),
          decoration: InputDecoration(
            labelText: 'Category Name',
            labelStyle: TextStyle(color: Ycolor.gray10),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Ycolor.primarycolor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Ycolor.primarycolor)),
          ),
          TextButton(
            onPressed: () {
              if (isEditing) {
                _editCategory(category['id'].toString(), textController.text);
              } else {
                _addCategory(textController.text);
              }
              Navigator.pop(context);
            },
            child: Text(
              isEditing ? 'Save' : 'Add',
              style: TextStyle(color: Ycolor.primarycolor),
            ),
          ),
        ],
      ),
    );
  }
}
