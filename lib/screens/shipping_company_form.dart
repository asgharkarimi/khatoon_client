import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_links.dart';
import '../models/shipping_company.dart';
import '../widgets/app_buttons.dart';

class ShippingCompanyForm extends StatefulWidget {
  final ShippingCompany? company;

  const ShippingCompanyForm({super.key, this.company});

  @override
  State<ShippingCompanyForm> createState() => _ShippingCompanyFormState();
}

class _ShippingCompanyFormState extends State<ShippingCompanyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.company!.name;
      if (widget.company!.phoneNumber != null) {
        _phoneNumberController.text = widget.company!.phoneNumber!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = {
        'name': _nameController.text,
        'phone_number': _phoneNumberController.text.isEmpty ? null : _phoneNumberController.text,
      };

      final response = _isEditing
          ? await http.put(
              Uri.parse(AppLinks.updateShippingCompanyById(widget.company!.id)),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(data),
            )
          : await http.post(
              Uri.parse(AppLinks.shippingCompanies),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(data),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'شرکت حمل و نقل با موفقیت ویرایش شد'
                : 'شرکت حمل و نقل با موفقیت افزوده شد'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'خطا در ثبت اطلاعات';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش شرکت حمل و نقل' : 'افزودن شرکت حمل و نقل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'نام شرکت',
                  border: OutlineInputBorder(),
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً نام شرکت را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'شماره تماس (اختیاری)',
                  border: OutlineInputBorder(),
                ),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButtons.primaryButton(
                  onPressed: _isLoading ? () {} : _submitForm,
                  icon: Icons.save,
                  label: 'ثبت شرکت حمل و نقل',
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 