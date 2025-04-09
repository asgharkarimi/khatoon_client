import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'dart:ui' as ui;

class BankAccountAddForm extends StatefulWidget {
  const BankAccountAddForm({super.key});

  @override
  State<BankAccountAddForm> createState() => _BankAccountAddFormState();
}

class _BankAccountAddFormState extends State<BankAccountAddForm> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _ibanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderNameController.dispose();
    _cardNumberController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _addBankAccount() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final jsonBody = jsonEncode(<String, dynamic>{
          'bank_name': _bankNameController.text.trim(),
          'account_holder_name': _accountHolderNameController.text.trim(),
          'card_number': _cardNumberController.text.trim().isNotEmpty
              ? _cardNumberController.text.trim()
              : null,
          'iban': _ibanController.text.trim().isNotEmpty
              ? _ibanController.text.trim()
              : null,
        });
        print("JSON Body: $jsonBody");

        final response = await http.post(
          Uri.parse(AppLinks.bankAccounts),
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
          message = "Bank account created successfully.";
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
          _bankNameController.clear();
          _accountHolderNameController.clear();
          _cardNumberController.clear();
          _ibanController.clear();
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
          title: const Text('افزودن حساب بانکی جدید'),
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
                    controller: _bankNameController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'نام بانک',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفا نام بانک را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _accountHolderNameController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'نام صاحب حساب',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفا نام صاحب حساب را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _cardNumberController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      labelText: 'شماره کارت (اختیاری)',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _ibanController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      labelText: 'شماره شبا (IBAN) (اختیاری)',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      hintText: 'IR',
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  SizedBox(
                    width: double.infinity,
                    child: AppButtons.primaryButton(
                      onPressed: _isLoading ? () {} : _addBankAccount,
                      icon: Icons.add_circle_outline,
                      label: 'افزودن حساب بانکی',
                      isLoading: _isLoading,
                      isFullWidth: true,
                    ),
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