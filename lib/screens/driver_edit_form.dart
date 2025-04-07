import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../app_links.dart';
import '../models/driver.dart';
import '../widgets/app_buttons.dart';

class DriverEditForm extends StatefulWidget {
  final Driver driver;

  const DriverEditForm({
    super.key,
    required this.driver,
  });

  @override
  State<DriverEditForm> createState() => _DriverEditFormState();
}

class _DriverEditFormState extends State<DriverEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _salaryPercentageController;
  late final TextEditingController _nationalIdController;
  bool _isLoading = false;
  bool _isUploadingImages = false;
  
  // Image paths for newly selected images
  String? _nationalIdCardImagePath;
  String? _driverLicenseImagePath;
  String? _driverSmartCardImagePath;
  
  // Image URLs (existing or newly uploaded)
  String? _nationalIdCardImageUrl;
  String? _driverLicenseImageUrl;
  String? _driverSmartCardImageUrl;
  
  // Flags to track if image is changed
  bool _isNationalIdCardImageChanged = false;
  bool _isDriverLicenseImageChanged = false;
  bool _isDriverSmartCardImageChanged = false;
  
  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.driver.firstName);
    _lastNameController = TextEditingController(text: widget.driver.lastName);
    _phoneNumberController = TextEditingController(text: widget.driver.phoneNumber ?? '');
    _salaryPercentageController = TextEditingController(
        text: widget.driver.salaryPercentage?.toString() ?? '');
    _nationalIdController = TextEditingController(text: widget.driver.nationalId ?? '');
    
    // Initialize image URLs from the driver model
    _nationalIdCardImageUrl = widget.driver.nationalIdCardImage;
    _driverLicenseImageUrl = widget.driver.driverLicenseImage;
    _driverSmartCardImageUrl = widget.driver.driverSmartCardImage;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _salaryPercentageController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }
  
  // Upload an image to the server
  Future<String?> _uploadImage(String imagePath, String imageType) async {
    try {
      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppLinks.upload),
      );
      
      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', 
          imagePath,
          filename: '${DateTime.now().millisecondsSinceEpoch}_${imageType}_${imagePath.split('/').last}',
        ),
      );
      
      // Add image type as additional field
      request.fields['image_type'] = imageType;
      
      // Send the request
      final response = await request.send().timeout(const Duration(seconds: 30));
      
      // Check if upload was successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response
        final responseString = await response.stream.bytesToString();
        final responseData = jsonDecode(responseString);
        
        if (responseData['success'] == true && responseData['file_path'] != null) {
          return responseData['file_path'];
        } else {
          print('Upload error: ${responseData['message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during upload: $e');
      return null;
    }
  }
  
  // Upload all selected images
  Future<bool> _uploadAllImages() async {
    setState(() {
      _isUploadingImages = true;
    });
    
    try {
      // Upload national ID card image if changed
      if (_isNationalIdCardImageChanged && _nationalIdCardImagePath != null) {
        _nationalIdCardImageUrl = await _uploadImage(_nationalIdCardImagePath!, 'national_id');
        if (_nationalIdCardImageUrl == null) {
          return false;
        }
      }
      
      // Upload driver's license image if changed
      if (_isDriverLicenseImageChanged && _driverLicenseImagePath != null) {
        _driverLicenseImageUrl = await _uploadImage(_driverLicenseImagePath!, 'driver_license');
        if (_driverLicenseImageUrl == null) {
          return false;
        }
      }
      
      // Upload driver's smart card image if changed
      if (_isDriverSmartCardImageChanged && _driverSmartCardImagePath != null) {
        _driverSmartCardImageUrl = await _uploadImage(_driverSmartCardImagePath!, 'smart_card');
        if (_driverSmartCardImageUrl == null) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Exception during multi-upload: $e');
      return false;
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }
  
  // Request necessary permissions for image selection
  Future<bool> _requestPermissions(ImageSource source) async {
    print("درخواست دسترسی‌های لازم...");
    
    if (source == ImageSource.camera) {
      // For camera
      PermissionStatus camera = await Permission.camera.status;
      
      if (camera.isDenied) {
        print("دسترسی دوربین رد شده، درخواست دسترسی...");
        camera = await Permission.camera.request();
      }
      
      if (camera.isPermanentlyDenied) {
        print("دسترسی دوربین به صورت دائمی رد شده");
        _showOpenSettingsDialog("دسترسی به دوربین به صورت دائمی رد شده است. لطفا از طریق تنظیمات دستگاه این دسترسی را فعال کنید.");
        return false;
      }
      
      return camera.isGranted;
    } else {
      // For gallery
      if (Platform.isAndroid) {
        // Check Android version to request appropriate permissions
        final androidVersion = await _getAndroidVersion();
        print("Android version: $androidVersion");
        
        if (androidVersion >= 33) { // Android 13+
          print("درخواست دسترسی photos برای Android 13+");
          
          // First, check and request READ_MEDIA_IMAGES permission
          PermissionStatus mediaImages = await Permission.photos.status;
          print("READ_MEDIA_IMAGES status: $mediaImages");
          
          if (mediaImages.isDenied) {
            mediaImages = await Permission.photos.request();
            print("After request READ_MEDIA_IMAGES status: $mediaImages");
          }
          
          if (mediaImages.isPermanentlyDenied) {
            _showOpenSettingsDialog("دسترسی به تصاویر به صورت دائمی رد شده است. لطفا از طریق تنظیمات دستگاه این دسترسی را فعال کنید.");
            return false;
          }
          
          return mediaImages.isGranted;
        } else { // Android 12-
          print("درخواست دسترسی storage برای Android 12 و پایین‌تر");
          PermissionStatus storage = await Permission.storage.status;
          print("STORAGE status: $storage");
          
          if (storage.isDenied) {
            storage = await Permission.storage.request();
            print("After request STORAGE status: $storage");
          }
          
          if (storage.isPermanentlyDenied) {
            _showOpenSettingsDialog("دسترسی به حافظه به صورت دائمی رد شده است. لطفا از طریق تنظیمات دستگاه این دسترسی را فعال کنید.");
            return false;
          }
          
          // On older Android versions, we need both READ and WRITE permissions
          if (!storage.isGranted) {
            print("دسترسی storage داده نشد");
            return false;
          }
          
          return true;
        }
      } else if (Platform.isIOS) {
        // For iOS, we need photos permission
        PermissionStatus photos = await Permission.photos.status;
        
        if (photos.isDenied) {
          photos = await Permission.photos.request();
        }
        
        if (photos.isPermanentlyDenied) {
          _showOpenSettingsDialog("دسترسی به تصاویر به صورت دائمی رد شده است. لطفا از طریق تنظیمات دستگاه این دسترسی را فعال کنید.");
          return false;
        }
        
        return photos.isGranted;
      }
      
      // If platform is neither Android nor iOS, assume permissions are granted
      return true;
    }
  }
  
  // Get Android version
  Future<int> _getAndroidVersion() async {
    try {
      if (!Platform.isAndroid) return 0;
      
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      
      print("Android SDK: ${androidInfo.version.sdkInt}");
      return androidInfo.version.sdkInt;
    } catch (e) {
      print("خطا در تعیین نسخه اندروید: $e");
      return 29; // Default to Android 10
    }
  }
  
  // Show dialog to open settings
  void _showOpenSettingsDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نیاز به دسترسی'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 16),
                const Text('برای فعال کردن دسترسی‌ها، باید به تنظیمات برنامه بروید.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('بعداً'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('رفتن به تنظیمات'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Upload an image to the test endpoint for debugging
  Future<void> _testImageUpload() async {
    try {
      print("\n\n--- شروع تست آپلود تصویر ---");
      
      if (Platform.isAndroid) {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        print("اندروید: ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})");
      }
      
      // Pick an image first
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        print("هیچ تصویری انتخاب نشد");
        return;
      }
      
      print("تصویر با موفقیت انتخاب شد: ${pickedFile.path}");
      
      // Create a test multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppLinks.baseUrl}/test_upload.php'),
      );
      
      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', 
          pickedFile.path,
          filename: 'test_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      // Add a test field
      request.fields['test_field'] = 'این یک تست است';
      
      print("درخواست آماده شد، در حال ارسال به سرور...");
      
      // Send the request with a longer timeout
      final response = await request.send().timeout(const Duration(seconds: 60));
      
      print("پاسخ دریافت شد با کد وضعیت: ${response.statusCode}");
      
      // Get the response body
      final responseString = await response.stream.bytesToString();
      print("پاسخ: $responseString");
      
      // Show the response to the user
      if (!mounted) return;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تست آپلود با موفقیت انجام شد. جزئیات در کنسول'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در تست آپلود: ${response.statusCode}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
    } catch (e) {
      print("\n⚠️ خطا در تست آپلود: $e");
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در تست آپلود: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Method to pick image from gallery or camera
  Future<void> _pickImage(ImageSource source, int imageType) async {
    try {
      print("شروع انتخاب تصویر از منبع: ${source == ImageSource.gallery ? 'گالری' : 'دوربین'}");
      
      // First request permissions
      final bool hasPermission = await _requestPermissions(source);
      
      if (!hasPermission) {
        print("دسترسی مورد نیاز وجود ندارد");
        return;
      }
      
      print("دسترسی‌ها تایید شد، در حال باز کردن ${source == ImageSource.gallery ? 'گالری' : 'دوربین'}...");
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        print("تصویر با موفقیت انتخاب شد: ${pickedFile.path}");
        setState(() {
          switch (imageType) {
            case 1: 
              _nationalIdCardImagePath = pickedFile.path;
              _isNationalIdCardImageChanged = true;
              break;
            case 2:
              _driverLicenseImagePath = pickedFile.path;
              _isDriverLicenseImageChanged = true;
              break;
            case 3:
              _driverSmartCardImagePath = pickedFile.path;
              _isDriverSmartCardImageChanged = true;
              break;
          }
        });
      } else {
        // User cancelled the picker
        print('کاربر انتخاب تصویر را لغو کرد');
      }
    } catch (e) {
      print('خطای دقیق در انتخاب تصویر: $e');
      
      String errorMessage = 'خطا در انتخاب تصویر';
      bool showSettingsOption = false;
      
      // More specific error messages based on common errors
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        errorMessage = 'دسترسی به گالری یا دوربین رد شده است';
        showSettingsOption = true;
      } else if (e.toString().contains('camera')) {
        errorMessage = 'خطا در دسترسی به دوربین';
      } else if (e.toString().contains('photo') || e.toString().contains('gallery')) {
        errorMessage = 'خطا در دسترسی به گالری';
        showSettingsOption = true;
      }
      
      if (mounted) {
        // Show a dialog instead of snackbar for more visibility
        if (showSettingsOption) {
          _showPermissionDeniedDialog(errorMessage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'متوجه شدم',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    }
  }
  
  // Show a dialog to guide user to enable permissions
  void _showPermissionDeniedDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('نیاز به دسترسی'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const SizedBox(height: 16),
                const Text(
                  'برای انتخاب تصویر، لطفا به برنامه دسترسی به گالری و دوربین را بدهید:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('۱. به تنظیمات دستگاه بروید'),
                const Text('۲. بخش "برنامه‌ها" یا "Apps" را انتخاب کنید'),
                const Text('۳. برنامه خاتون‌بار را پیدا کنید'),
                const Text('۴. بخش "دسترسی‌ها" یا "Permissions" را انتخاب کنید'),
                const Text('۵. دسترسی به گالری و دوربین را فعال کنید'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('متوجه شدم'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Method to show image source selection dialog
  Future<void> _showImageSourceDialog(int imageType) async {
    String title = '';
    switch (imageType) {
      case 1:
        title = 'انتخاب تصویر کارت ملی';
        break;
      case 2:
        title = 'انتخاب تصویر گواهینامه';
        break;
      case 3:
        title = 'انتخاب تصویر کارت هوشمند';
        break;
    }
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('انتخاب از گالری'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.gallery, imageType);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('عکس گرفتن با دوربین'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.camera, imageType);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('انصراف'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Widget to display image selection button
  Widget _buildImageSelectionButton(String label, int imageType, String? currentImagePath, String? currentImageUrl) {
    final bool isLocalFile = currentImagePath != null;
    final bool hasImage = isLocalFile || currentImageUrl != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: isLocalFile 
                      ? Image.file(
                          File(currentImagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Image.network(
                          currentImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 40, color: Colors.grey.shade600),
                                  const SizedBox(height: 4),
                                  Text(
                                    'خطا در بارگیری تصویر',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 40, color: Colors.grey.shade600),
                        const SizedBox(height: 4),
                        Text(
                          'تصویری انتخاب نشده',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showImageSourceDialog(imageType),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateDriver() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Step 1: Upload images if any have changed
        bool hasChangedImages = _isNationalIdCardImageChanged || 
                               _isDriverLicenseImageChanged || 
                               _isDriverSmartCardImageChanged;
        
        bool uploadSuccess = true;
        if (hasChangedImages) {
          uploadSuccess = await _uploadAllImages();
          if (!uploadSuccess) {
            throw Exception('Failed to upload one or more images');
          }
        }

        // Step 2: Send driver data with uploaded image URLs
        final driverData = <String, dynamic>{
          'id': widget.driver.id,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone_number': _phoneNumberController.text.trim().isNotEmpty
              ? _phoneNumberController.text.trim()
              : null,
          'salary_percentage': _salaryPercentageController.text.trim().isNotEmpty
              ? double.parse(_salaryPercentageController.text.trim())
              : null,
          'national_id': _nationalIdController.text.trim().isNotEmpty
              ? _nationalIdController.text.trim()
              : null,
          'national_id_card_image': _nationalIdCardImageUrl,
          'driver_license_image': _driverLicenseImageUrl,
          'driver_smart_card_image': _driverSmartCardImageUrl,
          // Note: Password is not included in edit form to avoid changing it unintentionally
        };
        
        // Debug print driver data
        print('\n======= راننده ویرایش شد =======');
        print('شناسه: ${widget.driver.id}');
        driverData.forEach((key, value) {
          print('$key: $value');
        });
        print('============================\n');
        
        final jsonBody = jsonEncode(driverData);
        
        // Print JSON body that will be sent to API
        print('\n======= JSON ارسالی به API =======');
        print(jsonBody);
        print('=================================\n');

        final response = await http.put(
          Uri.parse(AppLinks.updateDriverById(widget.driver.id)),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonBody,
        ).timeout(const Duration(seconds: 10));

        // Debug print API response
        print('\n======= پاسخ API =======');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('========================\n');

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
          message = "راننده با موفقیت به‌روزرسانی شد.";
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
        } else if (e is FormatException) {
          errorMessage = "Invalid format. Please check your inputs.";
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
          title: const Text('ویرایش راننده'),
          actions: [
            // دکمه تست آپلود برای رفع اشکال
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'تست آپلود تصویر',
              onPressed: _testImageUpload,
            ),
          ],
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
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _salaryPercentageController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      labelText: 'درصد حقوق (اختیاری)',
                      prefixIcon: Icon(Icons.percent),
                      hintText: 'مثال: 10.5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        try {
                          double percentage = double.parse(value);
                          if (percentage < 0 || percentage > 100) {
                            return 'درصد باید بین 0 تا 100 باشد';
                          }
                        } catch (e) {
                          return 'لطفا یک عدد معتبر وارد کنید';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _nationalIdController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      labelText: 'کد ملی (اختیاری)',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24.0),
                  const Text(
                    'اسناد و تصاویر مدارک',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _buildImageSelectionButton('تصویر کارت ملی (اختیاری)', 1, _nationalIdCardImagePath, _nationalIdCardImageUrl),
                  const SizedBox(height: 16.0),
                  _buildImageSelectionButton('تصویر گواهینامه رانندگی (اختیاری)', 2, _driverLicenseImagePath, _driverLicenseImageUrl),
                  const SizedBox(height: 16.0),
                  _buildImageSelectionButton('تصویر کارت هوشمند (اختیاری)', 3, _driverSmartCardImagePath, _driverSmartCardImageUrl),
                  const SizedBox(height: 32.0),
                  _isLoading || _isUploadingImages
                      ? Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              Text(
                                _isUploadingImages 
                                    ? 'در حال آپلود تصاویر...' 
                                    : 'در حال ثبت اطلاعات...',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: AppButtons.primaryButton(
                                onPressed: _updateDriver,
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
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 