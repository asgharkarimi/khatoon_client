import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../app_links.dart';
import '../widgets/app_buttons.dart';

class VehicleForm extends StatefulWidget {
  static const routeName = '/vehicle-form';
  
  const VehicleForm({super.key});

  @override
  State<VehicleForm> createState() => _VehicleAddFormState();
}

class _VehicleAddFormState extends State<VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _smartCardController = TextEditingController();
  final _healthCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _smartCardController.dispose();
    _healthCodeController.dispose();
    super.dispose();
  }

  Future<void> _addVehicle() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final jsonBody = jsonEncode(<String, dynamic>{
          'name': _nameController.text.trim(),
          'smart_card_number': _smartCardController.text.trim().isNotEmpty
              ? _smartCardController.text.trim()
              : null,
          'health_code': _healthCodeController.text.trim().isNotEmpty
              ? _healthCodeController.text.trim()
              : null,
        });
        print("JSON Body: $jsonBody");

        final response = await http.post(
          Uri.parse(AppLinks.vehicles),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonBody,
        ).timeout(const Duration(seconds: 10));

        // Decode response body safely
        Map<String, dynamic>? responseData;
        String message = 'An unknown error occurred.';
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
        } else if (response.statusCode == 201) {
          message = "Vehicle created successfully.";
        } else {
          message = "Received empty response (Code: ${response.statusCode})";
        }

        if (!mounted) return;

        if (response.statusCode == 201) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
          );
          // Clear form and return to previous screen
          _formKey.currentState?.reset();
          _nameController.clear();
          _smartCardController.clear();
          _healthCodeController.clear();
          Navigator.pop(context, true);
        } else {
          // API Error
          print("API Error: ${response.statusCode} - ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $message (${response.statusCode})'),
                backgroundColor: Colors.red.shade700),
          );
        }
      } catch (e) {
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
          title: const Text('افزودن خودرو جدید'),
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
                      labelText: 'نام خودرو',
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفا نام خودرو را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _smartCardController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      labelText: 'شماره کارت هوشمند (اختیاری)',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _healthCodeController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      labelText: 'کد سلامت (اختیاری)',
                      prefixIcon: Icon(Icons.health_and_safety),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AppButtons.primaryButton(
                          onPressed: _addVehicle,
                          icon: Icons.add_circle_outline,
                          label: 'افزودن خودرو',
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