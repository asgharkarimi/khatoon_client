import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../app_links.dart';
import '../models/bank_account.dart';

class BankAccountEditForm extends StatefulWidget {
  final BankAccount bankAccount;

  const BankAccountEditForm({
    super.key,
    required this.bankAccount,
  });

  @override
  State<BankAccountEditForm> createState() => _BankAccountEditFormState();
}

class _BankAccountEditFormState extends State<BankAccountEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountHolderNameController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _ibanController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing bank account data
    _bankNameController = TextEditingController(text: widget.bankAccount.bankName);
    _accountHolderNameController = TextEditingController(text: widget.bankAccount.accountHolderName);
    _cardNumberController = TextEditingController(text: widget.bankAccount.cardNumber ?? '');
    _ibanController = TextEditingController(text: widget.bankAccount.iban ?? '');
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderNameController.dispose();
    _cardNumberController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _updateBankAccount() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final jsonBody = jsonEncode(<String, dynamic>{
          'id': widget.bankAccount.id.toString(),
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

        final response = await http.put(
          Uri.parse(AppLinks.updateBankAccountById(widget.bankAccount.id)),
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
          message = "Bank account updated successfully.";
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
          title: const Text('ویرایش حساب بانکی'),
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
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('ذخیره تغییرات'),
                          onPressed: _updateBankAccount,
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