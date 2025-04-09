import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import '../models/shipping_company.dart';
import 'shipping_company_form.dart';

class ShippingCompanyListScreen extends StatefulWidget {
  static const routeName = '/shipping-companies';

  const ShippingCompanyListScreen({super.key});

  @override
  State<ShippingCompanyListScreen> createState() => _ShippingCompanyListScreenState();
}

class _ShippingCompanyListScreenState extends State<ShippingCompanyListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ShippingCompany> _shippingCompanies = [];

  @override
  void initState() {
    super.initState();
    _fetchShippingCompanies();
  }

  Future<void> _fetchShippingCompanies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(AppLinks.shippingCompanies));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _shippingCompanies = data.map((item) => ShippingCompany.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'خطا در دریافت اطلاعات شرکت‌های حمل و نقل';
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

  Future<void> _deleteShippingCompany(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تایید حذف'),
        content: const Text('آیا از حذف این شرکت حمل و نقل اطمینان دارید؟'),
        actions: [
          AppButtons.textButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'انصراف',
          ),
          AppButtons.dangerTextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteShippingCompany(id);
            },
            label: 'حذف',
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse(AppLinks.deleteShippingCompanyById(id)),
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شرکت حمل و نقل با موفقیت حذف شد')),
        );
        _fetchShippingCompanies();
      } else {
        final errorData = json.decode(response.body);
        setState(() {
          _errorMessage = errorData['message'] ?? 'خطا در حذف شرکت حمل و نقل';
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
        title: const Text('شرکت‌های حمل و نقل'),
      ),
      floatingActionButton: AppButtons.extendedFloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ShippingCompanyForm(),
            ),
          ).then((_) => _fetchShippingCompanies());
        },
        icon: Icons.add,
        label: 'افزودن شرکت حمل و نقل',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchShippingCompanies,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                )
              : _shippingCompanies.isEmpty
                  ? const Center(child: Text('هیچ شرکت حمل و نقلی یافت نشد'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _shippingCompanies.length,
                      itemBuilder: (context, index) {
                        final company = _shippingCompanies[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(company.name),
                            subtitle: company.phoneNumber != null 
                              ? Text('شماره تماس: ${company.phoneNumber}')
                              : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ShippingCompanyForm(company: company),
                                      ),
                                    ).then((_) => _fetchShippingCompanies());
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteShippingCompany(company.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 