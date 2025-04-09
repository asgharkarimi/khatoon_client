import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class PaymentForm extends StatefulWidget {
  static const routeName = '/payments/new';

  const PaymentForm({super.key});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  // Form fields
  int? _selectedCargoId;
  double _amount = 0;
  int? _selectedCompanyId;
  int? _selectedBankAccountId;
  String? _receiptImage;
  Jalali? _paymentDate;
  final _amountController = TextEditingController();

  // Dropdown data
  List<Map<String, dynamic>> _cargos = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _bankAccounts = [];

  @override
  void initState() {
    super.initState();
    _fetchReferenceData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchReferenceData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch cargos
      final cargosResponse = await http.get(Uri.parse(AppLinks.cargos));
      if (cargosResponse.statusCode == 200) {
        final List<dynamic> cargoData = json.decode(cargosResponse.body);
        setState(() {
          _cargos = cargoData.map((data) => {
            'id': int.parse(data['id'].toString()),
            'title': '${data['origin']} → ${data['destination']}',
          }).toList();
        });
      }

      // Fetch companies
      final companiesResponse = await http.get(Uri.parse(AppLinks.cargoSellingCompanies));
      if (companiesResponse.statusCode == 200) {
        final List<dynamic> companyData = json.decode(companiesResponse.body);
        setState(() {
          _companies = companyData.map((data) => {
            'id': int.parse(data['id'].toString()),
            'name': data['name'],
          }).toList();
        });
      }

      // Fetch bank accounts
      final bankAccountsResponse = await http.get(Uri.parse(AppLinks.bankAccounts));
      if (bankAccountsResponse.statusCode == 200) {
        final List<dynamic> bankAccountData = json.decode(bankAccountsResponse.body);
        setState(() {
          _bankAccounts = bankAccountData.map((data) => {
            'id': int.parse(data['id'].toString()),
            'title': '${data['bank_name']} - ${data['account_number']}',
          }).toList();
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطا در دریافت اطلاعات: $e';
        _isLoading = false;
      });
    }
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return value;
    
    // Remove existing commas
    String valueWithoutCommas = value.replaceAll(',', '');
    
    // Check if this is a valid number (allow decimal points)
    try {
      double number = double.parse(valueWithoutCommas);
      
      // Handle integer part with Western digits
      String formattedInteger = NumberFormat('#,###', 'en_US').format(number.truncate());
      
      // If there's a decimal part, keep it
      if (valueWithoutCommas.contains('.')) {
        int dotIndex = valueWithoutCommas.indexOf('.');
        String decimalPart = valueWithoutCommas.substring(dotIndex);
        return formattedInteger + decimalPart;
      }
      
      return formattedInteger;
    } catch (e) {
      return value; // Return original if not a valid number
    }
  }

  void _formatAndUpdateField(TextEditingController controller, String value) {
    if (value.isEmpty) return;
    
    // Save current selection
    int cursorPos = controller.selection.base.offset;
    if (cursorPos < 0) cursorPos = 0;
    
    // Only keep digits, period, and commas from the input
    String cleanedValue = value.replaceAll(RegExp(r'[^\d.,]'), '');
    
    // If we have nothing left after filtering, clear the controller
    if (cleanedValue.isEmpty) {
      controller.clear();
      return;
    }
    
    // Handle decimal points correctly
    String sanitizedValue = cleanedValue;
    
    // Remove any commas that were added for formatting
    sanitizedValue = sanitizedValue.replaceAll(',', '');
    
    // If there are multiple periods, keep only the first one
    int periodCount = '.'.allMatches(sanitizedValue).length;
    if (periodCount > 1) {
      int firstPeriodIndex = sanitizedValue.indexOf('.');
      sanitizedValue = 
          sanitizedValue.substring(0, firstPeriodIndex + 1) + 
          sanitizedValue.substring(firstPeriodIndex + 1).replaceAll('.', '');
    }
    
    // Format the number
    String formatted = _formatNumber(sanitizedValue);
    
    // Only update if the format is actually different
    if (formatted != value) {
      // Calculate cursor position
      int currentCursor = controller.selection.start;
      int newCursorPos;
      
      // If cursor is at the end, keep it at end
      if (currentCursor == controller.text.length) {
        newCursorPos = formatted.length;
      } else {
        // For mid-text edits, try to maintain relative cursor position
        // Count how many chars were added/removed
        int lengthDiff = formatted.length - controller.text.length;
        newCursorPos = currentCursor + lengthDiff;
        
        // Make sure cursor position is valid
        if (newCursorPos < 0) newCursorPos = 0;
        if (newCursorPos > formatted.length) newCursorPos = formatted.length;
      }
      
      // Update the value and cursor in the text field
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(AppLinks.payments),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cargo_id': _selectedCargoId,
          'amount': _amount,
          'company_id': _selectedCompanyId,
          'bank_account_id': _selectedBankAccountId,
          'receipt_image': _receiptImage,
          'payment_date': _paymentDate?.toDateTime().toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پرداخت با موفقیت ثبت شد')),
        );
        Navigator.of(context).pop();
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _error = errorData['message'] ?? 'خطا در ثبت پرداخت';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطا: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ثبت پرداخت جدید'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<int>(
                            value: _selectedCargoId,
                            decoration: const InputDecoration(
                              labelText: 'بار',
                              border: OutlineInputBorder(),
                            ),
                            items: _cargos.map((cargo) {
                              return DropdownMenuItem<int>(
                                value: cargo['id'],
                                child: Text(cargo['title']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCargoId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفا بار را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'مبلغ پرداخت',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.left,
                            textDirection: ui.TextDirection.ltr,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                            ],
                            onChanged: (value) {
                              _formatAndUpdateField(_amountController, value);
                            },
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                String cleanValue = value.replaceAll(',', '');
                                _amount = double.parse(cleanValue);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفا مبلغ را وارد کنید';
                              }
                              if (double.tryParse(value.replaceAll(',', '')) == null) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _selectedCompanyId,
                            decoration: const InputDecoration(
                              labelText: 'شرکت فروشنده',
                              border: OutlineInputBorder(),
                            ),
                            items: _companies.map((company) {
                              return DropdownMenuItem<int>(
                                value: company['id'],
                                child: Text(company['name']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCompanyId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفا شرکت را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _selectedBankAccountId,
                            decoration: const InputDecoration(
                              labelText: 'حساب بانکی',
                              border: OutlineInputBorder(),
                            ),
                            items: _bankAccounts.map((account) {
                              return DropdownMenuItem<int>(
                                value: account['id'],
                                child: Text(account['title']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBankAccountId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'تصویر فیش پرداخت',
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (value) {
                              _receiptImage = value;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'تاریخ پرداخت',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                              text: _paymentDate != null
                                  ? _paymentDate!.formatFullDate()
                                  : '',
                            ),
                            onTap: () async {
                              final picked = await showPersianDatePicker(
                                context: context,
                                initialDate: _paymentDate ?? Jalali.now(),
                                firstDate: Jalali(1300),
                                lastDate: Jalali.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _paymentDate = picked;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفا تاریخ را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: _isLoading ? () {} : _submitForm,
          icon: _isLoading ? Icons.hourglass_empty : Icons.save,
          label: 'ثبت پرداخت',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: const SizedBox(height: 10),
      ),
    );
  }
} 