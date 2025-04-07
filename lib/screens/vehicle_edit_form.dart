import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../app_links.dart';
import '../models/vehicle.dart';
import '../widgets/app_buttons.dart';

class VehicleEditForm extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleEditForm({
    super.key,
    required this.vehicle,
  });

  @override
  State<VehicleEditForm> createState() => _VehicleEditFormState();
}

class _VehicleEditFormState extends State<VehicleEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _smartCardController;
  late final TextEditingController _healthCodeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing vehicle data
    _nameController = TextEditingController(text: widget.vehicle.name);
    _smartCardController = TextEditingController(text: widget.vehicle.smartCardNumber ?? '');
    _healthCodeController = TextEditingController(text: widget.vehicle.healthCode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _smartCardController.dispose();
    _healthCodeController.dispose();
    super.dispose();
  }

  Future<void> _updateVehicle() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final jsonBody = jsonEncode(<String, dynamic>{
          'id': widget.vehicle.id.toString(),
          'name': _nameController.text.trim(),
          'smart_card_number': _smartCardController.text.trim().isNotEmpty
              ? _smartCardController.text.trim()
              : null,
          'health_code': _healthCodeController.text.trim().isNotEmpty
              ? _healthCodeController.text.trim()
              : null,
        });
        print("JSON Body: $jsonBody");

        final response = await http.put(
          Uri.parse(AppLinks.updateVehicleById(widget.vehicle.id)),
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
          message = "Vehicle updated successfully.";
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
          title: const Text('ویرایش خودرو'),
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
                          onPressed: _updateVehicle,
                          icon: Icons.save,
                          label: 'ذخیره تغییرات',
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