import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/driver.dart';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'driver_form.dart';
import 'driver_edit_form.dart';

class DriverListScreen extends StatefulWidget {
  static const routeName = '/drivers';
  const DriverListScreen({super.key});

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  List<Driver> _drivers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse(AppLinks.drivers))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> driversJson = jsonDecode(response.body);
        setState(() {
          _drivers = driversJson
              .map((json) => Driver.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load drivers. Status: ${response.statusCode}';
          _isLoading = false;
        });
        print('Failed to load drivers: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Exception when loading drivers: $e');
    }
  }

  Future<void> _deleteDriver(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse(AppLinks.deleteDriverById(id)),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Remove the driver from the list
        setState(() {
          _drivers.removeWhere((driver) => driver.id == id);
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('راننده با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف راننده: ${response.statusCode}'),
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

  void _navigateToAddDriver() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DriverForm()),
    );
    
    // Refresh the list when returning from the add screen
    if (result == true || result == null) {
      _fetchDrivers();
    }
  }

  void _editDriver(Driver driver) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverEditForm(driver: driver),
      ),
    );
    
    // Refresh the list when returning from the edit screen with a true result
    if (result == true) {
      _fetchDrivers();
    }
  }

  Future<void> _confirmDeleteDriver(Driver driver) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تایید حذف'),
            content: Text('آیا از حذف "${driver.fullName}" اطمینان دارید؟'),
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
                  _deleteDriver(driver.id);
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
          title: const Text('لیست رانندگان'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchDrivers,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: _navigateToAddDriver,
          icon: Icons.add,
          label: 'افزودن راننده',
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
              onPressed: _fetchDrivers,
              icon: Icons.refresh,
              label: 'تلاش مجدد',
            ),
          ],
        ),
      );
    }

    if (_drivers.isEmpty) {
      return const Center(
        child: Text(
          'هیچ راننده‌ای یافت نشد',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDrivers,
      child: ListView.builder(
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(driver.fullName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (driver.phoneNumber != null)
                    Text('شماره تلفن: ${driver.phoneNumber}'),
                  if (driver.salaryPercentage != null)
                    Text('درصد حقوق: ${driver.salaryPercentage}%'),
                  if (driver.nationalId != null)
                    Text('کد ملی: ${driver.nationalId}'),
                ],
              ),
              isThreeLine: driver.phoneNumber != null || driver.salaryPercentage != null || driver.nationalId != null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editDriver(driver),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteDriver(driver),
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