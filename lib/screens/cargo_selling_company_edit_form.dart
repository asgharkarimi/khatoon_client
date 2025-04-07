import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../app_links.dart';
import '../models/cargo_selling_company.dart';
import '../widgets/app_buttons.dart';

class CargoSellingCompanyEditForm extends StatefulWidget {
  final CargoSellingCompany company;

  const CargoSellingCompanyEditForm({
    super.key,
    required this.company,
  });

  @override
  State<CargoSellingCompanyEditForm> createState() => _CargoSellingCompanyEditFormState();
}

class _CargoSellingCompanyEditFormState extends State<CargoSellingCompanyEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneNumberController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company.name);
    _phoneNumberController = TextEditingController(text: widget.company.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _updateCompany() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final jsonBody = jsonEncode(<String, dynamic>{
          'id': widget.company.id,
          'name': _nameController.text.trim(),
          'phone_number': _phoneNumberController.text.trim().isNotEmpty
              ? _phoneNumberController.text.trim()
              : null,
        });

        final response = await http.put(
          Uri.parse(AppLinks.updateCargoSellingCompanyById(widget.company.id)),
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
          message = "شرکت با موفقیت به‌روزرسانی شد.";
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
          title: const Text('ویرایش شرکت فروشنده بار'),
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
                      labelText: 'نام شرکت',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفا نام شرکت را وارد کنید';
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
                      : Row(
                          children: [
                            Expanded(
                              child: AppButtons.primaryButton(
                                onPressed: _updateCompany,
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