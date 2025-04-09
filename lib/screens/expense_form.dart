import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;

class ExpenseForm extends StatefulWidget {
  static const routeName = '/expense-form';

  const ExpenseForm({super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  bool _isLoadingCargos = true;
  String? _error;

  // Form field values
  String _description = '';
  int? _expenseTypeId;
  int? _cargoId;
  double _amount = 0.0;
  DateTime? _expenseDate;
  String? _receiptImagePath;

  // Controllers
  final _amountController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final NumberFormat _numberFormat = NumberFormat.decimalPattern();
  
  // Reference data for expense categories
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _cargos = [];

  @override
  void initState() {
    super.initState();
    _fetchExpenseCategories();
    _fetchCargos();
  }
  
  Future<void> _fetchExpenseCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _error = null;
    });
    
    try {
      final response = await http.get(Uri.parse('http://192.168.197.166/khatooonbar/expense_categories.php'));
      
      if (response.statusCode == 200) {
        final List<dynamic> categoriesData = json.decode(response.body);
        
        setState(() {
          _expenseCategories = categoriesData.map((data) => {
            'id': data['id'] is String ? int.parse(data['id']) : data['id'],
            'name': data['name'].toString(),
          }).toList();
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _error = 'خطا در دریافت دسته‌بندی‌ها: ${response.statusCode}';
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطا در دریافت دسته‌بندی‌ها: $e';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchCargos() async {
    setState(() {
      _isLoadingCargos = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('http://192.168.197.166/khatooonbar/cargos.php'));

      if (response.statusCode == 200) {
        final List<dynamic> cargosData = json.decode(response.body);

        setState(() {
          _cargos = cargosData.map((data) => {
            'id': data['id'] is String ? int.parse(data['id']) : data['id'],
            'title': data['title'].toString(),
            'origin': data['origin'].toString(),
            'destination': data['destination'].toString(),
            'date': data['date'].toString(),
          }).toList();
          _isLoadingCargos = false;
        });
      } else {
        setState(() {
          _error = 'خطا در دریافت بارنامه‌ها: ${response.statusCode}';
          _isLoadingCargos = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطا در دریافت بارنامه‌ها: $e';
        _isLoadingCargos = false;
      });
    }
  }

  Future<String?> _uploadImageFile(String filePath) async {
    try {
      final uri = Uri.parse(AppLinks.uploadImage);
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', filePath));
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseBody);
      
      if (response.statusCode == 200 && jsonResponse['filename'] != null) {
        return jsonResponse['filename'];
      } else {
        print('Error uploading image: ${jsonResponse['message']}');
        return null;
      }
    } catch (e) {
      print('Exception uploading image: $e');
      return null;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _receiptImagePath = image.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
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
      // Upload image file if selected
      String? uploadedImageUrl;
      if (_receiptImagePath != null) {
        uploadedImageUrl = await _uploadImageFile(_receiptImagePath!);
      }
      
      final expenseData = {
        'description': _description,
        'expense_type_id': _expenseTypeId,
        'amount': _amount,
        'expense_date': _expenseDate != null ? DateFormat('yyyy-MM-dd').format(_expenseDate!) : null,
        'receipt_image': uploadedImageUrl,
        'cargo_id': _cargoId,
      };
      
      final response = await http.post(
        Uri.parse(AppLinks.expenses),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(expenseData),
      );
      
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _error = errorData['message'] ?? 'خطا در ثبت هزینه';
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
          title: const Text('افزودن هزینه جدید'),
        ),
        body: _isLoadingCategories || _isLoadingCargos
            ? const Center(child: CircularProgressIndicator())
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            
                            // Description
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'عنوان هزینه',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً توضیحات را وارد کنید';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _description = value ?? '';
                              },
                            ),
                            const SizedBox(height: 16),

                            // Expense Type Dropdown
                            DropdownButtonFormField<int>(
                              value: _expenseTypeId,
                              decoration: const InputDecoration(
                                labelText: 'انتخاب دسته بندی',
                                border: OutlineInputBorder(),
                              ),
                              items: _expenseCategories.map((category) {
                                return DropdownMenuItem<int>(
                                  value: category['id'] as int,
                                  child: Text(category['name'] as String),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _expenseTypeId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'لطفاً نوع هزینه را انتخاب کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: _cargoId,
                              decoration: const InputDecoration(
                                labelText: 'انتخاب بارنامه',
                                border: OutlineInputBorder(),
                              ),
                              items: _cargos.map((cargo) {
                                final displayText = '${cargo['origin']} → ${cargo['destination']}';
                                return DropdownMenuItem<int>(
                                  value: cargo['id'] as int,
                                  child: Text(displayText),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _cargoId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'لطفاً بارنامه را انتخاب کنید';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Amount
                            TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                labelText: 'مبلغ (تومان)',
                                border: OutlineInputBorder(),
                                hintText: 'مثال: 1,000,000',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً مبلغ را وارد کنید';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  final rawValue = value.replaceAll(',', '');
                                  final parsedValue = int.tryParse(rawValue);
                                  if (parsedValue != null) {
                                    _amountController.value = TextEditingValue(
                                      text: _numberFormat.format(parsedValue),
                                      selection: TextSelection.collapsed(offset: _numberFormat.format(parsedValue).length),
                                    );
                                  }
                                }
                              },
                              onSaved: (value) {
                                if (value != null && value.isNotEmpty) {
                                  _amount = double.parse(value.replaceAll(',', ''));
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Expense Date
                            InkWell(
                              onTap: () async {
                                Jalali? picked = await showPersianDatePicker(
                                  context: context,
                                  initialDate: Jalali.now(),
                                  firstDate: Jalali(1380, 1),
                                  lastDate: Jalali(1410, 12),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _expenseDate = picked.toDateTime();
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'تاریخ هزینه',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _expenseDate != null
                                      ? Jalali.fromDateTime(_expenseDate!).formatFullDate()
                                      : 'انتخاب تاریخ',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Receipt Image
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('تصویر رسید:', style: TextStyle(fontSize: 16)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    AppButtons.imageSelectionButton(
                                      onPressed: () => _pickImage(ImageSource.gallery),
                                      icon: Icons.photo_library,
                                      label: 'انتخاب از گالری',
                                    ),
                                    AppButtons.imageSelectionButton(
                                      onPressed: () => _pickImage(ImageSource.camera),
                                      icon: Icons.camera_alt,
                                      label: 'دوربین',
                                    ),
                                  ],
                                ),
                                if (_receiptImagePath != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Image.file(
                                            File(_receiptImagePath!),
                                            fit: BoxFit.contain,
                                            height: 140,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _receiptImagePath = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'فایل انتخاب شده: ${_receiptImagePath!.split('/').last}',
                                    style: const TextStyle(color: Colors.green, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Cargo Dropdown
                            
                          

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: AppButtons.primaryButton(
                                onPressed: _submitForm,
                                icon: Icons.save,
                                label: 'ثبت هزینه',
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