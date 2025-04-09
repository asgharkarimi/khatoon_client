import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/customer.dart';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'customer_form.dart';
import 'customer_edit_form.dart';

class CustomerListScreen extends StatefulWidget {
  static const routeName = '/customers';
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse(AppLinks.customers))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> customersJson = jsonDecode(response.body);
        setState(() {
          _customers = customersJson
              .map((json) => Customer.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load customers. Status: ${response.statusCode}';
          _isLoading = false;
        });
        print('Failed to load customers: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Exception when loading customers: $e');
    }
  }

  Future<void> _deleteCustomer(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${AppLinks.customers}?id=$id'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Remove the customer from the list
        setState(() {
          _customers.removeWhere((customer) => customer.id == id);
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مشتری با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف مشتری: ${response.statusCode}'),
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

  void _navigateToAddCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomerAddForm()),
    );
    
    // Refresh the list when returning from the add screen
    if (result == true || result == null) {
      _fetchCustomers();
    }
  }

  void _editCustomer(Customer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerEditForm(customer: customer),
      ),
    );
    
    // Refresh the list when returning from the edit screen with a true result
    if (result == true) {
      _fetchCustomers();
    }
  }

  Future<void> _confirmDeleteCustomer(Customer customer) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تایید حذف'),
            content: Text('آیا از حذف "${customer.fullName}" اطمینان دارید؟'),
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
                  _deleteCustomer(customer.id);
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
          title: const Text('لیست مشتریان'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchCustomers,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: _navigateToAddCustomer,
          icon: Icons.add,
          label: 'افزودن مشتری',
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
              onPressed: _fetchCustomers,
              icon: Icons.refresh,
              label: 'تلاش مجدد',
            ),
          ],
        ),
      );
    }

    if (_customers.isEmpty) {
      return const Center(
        child: Text(
          'هیچ مشتری‌ای یافت نشد',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: _customers.length,
      itemBuilder: (context, index) {
        final customer = _customers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(customer.fullName),
            subtitle: customer.phoneNumber != null
                ? Text(customer.phoneNumber!)
                : const Text('شماره تلفن ثبت نشده', style: TextStyle(fontStyle: FontStyle.italic)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editCustomer(customer),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteCustomer(customer),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 