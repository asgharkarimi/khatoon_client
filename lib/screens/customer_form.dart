import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonEncode
import 'dart:async'; // Import for TimeoutException
import '../app_links.dart'; // Import the AppLinks class

class CustomerAddForm extends StatefulWidget {
  const CustomerAddForm({super.key});

  @override
  State<CustomerAddForm> createState() => _CustomerAddFormState();
}

class _CustomerAddFormState extends State<CustomerAddForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isLoading = false;

  // --- REMOVE OLD API URL --- 
  // final String apiUrl = "http://YOUR_API_URL/api/customers.php"; // <-- REMOVE THIS
  // --------------------------------------------------------------------

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final jsonBody = jsonEncode(<String, String?>{
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone_number': _phoneNumberController.text.trim().isNotEmpty
              ? _phoneNumberController.text.trim()
              : null,
        });
        print("JSON Body: $jsonBody");

        final response = await http.post(
          Uri.parse(AppLinks.customers), // <-- USE LINK FROM AppLinks
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            // Add any other headers like Authorization if needed
          },
          body: jsonBody,
        ).timeout(const Duration(seconds: 10)); // Add a timeout

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
            // If the response wasn't JSON, maybe show the raw body?
            // message = response.body;
          }
        } else if (response.statusCode == 201) {
             message = "Customer created successfully."; // Default success if no message
        } else {
             message = "Received empty response (Code: ${response.statusCode})";
        }


        if (!mounted) return; // Check if widget is still in the tree

        if (response.statusCode == 201) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
          );
          // Optionally clear the form or navigate away
          _formKey.currentState?.reset();
          _firstNameController.clear();
          _lastNameController.clear();
          _phoneNumberController.clear();
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
    // Use theme defaults for input decoration
    final inputDecorationTheme = Theme.of(context).inputDecorationTheme;

    return Directionality( // Added for RTL text direction
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('افزودن مشتری جدید'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView( // Allows scrolling if content overflows
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _firstNameController,
                    textDirection: TextDirection.rtl, // Ensure RTL input
                    decoration: InputDecoration( // Uses theme but can be customized
                      labelText: 'نام',
                      // border: inputDecorationTheme.border, // Already applied by theme
                      prefixIcon: const Icon(Icons.person_outline),
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
                    decoration: InputDecoration(
                      labelText: 'نام خانوادگی',
                      prefixIcon: const Icon(Icons.person),
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
                     textDirection: TextDirection.ltr, // Phone numbers usually LTR
                     textAlign: TextAlign.left, // Align text left for phone number
                    decoration: InputDecoration(
                      labelText: 'شماره تلفن (اختیاری)',
                      prefixIcon: const Icon(Icons.phone),
                      hintText: '09...'
                    ),
                    keyboardType: TextInputType.phone,
                    // Optional: Add specific phone number validation
                    // validator: (value) {
                    //   if (value != null && value.isNotEmpty && !RegExp(r'^09[0-9]{9}$').hasMatch(value)) {
                    //      return 'فرمت شماره تلفن نامعتبر است';
                    //   }
                    //   return null;
                    // },
                  ),
                  const SizedBox(height: 24.0),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('افزودن مشتری'),
                          onPressed: _addCustomer,
                          // Style is inherited from the theme's ElevatedButtonThemeData
                          // style: ElevatedButton.styleFrom(
                          //   padding: const EdgeInsets.symmetric(vertical: 16.0),
                          //   textStyle: const TextStyle(fontSize: 16, fontFamily: 'Vazir'),
                          // ),
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
