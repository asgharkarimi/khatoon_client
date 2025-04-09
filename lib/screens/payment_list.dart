import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'payment_form.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:ui' as ui;

class PaymentListScreen extends StatefulWidget {
  static const routeName = '/payments';

  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  // Format numbers with Persian thousands separator
  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    // Convert to double if it's a string
    double numValue = (value is String) ? double.parse(value) : value.toDouble();
    return NumberFormat('#,###', 'fa').format(numValue);
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse(AppLinks.payments));
      
      if (response.statusCode == 200) {
        final List<dynamic> paymentData = json.decode(response.body);
        
        setState(() {
          _payments = paymentData.map((data) => {
            'id': data['id'],
            'cargo_id': data['cargo_id'],
            'amount': data['amount'],
            'company_name': data['company_name'] ?? '',
            'bank_account': data['bank_account'] ?? '',
            'receipt_image': data['receipt_image'],
            'payment_date': data['payment_date'],
            'cargo_title': '${data['cargo_origin'] ?? ''} → ${data['cargo_destination'] ?? ''}',
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'خطا در دریافت پرداخت‌ها: ${response.statusCode}';
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

  Future<void> _deletePayment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppLinks.payments}?id=$id'),
      );

      if (response.statusCode == 200) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پرداخت با موفقیت حذف شد')),
        );
        _fetchPayments(); // Refresh the list
      } else {
        // Error
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${errorData['message'] ?? 'خطا در حذف پرداخت'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تایید حذف'),
        content: Text('آیا از حذف پرداخت مبلغ ${_formatNumber(payment['amount'])} تومان مطمئن هستید؟'),
        actions: [
          AppButtons.textButton(
            onPressed: () => Navigator.of(ctx).pop(),
            label: 'انصراف',
          ),
          AppButtons.dangerTextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deletePayment(payment['id']);
            },
            label: 'حذف',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت پرداخت‌ها'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : RefreshIndicator(
                    onRefresh: _fetchPayments,
                    child: _payments.isEmpty
                        ? const Center(child: Text('هیچ پرداختی یافت نشد'))
                        : ListView.builder(
                            itemCount: _payments.length,
                            itemBuilder: (ctx, index) {
                              final payment = _payments[index];
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          payment['cargo_title'],
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('مبلغ:', style: TextStyle(color: Colors.black87)),
                                                Text(
                                                  '${_formatNumber(payment['amount'])} تومان',
                                                  style: const TextStyle(fontFamily: 'Vazir'),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('شرکت:'),
                                                Expanded(
                                                  child: Text(
                                                    payment['company_name'] ?? '',
                                                    textAlign: TextAlign.left,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('حساب بانکی:'),
                                                Expanded(
                                                  child: Text(
                                                    payment['bank_account'] ?? '',
                                                    textAlign: TextAlign.left,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('تاریخ پرداخت:'),
                                                Expanded(
                                                  child: Text(
                                                    payment['payment_date'] != null 
                                                      ? Jalali.fromDateTime(DateTime.parse(payment['payment_date'])).formatFullDate()
                                                      : '',
                                                    textAlign: TextAlign.left,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmDelete(payment),
                                        ),
                                        isThreeLine: true,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed(PaymentForm.routeName).then((_) => _fetchPayments());
          },
          icon: Icons.add,
          label: 'افزودن پرداخت',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
} 