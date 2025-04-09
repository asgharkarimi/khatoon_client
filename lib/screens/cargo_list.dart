import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../app_links.dart';
import '../models/cargo_model.dart';
import '../widgets/app_buttons.dart';
import 'cargo_form.dart';
import 'cargo_edit_form.dart';
import 'cargo_details.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class CargoListScreen extends StatefulWidget {
  static const routeName = '/cargos';

  const CargoListScreen({super.key});

  @override
  State<CargoListScreen> createState() => _CargoListScreenState();
}

class _CargoListScreenState extends State<CargoListScreen> {
  List<Cargo> _cargos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCargos();
  }

  // Format numbers with Persian thousands separator
  String _formatNumber(double value) {
    return NumberFormat('#,###', 'fa').format(value);
  }

  // Calculate cargo totals (in Toman)
  double _calculateTotalPrice(Cargo cargo) {
    return (cargo.weightTonnes * cargo.pricePerTonne) / 10;
  }
  
  double _calculateTotalTransportCost(Cargo cargo) {
    return (cargo.weightTonnes * cargo.transportCostPerTonne) / 10;
  }
  
  // Format per-ton price in Toman
  String _formatPricePerTon(double pricePerTonne) {
    return _formatNumber(pricePerTonne / 10);
  }

  Future<void> _fetchCargos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse(AppLinks.cargos));
      
      if (response.statusCode == 200) {
        final List<dynamic> cargoData = json.decode(response.body);
        
        setState(() {
          _cargos = cargoData.map((data) => Cargo.fromJson(data)).toList()
            ..sort((a, b) {
              // First compare by loading date
              if (a.loadingDate == null && b.loadingDate == null) {
                return (b.id ?? 0).compareTo(a.id ?? 0); // If both dates are null, sort by ID
              }
              if (a.loadingDate == null) return 1; // Nulls go last
              if (b.loadingDate == null) return -1;
              
              int dateComparison = b.loadingDate!.compareTo(a.loadingDate!);
              if (dateComparison != 0) return dateComparison;
              
              // If dates are equal, sort by ID in descending order
              return (b.id ?? 0).compareTo(a.id ?? 0);
            });
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'خطا در دریافت بارها: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطا: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCargo(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppLinks.cargos}?id=$id'),
      );

      if (response.statusCode == 200) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بار با موفقیت حذف شد')),
        );
        _fetchCargos(); // Refresh the list
      } else {
        // Error
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${errorData['message'] ?? 'خطا در حذف بار'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    }
  }

  void _confirmDelete(Cargo cargo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تایید حذف'),
        content: Text('آیا از حذف بار از ${cargo.origin} به ${cargo.destination} مطمئن هستید؟'),
        actions: [
          AppButtons.textButton(
            onPressed: () => Navigator.of(ctx).pop(),
            label: 'انصراف',
          ),
          AppButtons.dangerTextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteCargo(cargo.id!);
            },
            label: 'حذف',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت بارها'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchCargos,
                  child: _cargos.isEmpty
                      ? const Center(child: Text('هیچ باری یافت نشد'))
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ListView.builder(
                            itemCount: _cargos.length,
                            itemBuilder: (ctx, index) {
                              final cargo = _cargos[index];
                              
                              // Calculate totals
                              final totalPrice = _calculateTotalPrice(cargo);
                              final totalTransportCost = _calculateTotalTransportCost(cargo);
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => CargoDetailsScreen(cargo: cargo),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${cargo.origin} ------> ${cargo.destination}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit),
                                                      onPressed: () {
                                                        Navigator.of(context).push(
                                                          MaterialPageRoute(
                                                            builder: (context) => CargoEditForm(cargo: cargo),
                                                          ),
                                                        ).then((_) => _fetchCargos());
                                                      },
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete, color: Colors.red),
                                                      onPressed: () => _confirmDelete(cargo),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Text('مشتری:', style: TextStyle(color: Colors.black54)),
                                                const SizedBox(width: 8),
                                                Text(cargo.customerName ?? 'نامشخص'),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Text('راننده:', style: TextStyle(color: Colors.black54)),
                                                const SizedBox(width: 8),
                                                Text(cargo.driverName ?? 'نامشخص'),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Text('بارگیری:', style: TextStyle(color: Colors.black54)),
                                                const SizedBox(width: 8),
                                                Text(
                                                  cargo.loadingDate != null 
                                                    ? Jalali.fromDateTime(DateTime.parse(cargo.loadingDate!)).formatFullDate()
                                                    : 'نامشخص'
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Text('وزن:', style: TextStyle(color: Colors.black54)),
                                                const SizedBox(width: 8),
                                                Text('${_formatNumber(cargo.weightTonnes)} تن'),
                                              ],
                                            ),
                                            const Divider(height: 24),
                                            const Text(
                                              'خلاصه محاسبات',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('قیمت هر تن:', style: TextStyle(color: Colors.black87)),
                                                Text(
                                                  '${_formatNumber(cargo.pricePerTonne / 10)} تومان',
                                                  style: const TextStyle(fontFamily: 'Vazir'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('هزینه حمل هر تن:', style: TextStyle(color: Colors.black87)),
                                                Text(
                                                  '${_formatNumber(cargo.transportCostPerTonne / 10)} تومان',
                                                  style: const TextStyle(fontFamily: 'Vazir'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('هزینه کل حمل:', style: TextStyle(color: Colors.black87)),
                                                Text(
                                                  '${_formatNumber((cargo.weightTonnes * cargo.transportCostPerTonne) / 10)} تومان',
                                                  style: const TextStyle(fontFamily: 'Vazir'),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('مبلغ بارنامه:', style: TextStyle(color: Colors.black87)),
                                                Text(
                                                  '${_formatNumber((cargo.waybillAmount ?? 0) / 10)} تومان',
                                                  style: const TextStyle(fontFamily: 'Vazir'),
                                                ),
                                              ],
                                            ),
                                            if (cargo.driverIncome != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('درآمد راننده:', style: TextStyle(color: Colors.black87)),
                                                  Text(
                                                    '${_formatNumber((cargo.driverIncome ?? 0) / 10)} تومان',
                                                    style: TextStyle(
                                                      fontFamily: 'Vazir',
                                                      color: (cargo.driverIncome ?? 0) > 0 
                                                        ? Colors.green 
                                                        : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
      floatingActionButton: AppButtons.extendedFloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(CargoForm.routeName).then((_) => _fetchCargos());
        },
        icon: Icons.add,
        label: 'افزودن بار',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Helper method to format dates
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }
  
  // Helper method to get color based on payment status
  Color _getPaymentStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'paid':
      case 'پرداخت شده':
        return Colors.green;
      case 'partial':
      case 'پرداخت جزئی':
        return Colors.orange;
      case 'not received':
      case 'پرداخت نشده':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 