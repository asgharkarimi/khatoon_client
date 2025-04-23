import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

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
  
  // Added fields for driver payment
  int? _selectedDriverId;
  String? _selectedDriverName;
  double _driverIncome = 0.0;
  
  // Added fields for cargo details
  String _cargoOrigin = '';
  String _cargoDestination = '';
  String _cargoLoadingDate = '';
  double _cargoWeight = 0.0;
  String _cargoDriverName = '';
  String _sellingCompanyName = '';
  String _payableAmount = '0';
  bool _showCargoDetails = false;
  double _pricePerTonne = 0.0;
  
  // Added fields for image picker
  final ImagePicker _picker = ImagePicker();
  File? _receiptImageFile;
  String? _receiptImageName;
  
  // Dropdown data
  List<Map<String, dynamic>> _cargos = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _bankAccounts = [];

  @override
  void initState() {
    super.initState();
    _fetchReferenceData();
    
    // Load existing payment data if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        // Handle existing payment data
        if (args['receipt_image'] != null) {
          setState(() {
            _receiptImage = args['receipt_image'];
          });
        }
        // Handle other fields as needed...
      }
    });
    
    // Set Locale for number formatting
    Intl.defaultLocale = 'fa_IR';
    
    // Add listeners to update calculations when values change
    _amountController.addListener(_updateCalculations);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchReferenceData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch cargos
      final cargosResponse = await http.get(Uri.parse(AppLinks.cargos));
      if (cargosResponse.statusCode == 200) {
        final List<dynamic> cargoData = json.decode(cargosResponse.body);
        if (!mounted) return;
        setState(() {
          _cargos = cargoData.map((data) => {
            'id': int.parse(data['id'].toString()),
            'title': '${data['origin']} → ${data['destination']}',
            'driverId': data['driver_id'] != null ? int.parse(data['driver_id'].toString()) : null,
            'driverName': data['driver_name'],
            'driverIncome': data['driver_income'] != null ? double.parse(data['driver_income'].toString()) / 10 : 0.0, // Convert to Toman
            'origin': data['origin'],
            'destination': data['destination'],
            'loadingDate': data['loading_date'] != null ? _formatJalaliDate(data['loading_date']) : 'نامشخص',
            'weightTonnes': data['weight_tonnes'] != null ? double.parse(data['weight_tonnes'].toString()) : 0.0,
            'pricePerTonne': data['price_per_tonne'] != null ? double.parse(data['price_per_tonne'].toString()) : 0.0,
            'sellingCompanyId': data['selling_company_id'] != null ? int.parse(data['selling_company_id'].toString()) : null,
            'sellingCompanyName': data['selling_company_name'],
          }).toList();
        });
      }

      // Fetch companies
      final companiesResponse = await http.get(Uri.parse(AppLinks.cargoSellingCompanies));
      if (companiesResponse.statusCode == 200) {
        final List<dynamic> companyData = json.decode(companiesResponse.body);
        if (!mounted) return;
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
        if (!mounted) return;
        setState(() {
          _bankAccounts = bankAccountData.map((data) => {
            'id': int.parse(data['id'].toString()),
            'title': '${data['bank_name']} - ${data['account_holder_name']}',
            'bank_name': data['bank_name'],
            'account_holder_name': data['account_holder_name'],
          }).toList();
        });
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      
      // Format the number with thousand separators
      // Use different formatting for integers vs decimals
      if (number == number.toInt()) {
        // Integer - don't show decimal part
        final formatter = NumberFormat('#,###', 'fa_IR');
        return formatter.format(number.toInt());
      } else {
        // Has decimal part
        final formatter = NumberFormat('#,###.##', 'fa_IR');
        return formatter.format(number);
      }
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

  void _updateSelectedCargo(int? cargoId) {
    if (!mounted) return;
    
    setState(() {
      _selectedCargoId = cargoId;
      _showCargoDetails = false;
      
      // Find the selected cargo
      if (cargoId != null) {
        final selectedCargo = _cargos.firstWhere(
          (cargo) => cargo['id'] == cargoId,
          orElse: () => <String, dynamic>{},
        );
        
        // Update driver information
        _selectedDriverId = selectedCargo['driverId'];
        _selectedDriverName = selectedCargo['driverName'];
        _driverIncome = selectedCargo['driverIncome'] ?? 0.0;
        
        // Auto-select selling company
        _selectedCompanyId = selectedCargo['sellingCompanyId'];
        _sellingCompanyName = selectedCargo['sellingCompanyName'] ?? '';
        
        // Update cargo details
        _cargoOrigin = selectedCargo['origin'] ?? '';
        _cargoDestination = selectedCargo['destination'] ?? '';
        _cargoLoadingDate = selectedCargo['loadingDate'] ?? '';
        _cargoWeight = selectedCargo['weightTonnes'] ?? 0.0;
        _cargoDriverName = selectedCargo['driverName'] ?? '';
        _pricePerTonne = selectedCargo['pricePerTonne'] ?? 0.0;
        
        // Calculate payable amount based on price per tonne and weight
        double calculatedPayableAmount = _pricePerTonne * _cargoWeight;
        
        // Auto-fill the amount field with the calculated amount
        _amountController.text = _formatNumber(calculatedPayableAmount.toString());
        _amount = calculatedPayableAmount;
        
        // Format payable amount with price formatter
        _payableAmount = _formatPrice(calculatedPayableAmount).replaceAll(' تومان', '');
        
        _showCargoDetails = true;
      }
    });
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Reduce image quality to decrease file size
      );
      
      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _receiptImageFile = File(pickedFile.path);
          _receiptImageName = pickedFile.name;
          _receiptImage = pickedFile.path; // Store path for API
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = null; // Don't show error in main screen
      });
      
      // Show error dialog with proper styling
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 10),
                const Text('خطا در انتخاب تصویر'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'امکان استفاده از دوربین وجود ندارد.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    e.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'لطفا از گالری استفاده کنید یا دسترسی‌های برنامه را بررسی نمایید.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Try gallery instead
                  _pickImage(ImageSource.gallery);
                },
                child: const Text('استفاده از گالری'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('متوجه شدم'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Show options to pick image
  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('انتخاب از گالری'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('گرفتن عکس با دوربین'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Upload receipt image and return the image name on server
  Future<String?> _uploadReceiptImage() async {
    if (_receiptImageFile == null) {
      return null;
    }
    
    try {
      final uploadUrl = AppLinks.uploadImage;
      
      // Log upload URL and file info
      print('====== IMAGE UPLOAD DEBUG INFO ======');
      print('Upload URL: $uploadUrl');
      print('File exists: ${await _receiptImageFile!.exists()}');
      print('File size: ${await _receiptImageFile!.length()} bytes');
      print('File path: ${_receiptImageFile!.path}');
      
      // Create multipart request with proper fields
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(uploadUrl),
      );
      
      // Add file as multipart
      var file = await http.MultipartFile.fromPath(
        'image', 
        _receiptImageFile!.path,
        filename: _receiptImageName ?? 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      request.files.add(file);
      
      // Add type information to help with organization
      request.fields['image_type'] = 'receipt';
      
      // Send the request
      print('Sending request...');
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: $responseData');
      print('====== END DEBUG INFO ======');
      
      if (response.statusCode == 200) {
        // Parse response
        final jsonResponse = json.decode(responseData);
        
        if (jsonResponse['success'] == true) {
          // Extract file path from response (contains the server URL)
          final imageUrl = jsonResponse['file_path'];
          print('File uploaded successfully: $imageUrl');
          
          // Return the image URL for storage in DB
          return imageUrl;
        } else {
          throw Exception('Upload failed: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (!mounted) return null;
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('خطا در آپلود تصویر'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString()),
                const SizedBox(height: 16),
                const Text('آیا می‌خواهید بدون تصویر ادامه دهید؟'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _receiptImageFile = null;
                    _receiptImage = null;
                  });
                },
                child: const Text('ادامه بدون تصویر'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('بستن'),
              ),
            ],
          ),
        ),
      );
      
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Upload receipt image if available
      String? uploadedImagePath;
      if (_receiptImageFile != null) {
        uploadedImagePath = await _uploadReceiptImage();
        
        // If upload fails and user doesn't want to continue, stop submission
        if (uploadedImagePath == null && _receiptImageFile != null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      // Create payment data
      final Map<String, dynamic> paymentData = {
        'cargo_id': _selectedCargoId,
        'driver_id': _selectedDriverId,
        'amount': _amount,
        'company_id': _selectedCompanyId,
        'payment_date': _paymentDate?.toDateTime().toIso8601String(),
      };
      
      // Add optional fields if they exist
      if (_selectedBankAccountId != null) {
        paymentData['bank_account_id'] = _selectedBankAccountId;
      }
      
      // Add receipt image path if available
      if (uploadedImagePath != null) {
        paymentData['receipt_image'] = uploadedImagePath;
      }

      // Print JSON data for debugging
      print('Payment Data JSON:');
      print(json.encode(paymentData));
      print('-------------------');

      // POST to payments.php endpoint
      final response = await http.post(
        Uri.parse(AppLinks.payments),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(paymentData),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پرداخت با موفقیت ثبت شد'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        final errorData = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _error = errorData['message'] ?? 'خطا در ثبت پرداخت به شرکت';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
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
          title: const Text('ثبت پرداخت جدید به شرکت'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
                              _updateSelectedCargo(value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفا بار را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          
                          // Show cargo details card when cargo is selected
                          if (_showCargoDetails) ...[
                            const SizedBox(height: 16),
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'جزئیات بار',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const Divider(height: 24),
                                    _buildDetailRow('مسیر', '$_cargoOrigin به $_cargoDestination'),
                                    _buildDetailRow('تاریخ بارگیری', _cargoLoadingDate),
                                    _buildDetailRow('وزن بار', _formatWeight(_cargoWeight)),
                                    _buildDetailRow('قیمت هر تن', _formatPrice(_pricePerTonne)),
                                    _buildDetailRow('راننده', _cargoDriverName),
                                    _buildDetailRow('شرکت فروشنده', _sellingCompanyName),
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'مبلغ کل: $_payableAmount تومان',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'مبلغ پرداخت',
                              border: OutlineInputBorder(),
                              prefixText: '  تومان',
                              prefixStyle: TextStyle(color: Colors.grey),
                              hintText: '0',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.left,
                            textDirection: ui.TextDirection.ltr,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            ],
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                // Format with dot as thousand separator
                                final cleanValue = value.replaceAll('.', '');
                                try {
                                  final number = double.parse(cleanValue);
                                  
                                  // Format with dot as thousand separator
                                  String formattedValue = '';
                                  String numStr = number.toInt().toString();
                                  
                                  for (int i = 0; i < numStr.length; i++) {
                                    if (i > 0 && (numStr.length - i) % 3 == 0) {
                                      formattedValue += '.';
                                    }
                                    formattedValue += numStr[i];
                                  }
                                  
                                  // Set the formatted value while maintaining cursor position
                                  final cursorPos = _amountController.selection.base.offset;
                                  
                                  // Only update if the format is different
                                  if (formattedValue != value) {
                                    // Calculate new cursor position based on difference in length
                                    final lengthDiff = formattedValue.length - value.length;
                                    final newPosition = cursorPos + lengthDiff;
                                    
                                    _amountController.value = TextEditingValue(
                                      text: formattedValue,
                                      selection: TextSelection.collapsed(
                                        offset: newPosition > 0 ? newPosition : 0
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // If parsing fails, keep original value
                                }
                              }
                            },
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                _amount = double.parse(value.replaceAll('.', ''));
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفا مبلغ را وارد کنید';
                              }
                              if (double.tryParse(value.replaceAll('.', '')) == null) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Company selection
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
                              if (!mounted) return;
                              setState(() {
                                _selectedCompanyId = value;
                              });
                            },
                            validator: (value) {
                              if (_selectedCompanyId == null) {
                                return 'لطفا شرکت را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int?>(
                            value: _selectedBankAccountId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'حساب بانکی',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('حسابی معرفی نشده'),
                              ),
                              ...(_bankAccounts ?? []).map((account) {
                                return DropdownMenuItem<int?>(
                                  value: account['id'],
                                  child: Text(
                                    '${account['bank_name']} - ${account['account_holder_name']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (int? newValue) {
                              setState(() {
                                _selectedBankAccountId = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Image picker field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InkWell(
                                onTap: () => _showImagePicker(context),
                                child: Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _receiptImageFile != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.file(
                                            _receiptImageFile!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : _receiptImage != null && _receiptImage!.startsWith('http')
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.network(
                                                _receiptImage!,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / 
                                                              loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey.shade400,
                                                        size: 40,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'خطا در بارگذاری تصویر',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 40,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'تصویر فیش پرداخت',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'برای آپلود ضربه بزنید',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                ),
                              ),
                              if (_receiptImageFile != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _receiptImageFile = null;
                                        _receiptImageName = null;
                                        _receiptImage = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                    label: const Text('حذف تصویر', style: TextStyle(color: Colors.red)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await showPersianDatePicker(
                                context: context,
                                initialDate: _paymentDate ?? Jalali.now(),
                                firstDate: Jalali(1380, 1),
                                lastDate: Jalali.now(),
                                locale: const Locale('fa', 'IR'),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData(
                                      fontFamily: 'Vazir',
                                      primaryColor: Theme.of(context).primaryColor,
                                      colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
                                      buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                      textTheme: const TextTheme(
                                        titleMedium: TextStyle(fontFamily: 'Vazir'),
                                        bodyLarge: TextStyle(fontFamily: 'Vazir'),
                                        bodyMedium: TextStyle(fontFamily: 'Vazir'),
                                        labelLarge: TextStyle(fontFamily: 'Vazir'),
                                      ),
                                    ),
                                    child: Directionality(
                                      textDirection: ui.TextDirection.rtl,
                                      child: child!,
                                    ),
                                  );
                                },
                              );
                              if (picked != null) {
                                if (!mounted) return;
                                setState(() {
                                  _paymentDate = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _paymentDate != null
                                        ? 'تاریخ پرداخت: ${_paymentDate!.formatCompactDate()}'
                                        : 'تاریخ پرداخت',
                                      style: TextStyle(
                                        color: _paymentDate != null ? Colors.black87 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: _isLoading ? () {} : _submitForm,
          icon: _isLoading ? Icons.hourglass_empty : Icons.save,
          label: 'ثبت پرداخت به شرکت',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: const SizedBox(height: 10),
      ),
    );
  }

  // Format date to Jalali
  String _formatJalaliDate(String date) {
    try {
      return Jalali.fromDateTime(DateTime.parse(date)).formatCompactDate();
    } catch (e) {
      return 'نامشخص';
    }
  }

  // Format weight with proper units
  String _formatWeight(double weight) {
    // Format weight as integer if it's a whole number
    if (weight == weight.toInt()) {
      return '${_formatNumber(weight.toInt().toString())} تن';
    } else {
      return '${_formatNumber(weight.toString())} تن';
    }
  }

  // Format price with proper currency
  String _formatPrice(double price) {
    // Format price as integer if it's a whole number
    if (price == price.toInt()) {
      return '${_formatNumber(price.toInt().toString())} تومان';
    } else {
      return '${_formatNumber(price.toString())} تومان';
    }
  }

  // Build a detail row with label and value
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateCalculations() {
    if (_amountController.text.isNotEmpty) {
      String cleanValue = _amountController.text.replaceAll(',', '');
      try {
        double value = double.parse(cleanValue);
        if (!mounted) return;
        setState(() {
          _amount = value;
        });
      } catch (e) {
        // Invalid number - ignore
      }
    }
  }
} 