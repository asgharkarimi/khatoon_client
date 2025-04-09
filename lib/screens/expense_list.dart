import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'expense_form.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'dart:ui' as ui;

class ExpenseListScreen extends StatefulWidget {
  static const routeName = '/expenses';

  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  // Format numbers with Persian thousands separator
  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    // Convert to double if it's a string
    double numValue = (value is String) ? double.parse(value) : value.toDouble();
    return NumberFormat('#,###', 'fa').format(numValue);
  }

  Future<void> _fetchExpenses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse(AppLinks.expenses));
      
      if (response.statusCode == 200) {
        final List<dynamic> expenseData = json.decode(response.body);
        
        setState(() {
          _expenses = expenseData.map((data) => {
            'id': data['id'],
            'amount': data['amount'],
            'description': data['description'] ?? '',
            'expense_type': data['expense_type'] ?? '',
            'expense_date': data['expense_date'],
            'receipt_image': data['receipt_image'],
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'خطا در دریافت هزینه‌ها: ${response.statusCode}';
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

  Future<void> _deleteExpense(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppLinks.expenses}?id=$id'),
      );

      if (response.statusCode == 200) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هزینه با موفقیت حذف شد')),
        );
        _fetchExpenses(); // Refresh the list
      } else {
        // Error
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: ${errorData['message'] ?? 'خطا در حذف هزینه'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تایید حذف'),
        content: Text('آیا از حذف هزینه ${expense['description']} به مبلغ ${_formatNumber(expense['amount'])} تومان مطمئن هستید؟'),
        actions: [
          AppButtons.textButton(
            onPressed: () => Navigator.of(ctx).pop(),
            label: 'انصراف',
          ),
          AppButtons.dangerTextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteExpense(expense['id']);
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
          title: const Text('مدیریت هزینه‌ها'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : RefreshIndicator(
                    onRefresh: _fetchExpenses,
                    child: _expenses.isEmpty
                        ? const Center(child: Text('هیچ هزینه‌ای یافت نشد'))
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: ListView.builder(
                              itemCount: _expenses.length,
                              itemBuilder: (ctx, index) {
                                final expense = _expenses[index];
                                
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
                                            expense['description'] ?? '',
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
                                                    '${_formatNumber(expense['amount'])} تومان',
                                                    style: const TextStyle(fontFamily: 'Vazir'),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('نوع هزینه:'),
                                                  Expanded(
                                                    child: Text(
                                                      expense['expense_type'] ?? '',
                                                      textAlign: TextAlign.left,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('تاریخ:'),
                                                  Expanded(
                                                    child: Text(
                                                      expense['expense_date'] != null 
                                                        ? Jalali.fromDateTime(DateTime.parse(expense['expense_date'])).formatFullDate()
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
                                            onPressed: () => _confirmDelete(expense),
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
                  ),
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed(ExpenseForm.routeName).then((_) => _fetchExpenses());
          },
          icon: Icons.add,
          label: 'افزودن هزینه',
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
} 