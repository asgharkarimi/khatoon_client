import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../app_links.dart';
import '../widgets/app_buttons.dart';

class DriverForm extends StatefulWidget {
  static const routeName = '/driver-form';
  
  const DriverForm({super.key});

  @override
  State<DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends State<DriverForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _salaryPercentageController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isUploadingImages = false;
  String _errorMessage = '';
  
  // Image paths and uploaded URLs
  String? _nationalIdCardImagePath;
  String? _driverLicenseImagePath;
  String? _driverSmartCardImagePath;
  
  // Server image URLs after upload
  String? _nationalIdCardImageUrl;
  String? _driverLicenseImageUrl;
  String? _driverSmartCardImageUrl;
  
  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _salaryPercentageController.dispose();
    _nationalIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Upload an image to the server
  Future<String?> _uploadImage(String imagePath, String imageType) async {
    try {
      print('Starting image upload for type: $imageType');
      print('Image path: $imagePath');
      
      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppLinks.uploadImage),
      );
      
      print('Upload URL: ${AppLinks.uploadImage}');
      
      // Get file extension
      final fileExtension = imagePath.split('.').last;
      
      // Create new filename with prefix and timestamp
      final newFilename = 'khatoonbar_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      // Add the image file to the request with new filename
      final file = await http.MultipartFile.fromPath(
        'image', 
        imagePath,
        filename: newFilename,
      );
      request.files.add(file);
      print('Added file to request: ${file.filename}');
      
      // Add image type as additional field
      request.fields['image_type'] = imageType;
      print('Added image_type field: $imageType');
      
      // Send the request
      print('Sending request...');
      final response = await request.send().timeout(const Duration(seconds: 30));
      print('Response status code: ${response.statusCode}');
      
      // Check if upload was successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse the response
        final responseString = await response.stream.bytesToString();
        print('Raw response: $responseString');
        
        final responseData = jsonDecode(responseString);
        print('Parsed response data: $responseData');
        
