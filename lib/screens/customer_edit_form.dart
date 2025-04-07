import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../app_links.dart';
import '../models/customer.dart';

class CustomerEditForm extends StatefulWidget {
  final Customer customer;

  const CustomerEditForm({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerEditForm> createState() => _CustomerEditFormState();
}

class _CustomerEditFormState extends State<CustomerEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneNumberController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing customer data
    _firstNameController = TextEditingController(text: widget.customer.firstName);
    _lastNameController = TextEditingController(text: widget.customer.lastName);
    _phoneNumberController = TextEditingController(text: widget.customer.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _updateCustomer() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final jsonBody = jsonEncode(<String, dynamic>{
          'id': widget.customer.id.toString(), // Include ID for update
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone_number': _phoneNumberController.text.trim().isNotEmpty
              ? _phoneNumberController.text.trim()
              : null,
        });
        print("JSON Body: $jsonBody");

        final response = await http.put(
          Uri.parse(AppLinks.updateCustomerById(widget.customer.id)),
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
        } else if (response.statusCode == 200) {
          message = "Customer updated successfully.";
        } else {
          message = "Received empty response (Code: ${response.statusCode})";
        }

        if (!mounted) return;

        if (response.statusCode == 200) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
          );
          // Return to previous screen
          Navigator.pop(context, true); // true indicates successful update
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
          title: const Text('ویرایش مشتری'),
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
                    controller: _firstNameController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'نام',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفا نام را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _lastNameController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'نام خانوادگی',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفا نام خانوادگی را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _phoneNumberController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      labelText: 'شماره تلفن (اختیاری)',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '09...',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24.0),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('ذخیره تغییرات'),
                          onPressed: _updateCustomer,
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