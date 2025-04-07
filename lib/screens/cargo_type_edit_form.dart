import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../app_links.dart';
import '../models/cargo_type.dart';
import '../widgets/app_buttons.dart';

class CargoTypeEditForm extends StatefulWidget {
  final CargoType cargoType;

  const CargoTypeEditForm({
    super.key,
    required this.cargoType,
  });

  @override
  State<CargoTypeEditForm> createState() => _CargoTypeEditFormState();
}

class _CargoTypeEditFormState extends State<CargoTypeEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cargoType.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateCargoType() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final jsonBody = jsonEncode(<String, dynamic>{
          'id': widget.cargoType.id,
          'name': _nameController.text.trim(),
        });

        final response = await http.put(
          Uri.parse(AppLinks.updateCargoTypeById(widget.cargoType.id)),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonBody,
        ).timeout(const Duration(seconds: 10));

        // Decode response body safely
        Map<String, dynamic>? responseData;
        String message = 'An unknown error occurred.'; // Default message
        if (response.body.isNotEmpty) {
          try {
            responseData = jsonDecode(response.body);
            if (responseData != null && responseData.containsKey('message')) {
              message = responseData['message'];
            }
          } catch (e) {
            print("Error decoding JSON response: $e");
            message = 'Error processing server response.';
          }
        } else if (response.statusCode == 200) {
          message = "نوع بار با موفقیت به‌روزرسانی شد.";
        } else {
          message = "Received empty response (Code: ${response.statusCode})";
        }

        if (!mounted) return; // Check if widget is still in the tree

        if (response.statusCode == 200) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
          );
          Navigator.pop(context, true);
        } else {
          // API Error (e.g., 400, 409, 500)
          print("API Error: ${response.statusCode} - ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $message (${response.statusCode})'),
                backgroundColor: Colors.red.shade700),
          );
        }
      } catch (e) {
        // Network or other errors (timeout, connection refused, etc.)
        if (!mounted) return;
        print("Submit Error: $e");
        String errorMessage = "Failed to connect to the server.";
        if (e is TimeoutException) {
          errorMessage = "Connection timed out. Please try again.";
        } else if (e is http.ClientException) {
          errorMessage = "Network error. Check your connection.";
        } else {
          errorMessage = "An unexpected error occurred: $e";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red.shade700),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ویرایش نوع بار'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _nameController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'نام نوع بار',
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفا نام نوع بار را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: AppButtons.primaryButton(
                                onPressed: _updateCargoType,
                                icon: Icons.save,
                                label: 'ذخیره تغییرات',
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppButtons.dangerButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icons.cancel,
                              label: 'انصراف',
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 