        if (responseData['success'] == true && responseData['file_path'] != null) {
          print('Upload successful. File path: ${responseData['file_path']}');
          return responseData['file_path'];
        } else {
          print('Upload error: ${responseData['message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('Exception during upload: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
  
  // Upload all selected images
  Future<bool> _uploadAllImages() async {
    setState(() {
      _isUploadingImages = true;
    });
    
    try {
      // Upload national ID card image if selected
      if (_nationalIdCardImagePath != null) {
        _nationalIdCardImageUrl = await _uploadImage(_nationalIdCardImagePath!, 'national_id');
        if (_nationalIdCardImageUrl == null) {
          return false;
        }
      }
      
      // Upload driver's license image if selected
      if (_driverLicenseImagePath != null) {
        _driverLicenseImageUrl = await _uploadImage(_driverLicenseImagePath!, 'driver_license');
        if (_driverLicenseImageUrl == null) {
          return false;
        }
      }
      
      // Upload driver's smart card image if selected
      if (_driverSmartCardImagePath != null) {
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
              _nationalIdCardImageUrl = null; // Reset the URL when new image is selected
              break;
            case 2:
              _driverLicenseImagePath = pickedFile.path;
              _driverLicenseImageUrl = null; // Reset the URL when new image is selected
              break;
            case 3:
              _driverSmartCardImagePath = pickedFile.path;
              _driverSmartCardImageUrl = null; // Reset the URL when new image is selected
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
              AppButtons.textButton(
                onPressed: () => Navigator.of(context).pop(),
                label: 'انصراف',
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Widget to display image selection button
  Widget _buildImageSelectionButton(String label, int imageType, String? currentImagePath) {
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
              child: currentImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(currentImagePath),
                      fit: BoxFit.cover,
                      width: double.infinity,
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
            if (currentImagePath != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _removeImage(imageType),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _addDriver() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Step 1: Upload images if any are selected
        bool hasImages = _nationalIdCardImagePath != null || 
                         _driverLicenseImagePath != null || 
                         _driverSmartCardImagePath != null;
        
        bool uploadSuccess = true;
        if (hasImages) {
          uploadSuccess = await _uploadAllImages();
          if (!uploadSuccess) {
            throw Exception('Failed to upload one or more images');
          }
        }

        // Step 2: Send driver data with uploaded image URLs
        final driverData = <String, dynamic>{
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
          'password': _passwordController.text.trim(),
          'national_id_card_image': _nationalIdCardImageUrl,
          'driver_license_image': _driverLicenseImageUrl,
          'driver_smart_card_image': _driverSmartCardImageUrl,
        };
        
        // Debug print driver data
        print('\n======= راننده جدید ایجاد شد =======');
        driverData.forEach((key, value) {
          print('$key: $value');
        });
        print('============================\n');
        
        final jsonBody = jsonEncode(driverData);
        
        // Print JSON body that will be sent to API
        print('\n======= JSON ارسالی به API =======');
        print(jsonBody);
        print('=================================\n');

        final response = await http.post(
          Uri.parse(AppLinks.drivers),
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

        // Check if the response contains HTML error (PHP error)
        if (response.body.contains('<br />') || response.body.contains('<b>Fatal error</b>')) {
          // Extract error message from PHP error
          String errorMessage = 'خطا در ثبت اطلاعات راننده';
          
          if (response.body.contains('Duplicate entry') && response.body.contains('national_id')) {
            errorMessage = 'کد ملی تکراری است. لطفا از کد ملی دیگری استفاده کنید.';
          } else if (response.body.contains('Duplicate entry') && response.body.contains('phone_number')) {
            errorMessage = 'شماره تلفن تکراری است. لطفا از شماره تلفن دیگری استفاده کنید.';
          }
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red.shade700,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

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
        } else if (response.statusCode == 201) {
          message = "راننده با موفقیت ایجاد شد.";
        } else {
          message = "Received empty response (Code: ${response.statusCode})";
        }

        if (!mounted) return; // Check if widget is still in the tree

        if (response.body.isEmpty) {
          setState(() {
            _errorMessage = 'Empty response from server.';
            _isLoading = false;
          });
          return;
        }

        if (response.statusCode == 201) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green.shade700),
          );
          // Clear the form and navigate back
          _formKey.currentState?.reset();
          _firstNameController.clear();
          _lastNameController.clear();
          _phoneNumberController.clear();
          _salaryPercentageController.clear();
          _nationalIdController.clear();
          _passwordController.clear();
          setState(() {
            _nationalIdCardImagePath = null;
            _driverLicenseImagePath = null;
            _driverSmartCardImagePath = null;
            _nationalIdCardImageUrl = null;
            _driverLicenseImageUrl = null;
            _driverSmartCardImageUrl = null;
          });
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

  // Upload an image to the test endpoint for debugging
  Future<void> _testImageUpload() async {
    try {
      print("\n\n--- شروع تست آپلود تصویر ---");
      print("دستگاه: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}");
      
      if (Platform.isAndroid) {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        print("اندروید: ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})");
        print("دستگاه: ${androidInfo.manufacturer} ${androidInfo.model}");
      }
      
      // First request permissions
      print("\nبررسی دسترسی‌ها...");
      final bool hasPermission = await _requestPermissions(ImageSource.gallery);
      
      if (!hasPermission) {
        print("\nخطا: دسترسی به گالری وجود ندارد");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('دسترسی به گالری وجود ندارد. لطفا از بخش تنظیمات دسترسی‌ها را فعال کنید.'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
      
      print("\nدر حال باز کردن انتخابگر تصویر...");
      // Pick an image first
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        print("\nخطا: هیچ تصویری انتخاب نشد");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('هیچ تصویری انتخاب نشد'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      print("\nتصویر با موفقیت انتخاب شد!");
      print("مسیر: ${pickedFile.path}");
      print("نام: ${pickedFile.name}");
      
      // Create a test multipart request
      print("\nدر حال آماده‌سازی درخواست آپلود...");
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppLinks.baseUrl}/api/test_upload.php'),
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
      
      print("\nدرخواست آماده شد، در حال ارسال به سرور...");
      
      // Send the request with a longer timeout
      final response = await request.send().timeout(const Duration(seconds: 60));
      
      print("\nپاسخ دریافت شد با کد وضعیت: ${response.statusCode}");
      
      // Get the response body
      final responseString = await response.stream.bytesToString();
      print("پاسخ: $responseString");
      
      // Show the response to the user
      if (!mounted) return;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تست آپلود با موفقیت انجام شد 👍'),
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
      String errorMessage = 'خطا در تست آپلود: $e';
      
      // Format the error message for some common errors
      if (e.toString().contains('permission')) {
        errorMessage = 'خطا: دسترسی لازم برای انتخاب تصویر وجود ندارد';
      } else if (e.toString().contains('socket')) {
        errorMessage = 'خطا: اتصال به سرور برقرار نشد';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'خطا: پاسخی از سرور دریافت نشد (تایم اوت)';
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    
    print("--- پایان تست آپلود تصویر ---\n\n");
  }

  void _removeImage(int imageType) {
    setState(() {
      switch (imageType) {
        case 1:
          _nationalIdCardImagePath = null;
          _nationalIdCardImageUrl = null;
          break;
        case 2:
          _driverLicenseImagePath = null;
          _driverLicenseImageUrl = null;
          break;
        case 3:
          _driverSmartCardImagePath = null;
          _driverSmartCardImageUrl = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('افزودن راننده جدید'),
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
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      labelText: 'رمز عبور',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفا رمز عبور را وارد کنید';
                      }
                      if (value.length < 6) {
                        return 'رمز عبور باید حداقل 6 کاراکتر باشد';
                      }
                      return null;
                    },
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
                  _buildImageSelectionButton('تصویر کارت ملی (اختیاری)', 1, _nationalIdCardImagePath),
                  const SizedBox(height: 16.0),
                  _buildImageSelectionButton('تصویر گواهینامه رانندگی (اختیاری)', 2, _driverLicenseImagePath),
                  const SizedBox(height: 16.0),
                  _buildImageSelectionButton('تصویر کارت هوشمند (اختیاری)', 3, _driverSmartCardImagePath),
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
                      : AppButtons.primaryButton(
                          onPressed: _addDriver,
                          icon: Icons.save,
                          label: 'ثبت راننده',
                          isLoading: _isLoading,
                          isFullWidth: true,
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