import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/cargo_type.dart';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'cargo_type_form.dart';
import 'cargo_type_edit_form.dart';

class CargoTypeListScreen extends StatefulWidget {
  const CargoTypeListScreen({super.key});

  @override
  State<CargoTypeListScreen> createState() => _CargoTypeListScreenState();
}

class _CargoTypeListScreenState extends State<CargoTypeListScreen> {
  List<CargoType> _cargoTypes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCargoTypes();
  }

  Future<void> _fetchCargoTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse(AppLinks.cargoTypes))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> typesJson = jsonDecode(response.body);
        setState(() {
          _cargoTypes = typesJson
              .map((json) => CargoType.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load cargo types. Status: ${response.statusCode}';
          _isLoading = false;
        });
        print('Failed to load cargo types: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Exception when loading cargo types: $e');
    }
  }

  Future<void> _deleteCargoType(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse(AppLinks.deleteCargoTypeById(id)),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Remove the cargo type from the list
        setState(() {
          _cargoTypes.removeWhere((type) => type.id == id);
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('نوع بار با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف نوع بار: ${response.statusCode}'),
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

  void _navigateToAddCargoType() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CargoTypeForm()),
    );
    
    // Refresh the list when returning from the add screen
    if (result == true || result == null) {
      _fetchCargoTypes();
    }
  }

  void _editCargoType(CargoType cargoType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CargoTypeEditForm(cargoType: cargoType),
      ),
    );
    
    // Refresh the list when returning from the edit screen with a true result
    if (result == true) {
      _fetchCargoTypes();
    }
  }

  Future<void> _confirmDeleteCargoType(CargoType cargoType) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تایید حذف'),
            content: Text('آیا از حذف "${cargoType.name}" اطمینان دارید؟'),
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
                  _deleteCargoType(cargoType.id);
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
          title: const Text('لیست انواع بار'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchCargoTypes,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: _navigateToAddCargoType,
          icon: Icons.add,
          label: 'افزودن نوع بار',
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
              onPressed: _fetchCargoTypes,
              icon: Icons.refresh,
              label: 'تلاش مجدد',
            ),
          ],
        ),
      );
    }

    if (_cargoTypes.isEmpty) {
      return const Center(
        child: Text(
          'هیچ نوع باری یافت نشد',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchCargoTypes,
      child: ListView.builder(
        itemCount: _cargoTypes.length,
        itemBuilder: (context, index) {
          final cargoType = _cargoTypes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(cargoType.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editCargoType(cargoType),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteCargoType(cargoType),
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