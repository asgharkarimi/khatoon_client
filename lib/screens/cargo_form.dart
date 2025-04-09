import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../app_links.dart';
import '../models/cargo_model.dart';
import '../models/vehicle.dart';
import '../models/driver.dart';
import '../models/cargo_type.dart';
import '../models/customer.dart';
import '../models/cargo_selling_company.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import '../widgets/app_buttons.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:ui' as ui;

class CargoForm extends StatefulWidget {
  static const routeName = '/add-cargo';

  const CargoForm({super.key});

  @override
  State<CargoForm> createState() => _CargoFormState();
}

class _CargoFormState extends State<CargoForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingReferences = true;
  String? _error;

  // Form field values
  int? _vehicleId;
  int? _driverId;
  Driver? _selectedDriver;
  int? _cargoTypeId;
  int? _customerId;
  int? _shippingCompanyId;
  int? _sellingCompanyId;
  String _origin = '';
  String _destination = '';
  DateTime? _loadingDate;
  DateTime? _unloadingDate;
  double _weightTonnes = 0.0;
  double _pricePerTonne = 0.0;
  double _transportCostPerTonne = 0.0;
  int? _customerPaymentStatusId = 1; // Default to "Not Received"
  bool _sellerPaymentStatus = false;
  double? _waybillAmount;
  String? _waybillImagePath; // Local path for newly selected image
  int? _customerBankAccountId;

  // Reference data
  List<Vehicle> _vehicles = [];
  List<Driver> _drivers = [];
  List<CargoType> _cargoTypes = [];
  List<Customer> _customers = [];
  List<CargoSellingCompany> _sellingCompanies = [];
  List<Map<String, dynamic>> _paymentTypes = [];
  List<Map<String, dynamic>> _shippingCompanies = [];
  List<dynamic> _bankAccounts = [];

  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _transportCostController = TextEditingController();
  final _waybillAmountController = TextEditingController();

  // Add these fields for image handling
  final ImagePicker _picker = ImagePicker();

  // Display variables
  bool _showDriverIncomeSection = false;

  final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    _fetchReferenceData();
    
    // Add listeners to update calculations when values change
    _weightController.addListener(_updateCalculations);
    _priceController.addListener(_updateCalculations);
    _transportCostController.addListener(_updateCalculations);
  }

  Future<void> _fetchReferenceData() async {
    setState(() {
      _isLoadingReferences = true;
      _error = null;
    });

    try {
      // Fetch all reference data in parallel
      final vehiclesResponse = await http.get(Uri.parse(AppLinks.vehicles));
      final driversResponse = await http.get(Uri.parse(AppLinks.drivers));
      final cargoTypesResponse = await http.get(Uri.parse(AppLinks.cargoTypes));
      final customersResponse = await http.get(Uri.parse(AppLinks.customers));
      final sellingCompaniesResponse = await http.get(Uri.parse(AppLinks.cargoSellingCompanies));
      final bankAccountsResponse = await http.get(Uri.parse(AppLinks.bankAccounts));
      final shippingCompaniesResponse = await http.get(Uri.parse(AppLinks.shippingCompanies));
      
      // Parse the data
      if (vehiclesResponse.statusCode == 200) {
        final List<dynamic> vehicleData = json.decode(vehiclesResponse.body);
        _vehicles = vehicleData.map((data) => Vehicle.fromJson(data)).toList();
      }
      
      if (driversResponse.statusCode == 200) {
        final List<dynamic> driverData = json.decode(driversResponse.body);
        _drivers = driverData.map((data) => Driver.fromJson(data)).toList();
      }
      
      if (cargoTypesResponse.statusCode == 200) {
        final List<dynamic> cargoTypeData = json.decode(cargoTypesResponse.body);
        _cargoTypes = cargoTypeData.map((data) => CargoType.fromJson(data)).toList();
      }
      
      if (customersResponse.statusCode == 200) {
        final List<dynamic> customerData = json.decode(customersResponse.body);
        _customers = customerData.map((data) => Customer.fromJson(data)).toList();
      }
      
      if (sellingCompaniesResponse.statusCode == 200) {
        final List<dynamic> sellingCompanyData = json.decode(sellingCompaniesResponse.body);
        _sellingCompanies = sellingCompanyData.map((data) => CargoSellingCompany.fromJson(data)).toList();
      }
      
      if (bankAccountsResponse.statusCode == 200) {
        final List<dynamic> bankAccountData = json.decode(bankAccountsResponse.body);
        _bankAccounts = bankAccountData;
      }
      
      if (shippingCompaniesResponse.statusCode == 200) {
        final List<dynamic> shippingCompanyData = json.decode(shippingCompaniesResponse.body);
        _shippingCompanies = shippingCompanyData.map((company) => {
          'id': int.parse(company['id'].toString()),
          'name': company['name'].toString()
        }).toList();
      } else {
        // Fallback to hardcoded values if API fails
        _shippingCompanies = [
          {'id': 1, 'name': 'شرکت حمل و نقل 1'},
          {'id': 2, 'name': 'شرکت حمل و نقل 2'},
        ];
      }
      
      _paymentTypes = [
        {'id': 1, 'name': 'دریافت نشده'},
        {'id': 2, 'name': 'بخشی دریافت شده'},
        {'id': 3, 'name': 'تماماً دریافت شده'},
      ];

      setState(() {
        _isLoadingReferences = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطا در دریافت اطلاعات: $e';
        _isLoadingReferences = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Form validation failed
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
      if (_waybillImagePath != null) {
        try {
          uploadedImageUrl = await _uploadImageFile(_waybillImagePath!);
          print("Image uploaded successfully: $uploadedImageUrl");
        } catch (e) {
          print("Error uploading image: $e");
          // Continue with form submission even if image upload fails
        }
      }
      
      final cargoData = {
        'vehicle_id': _vehicleId,
        'driver_id': _driverId,
        'cargo_type_id': _cargoTypeId,
        'customer_id': _customerId,
        'shipping_company_id': _shippingCompanyId,
        'selling_company_id': _sellingCompanyId,
        'origin': _origin,
        'destination': _destination,
        'loading_date': _loadingDate != null ? DateFormat('yyyy-MM-dd').format(_loadingDate!) : null,
        'unloading_date': _unloadingDate != null ? DateFormat('yyyy-MM-dd').format(_unloadingDate!) : null,
        'weight_tonnes': _weightTonnes,
        'price_per_tonne': _pricePerTonne,
        'transport_cost_per_tonne': _transportCostPerTonne,
        'customer_payment_status_id': _customerPaymentStatusId,
        'seller_payment_status': _sellerPaymentStatus,
        'waybill_amount': _waybillAmount,
        'waybill_image': uploadedImageUrl, // Use the uploaded image URL instead of local path
        'customer_bank_account_id': _customerBankAccountId,
      };
      
      // Debug print the JSON data
      print("\n=== CARGO FORM DATA (JSON) ===");
      print(json.encode(cargoData));
      print("==============================\n");
      
      print("Request data: ${json.encode(cargoData)}");
      
      final response = await http.post(
        Uri.parse(AppLinks.cargos),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cargoData),
      );
      
      if (response.statusCode == 201) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بار با موفقیت افزوده شد')),
        );
        Navigator.of(context).pop();
      } else {
        // Error
        final errorData = json.decode(response.body);
        setState(() {
          _error = errorData['message'] ?? 'خطا در افزودن بار';
          _isLoading = false;
        });
      }
      
      print("API response: ${response.body}");
    } catch (e) {
      setState(() {
        _error = 'خطا: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isLoadingDate) async {
    Jalali? picked = await showPersianDatePicker(
      context: context,
      initialDate: isLoadingDate && _loadingDate != null
          ? Jalali.fromDateTime(_loadingDate!)
          : !isLoadingDate && _unloadingDate != null
              ? Jalali.fromDateTime(_unloadingDate!)
              : Jalali.now(),
      firstDate: Jalali(1380, 1),
      lastDate: Jalali(1450, 12),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            fontFamily: 'Vazir',
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isLoadingDate) {
          _loadingDate = picked.toDateTime();
        } else {
          _unloadingDate = picked.toDateTime();
        }
      });
    }
  }

  // Request permissions for camera or gallery
  Future<bool> _requestPermissions(ImageSource source) async {
    if (Platform.isAndroid) {
      if (source == ImageSource.camera) {
        var cameraStatus = await Permission.camera.status;
        if (cameraStatus.isDenied) {
          cameraStatus = await Permission.camera.request();
        }
        
        if (cameraStatus.isPermanentlyDenied) {
          // Show dialog to guide user to app settings
          _showPermissionSettingsDialog('دوربین');
          return false;
        }
        
        if (cameraStatus.isGranted) {
          return true;
        }
      } else {
        // For gallery access on Android 13+, we need to request storage or photos permission
        var storageStatus = await Permission.storage.status;
        var photosStatus = await Permission.photos.status;
        
        if (storageStatus.isDenied) {
          storageStatus = await Permission.storage.request();
        }
        
        if (photosStatus.isDenied) {
          photosStatus = await Permission.photos.request();
        }
        
        if (storageStatus.isPermanentlyDenied && photosStatus.isPermanentlyDenied) {
          // Show dialog to guide user to app settings
          _showPermissionSettingsDialog('گالری');
          return false;
        }
        
        if (storageStatus.isGranted || photosStatus.isGranted) {
          return true;
        }
      }
    } else {
      // iOS logic
      if (source == ImageSource.camera) {
        var cameraStatus = await Permission.camera.request();
        if (cameraStatus.isGranted) {
          return true;
        } else if (cameraStatus.isPermanentlyDenied) {
          _showPermissionSettingsDialog('دوربین');
          return false;
        }
      } else {
        var photosStatus = await Permission.photos.request();
        if (photosStatus.isGranted) {
          return true;
        } else if (photosStatus.isPermanentlyDenied) {
          _showPermissionSettingsDialog('گالری');
          return false;
        }
      }
    }
    
    // If we reach here, permissions were denied
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('دسترسی به دوربین یا گالری داده نشد. لطفا دوباره تلاش کنید.'),
        duration: Duration(seconds: 3),
      ),
    );
    
    return false;
  }
  
  // Show dialog to guide user to app settings
  void _showPermissionSettingsDialog(String permissionType) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('نیاز به دسترسی $permissionType'),
          content: Text(
            'برای استفاده از این ویژگی، اپلیکیشن نیاز به دسترسی $permissionType دارد. '
            'لطفاً از تنظیمات گوشی دسترسی‌های برنامه را فعال کنید.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('بعداً'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('باز کردن تنظیمات'),
            ),
          ],
        );
      },
    );
  }
  
  // Method to pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      // First request permissions
      final bool hasPermission = await _requestPermissions(source);
      
      if (!hasPermission) {
        return;
      }
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _waybillImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در انتخاب تصویر: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Add this new method for image upload
  Future<String?> _uploadImageFile(String filePath) async {
    // Create multipart request
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppLinks.uploadImage),
    );
    
    // Get file name from path
    final fileName = path.basename(filePath);
    
    // Add the file to the request
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // Use 'file' as the field name since that's what the server expects
        filePath,
        filename: fileName,
      ),
    );
    
    try {
      // Send the request
      final streamedResponse = await request.send();
      
      // Get the response
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        // Parse the response to get the URL
        final responseData = json.decode(response.body);
        
        // Check if upload was successful
        if (responseData['status'] == 'success') {
          // Return the full URL by combining base URL with the returned file path
          return '${AppLinks.baseUrl}/${responseData['file_path']}';
        } else {
          print('Image upload server error: ${responseData['message']}');
          return null;
        }
      } else {
        print('Failed to upload image: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Method to parse current input values for calculations
  void _updateCalculations() {
    setState(() {
      // Only update if values are valid numbers
      try {
        if (_weightController.text.isNotEmpty) {
          _weightTonnes = (double.tryParse(_weightController.text) ?? 0) / 1000.0;
        }
        
        if (_priceController.text.isNotEmpty) {
          _pricePerTonne = double.tryParse(_priceController.text) ?? 0;
        }
        
        if (_transportCostController.text.isNotEmpty) {
          _transportCostPerTonne = double.tryParse(_transportCostController.text) ?? 0;
        }
        
        // Update whether to show driver income section
        _showDriverIncomeSection = _selectedDriver != null;
        
      } catch (e) {
        print("Error parsing numbers in _updateCalculations: $e");
        // Ignore parse errors while typing
      }
    });
  }

  // Display formatted number with thousand separators
  String formatNumberWithCommas(dynamic value) {
    if (value == null) return '';
    
    try {
      // Convert to double if it's a string
      double numValue = value is String 
        ? (double.tryParse(value) ?? 0) 
        : (value is double ? value : 0);
      
      final formatter = NumberFormat('#,###', 'fa');
      return formatter.format(numValue);
    } catch (e) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('افزودن بار جدید'),
        ),
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: _isLoading ? () {} : _submitForm,
          icon: _isLoading ? Icons.hourglass_empty : Icons.add,
          label: 'افزودن بار',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: const SizedBox(height: 10),
        body: _isLoadingReferences
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _fetchReferenceData,
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle dropdown
                          DropdownButtonFormField<int>(
                            value: _vehicleId,
                            decoration: const InputDecoration(
                              labelText: 'خودرو',
                              border: OutlineInputBorder(),
                            ),
                            items: _vehicles.map((vehicle) {
                              return DropdownMenuItem<int>(
                                value: vehicle.id,
                                child: Text(vehicle.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _vehicleId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً یک خودرو انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Driver dropdown
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'راننده',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: _drivers.map((driver) {
                              return DropdownMenuItem<int>(
                                value: driver.id,
                                child: Text('${driver.firstName} ${driver.lastName}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _driverId = value;
                                _selectedDriver = _drivers.firstWhere((driver) => driver.id == value);
                                _showDriverIncomeSection = true;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً یک راننده انتخاب کنید';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _driverId = value;
                              if (value != null) {
                                _selectedDriver = _drivers.firstWhere((driver) => driver.id == value);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Cargo Type dropdown
                          DropdownButtonFormField<int>(
                            value: _cargoTypeId,
                            decoration: const InputDecoration(
                              labelText: 'نوع بار',
                              border: OutlineInputBorder(),
                            ),
                            items: _cargoTypes.map((type) {
                              return DropdownMenuItem<int>(
                                value: type.id,
                                child: Text(type.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _cargoTypeId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً نوع بار را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Customer dropdown
                          DropdownButtonFormField<int>(
                            value: _customerId,
                            decoration: const InputDecoration(
                              labelText: 'مشتری',
                              border: OutlineInputBorder(),
                            ),
                            items: _customers.map((customer) {
                              return DropdownMenuItem<int>(
                                value: customer.id,
                                child: Text('${customer.firstName} ${customer.lastName}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _customerId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً یک مشتری انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Shipping Company dropdown
                          DropdownButtonFormField<int>(
                            value: _shippingCompanyId,
                            decoration: const InputDecoration(
                              labelText: 'شرکت حمل و نقل',
                              border: OutlineInputBorder(),
                            ),
                            items: _shippingCompanies.map((company) {
                              return DropdownMenuItem<int>(
                                value: company['id'] as int,
                                child: Text(company['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _shippingCompanyId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً یک شرکت حمل و نقل انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Selling Company dropdown
                          DropdownButtonFormField<int>(
                            value: _sellingCompanyId,
                            decoration: const InputDecoration(
                              labelText: 'شرکت فروشنده',
                              border: OutlineInputBorder(),
                            ),
                            items: _sellingCompanies.map((company) {
                              return DropdownMenuItem<int>(
                                value: company.id,
                                child: Text(company.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _sellingCompanyId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً یک شرکت فروشنده انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Origin field
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'مبدا',
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (value) {
                              // Ensure "0" is not treated as empty
                              _origin = value?.trim() ?? '';
                            },
                            validator: (value) {
                              // Check if value is null or empty after trimming
                              if (value == null || value.trim().isEmpty) {
                                return 'لطفاً مبدا را وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Destination field
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'مقصد',
                              border: OutlineInputBorder(),
                            ),
                            onSaved: (value) {
                              // Ensure "0" is not treated as empty
                              _destination = value?.trim() ?? '';
                            },
                            validator: (value) {
                              // Check if value is null or empty after trimming
                              if (value == null || value.trim().isEmpty) {
                                return 'لطفاً مقصد را وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Loading Date picker
                          InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'تاریخ بارگیری',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _loadingDate == null
                                    ? 'انتخاب تاریخ'
                                    : Jalali.fromDateTime(_loadingDate!).formatFullDate(),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Unloading Date picker
                          InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'تاریخ تخلیه',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _unloadingDate == null
                                    ? 'انتخاب تاریخ'
                                    : Jalali.fromDateTime(_unloadingDate!).formatFullDate(),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Weight field
                          TextFormField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              labelText: 'وزن (کیلوگرم)',
                              hintText: 'مثال: 15,000',
                              border: const OutlineInputBorder(),
                              helperText: _weightController.text.isNotEmpty ? 
                                'نمایش: ${_numberFormat.format(int.tryParse(_weightController.text.replaceAll(',', '')) ?? 0)}' : null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً وزن را وارد کنید';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final rawValue = value.replaceAll(',', '');
                                final parsedValue = int.tryParse(rawValue);
                                if (parsedValue != null) {
                                  _weightController.value = TextEditingValue(
                                    text: _numberFormat.format(parsedValue),
                                    selection: TextSelection.collapsed(offset: _numberFormat.format(parsedValue).length),
                                  );
                                }
                              }
                            },
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                _weightTonnes = double.parse(value.replaceAll(',', '')) / 1000.0;
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Price per tonne field
                          TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'قیمت هر تن (تومان)',
                              hintText: 'مثال: 1,000,000',
                              border: const OutlineInputBorder(),
                              helperText: _priceController.text.isNotEmpty ? 
                                'نمایش: ${_numberFormat.format(int.tryParse(_priceController.text.replaceAll(',', '')) ?? 0)}' : null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً قیمت را وارد کنید';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final rawValue = value.replaceAll(',', '');
                                final parsedValue = int.tryParse(rawValue);
                                if (parsedValue != null) {
                                  _priceController.value = TextEditingValue(
                                    text: _numberFormat.format(parsedValue),
                                    selection: TextSelection.collapsed(offset: _numberFormat.format(parsedValue).length),
                                  );
                                }
                              }
                            },
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                _pricePerTonne = double.parse(value.replaceAll(',', '')) * 10; // Convert to Rials
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Transport cost per tonne field
                          TextFormField(
                            controller: _transportCostController,
                            decoration: InputDecoration(
                              labelText: 'هزینه حمل هر تن (تومان)',
                              hintText: 'مثال: 200,000',
                              border: const OutlineInputBorder(),
                              helperText: _transportCostController.text.isNotEmpty ? 
                                'نمایش: ${_numberFormat.format(int.tryParse(_transportCostController.text.replaceAll(',', '')) ?? 0)}' : null,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً هزینه حمل را وارد کنید';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final rawValue = value.replaceAll(',', '');
                                final parsedValue = int.tryParse(rawValue);
                                if (parsedValue != null) {
                                  _transportCostController.value = TextEditingValue(
                                    text: _numberFormat.format(parsedValue),
                                    selection: TextSelection.collapsed(offset: _numberFormat.format(parsedValue).length),
                                  );
                                }
                              }
                            },
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                _transportCostPerTonne = double.parse(value.replaceAll(',', '')) * 10; // Convert to Rials
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Payment Status dropdown
                          DropdownButtonFormField<int>(
                            value: _customerPaymentStatusId,
                            decoration: const InputDecoration(
                              labelText: 'وضعیت پرداخت مشتری',
                              border: OutlineInputBorder(),
                            ),
                            items: _paymentTypes.map((type) {
                              return DropdownMenuItem<int>(
                                value: type['id'] as int,
                                child: Text(type['name'] as String),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _customerPaymentStatusId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Seller Payment Status checkbox
                          CheckboxListTile(
                            title: const Text('پرداخت به فروشنده انجام شده'),
                            value: _sellerPaymentStatus,
                            onChanged: (value) {
                              setState(() {
                                _sellerPaymentStatus = value ?? false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 16),
                          
                          // Customer Bank Account selection
                          DropdownButtonFormField<int>(
                            value: _customerBankAccountId,
                            decoration: const InputDecoration(
                              labelText: 'شماره حساب اعلامی به مشتری',
                              border: OutlineInputBorder(),
                            ),
                            items: _bankAccounts.map((account) {
                              return DropdownMenuItem<int>(
                                value: account['id'] is String ? int.parse(account['id']) : account['id'],
                                child: Text('${account['bank_name']} - ${account['account_holder_name']}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _customerBankAccountId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Waybill Amount
                          TextFormField(
                            controller: _waybillAmountController,
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              labelText: 'مبلغ بارنامه (تومان)',
                              border: const OutlineInputBorder(),
                              hintText: 'اختیاری',
                              helperText: _waybillAmountController.text.isNotEmpty ? 
                                'نمایش: ${formatNumberWithCommas(_waybillAmountController.text)}' : null,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (double.tryParse(value) == null) {
                                  return 'لطفاً یک عدد معتبر وارد کنید';
                                }
                              }
                              return null;
                            },
                            onSaved: (value) {
                              if (value != null && value.isNotEmpty) {
                                _waybillAmount = double.parse(value) * 10; // Convert to Rials for storage
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Waybill Image field
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تصویر بارنامه',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Display selected image if available
                                      if (_waybillImagePath != null)
                                        Column(
                                          children: [
                                            Container(
                                              height: 200,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Image.file(
                                                File(_waybillImagePath!),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'فایل انتخاب شده: ${_waybillImagePath!.split('/').last}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      
                                      // Buttons for selecting image
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _pickImage(ImageSource.gallery),
                                              icon: const Icon(Icons.photo_library),
                                              label: const Text('انتخاب از گالری'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _pickImage(ImageSource.camera),
                                              icon: const Icon(Icons.camera_alt),
                                              label: const Text('دوربین'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          
                          // Summary section
                          
                          
                          // Extra padding at the bottom to ensure content isn't covered by FAB
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  String _calculateDriverIncome() {
    if (_selectedDriver == null || _selectedDriver!.salaryPercentage == 0) {
      return '۰ تومان';
    }
    
    double weight = double.tryParse(_weightController.text) ?? 0;
    double transportCost = double.tryParse(_transportCostController.text) ?? 0;
    
    // Convert kg to tonnes
    weight = weight / 1000.0;
    
    // Calculate driver income: weight * transportCost * salaryPercentage / 100
    double income = weight * transportCost * (_selectedDriver?.salaryPercentage ?? 0) / 100;
    
    final formatter = NumberFormat('#,###', 'fa');
    return '${formatter.format(income)} تومان';
  }

  String _formatNumber(double number) {
    final formatter = NumberFormat('#,###', 'fa');
    return formatter.format(number);
  }
  
  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Remove listeners when disposing
    _weightController.removeListener(_updateCalculations);
    _priceController.removeListener(_updateCalculations);
    _transportCostController.removeListener(_updateCalculations);
    
    _weightController.dispose();
    _priceController.dispose();
    _transportCostController.dispose();
    _waybillAmountController.dispose();
    super.dispose();
  }
} 