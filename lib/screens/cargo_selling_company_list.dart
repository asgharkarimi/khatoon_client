import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/cargo_selling_company.dart';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'cargo_selling_company_form.dart';
import 'cargo_selling_company_edit_form.dart';

class CargoSellingCompanyListScreen extends StatefulWidget {
  const CargoSellingCompanyListScreen({super.key});

  @override
  State<CargoSellingCompanyListScreen> createState() => _CargoSellingCompanyListScreenState();
}

class _CargoSellingCompanyListScreenState extends State<CargoSellingCompanyListScreen> {
  List<CargoSellingCompany> _companies = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse(AppLinks.cargoSellingCompanies))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> companiesJson = jsonDecode(response.body);
        setState(() {
          _companies = companiesJson
              .map((json) => CargoSellingCompany.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load companies. Status: ${response.statusCode}';
          _isLoading = false;
        });
        print('Failed to load companies: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Exception when loading companies: $e');
    }
  }

  Future<void> _deleteCompany(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse(AppLinks.deleteCargoSellingCompanyById(id)),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Remove the company from the list
        setState(() {
          _companies.removeWhere((company) => company.id == id);
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('شرکت فروشنده بار با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف شرکت: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToAddCompany() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CargoSellingCompanyForm()),
    );
    
    // Refresh the list when returning from the add screen
    if (result == true || result == null) {
      _fetchCompanies();
    }
  }

  void _editCompany(CargoSellingCompany company) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CargoSellingCompanyEditForm(company: company),
      ),
    );
    
    // Refresh the list when returning from the edit screen with a true result
    if (result == true) {
      _fetchCompanies();
    }
  }

  Future<void> _confirmDeleteCompany(CargoSellingCompany company) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تایید حذف'),
            content: Text('آیا از حذف "${company.name}" اطمینان دارید؟'),
            actions: <Widget>[
              AppButtons.textButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                label: 'انصراف',
              ),
              AppButtons.dangerTextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteCompany(company.id);
                },
                label: 'حذف',
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لیست شرکت‌های فروشنده بار'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchCompanies,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: _navigateToAddCompany,
          icon: Icons.add,
          label: 'افزودن شرکت',
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppButtons.primaryButton(
              onPressed: _fetchCompanies,
              icon: Icons.refresh,
              label: 'تلاش مجدد',
            ),
          ],
        ),
      );
    }

    if (_companies.isEmpty) {
      return const Center(
        child: Text(
          'هیچ شرکتی یافت نشد',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCompanies,
      child: ListView.builder(
        itemCount: _companies.length,
        itemBuilder: (context, index) {
          final company = _companies[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(company.name),
              subtitle: company.phoneNumber != null
                  ? Text(company.phoneNumber!)
                  : const Text('شماره تلفن ثبت نشده', style: TextStyle(fontStyle: FontStyle.italic)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editCompany(company),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteCompany(company),
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