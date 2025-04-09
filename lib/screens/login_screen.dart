import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard.dart';
import '../common/enums.dart';
import '../widgets/app_buttons.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  void _login() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulate network request with a small delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _isLoading = false;
      });

      // Check for hardcoded credentials
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      // Check credentials and determine role
      UserRole? role;
      
      if (phone == '09199541276' && password == 'asghar') {
        // Admin user
        role = UserRole.admin;
      } else if (phone == '09195240866' && password == 'hossein') {
        // Driver user
        role = UserRole.driver;
      }

      if (role != null) {
        // Login successful - navigate to dashboard with role
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Dashboard(userRole: role!),
          ),
        );
      } else {
        // Show error
        setState(() {
          _errorMessage = 'شماره تلفن یا رمز عبور اشتباه است.';
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // RTL for Persian
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEDE7F6), Color(0xFFE8F5E9)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App logo
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_shipping_rounded,
                              size: 70,
                              color: Theme.of(context).colorScheme.primary,
                              shadows: [
                                Shadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // App name
                          Text(
                            'خاتون‌بار',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              shadows: [
                                Shadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Tagline
                          Text(
                            'سیستم مدیریت حمل و نقل',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 40),
                          
                          // Phone number field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              labelText: 'شماره موبایل',
                              prefixIcon: Icon(
                                Icons.phone_android,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              hintText: '09123456789',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً شماره موبایل خود را وارد کنید';
                              }
                              if (value.length != 11 || !value.startsWith('09')) {
                                return 'شماره موبایل باید 11 رقم و با 09 شروع شود';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'رمز عبور',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              hintText: '••••••••',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً رمز عبور خود را وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          
                          // Forgot Password Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AppButtons.textButton(
                              onPressed: () {
                                // Forgot password functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('برای بازیابی رمز عبور با پشتیبانی تماس بگیرید'),
                                  ),
                                );
                              },
                              label: 'فراموشی رمز عبور؟',
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Error message if login fails
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null) const SizedBox(height: 24),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: AppButtons.primaryButton(
                              onPressed: _isLoading ? () {} : _login,
                              icon: Icons.login,
                              label: 'ورود',
                              isLoading: _isLoading,
                              isFullWidth: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Version info
                          Text(
                            'نسخه 1.0.0',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 