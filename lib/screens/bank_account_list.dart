import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import '../models/bank_account.dart';
import '../app_links.dart';
import '../widgets/app_buttons.dart';
import 'bank_account_form.dart';
import 'bank_account_edit_form.dart';

class BankAccountListScreen extends StatefulWidget {
  const BankAccountListScreen({super.key});

  @override
  State<BankAccountListScreen> createState() => _BankAccountListScreenState();
}

class _BankAccountListScreenState extends State<BankAccountListScreen> {
  List<BankAccount> _bankAccounts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  Future<void> _fetchBankAccounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse(AppLinks.bankAccounts))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> bankAccountsJson = jsonDecode(response.body);
        setState(() {
          _bankAccounts = bankAccountsJson
              .map((json) => BankAccount.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load bank accounts. Status: ${response.statusCode}';
          _isLoading = false;
        });
        print('Failed to load bank accounts: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      print('Exception when loading bank accounts: $e');
    }
  }

  Future<void> _deleteBankAccount(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse(AppLinks.deleteBankAccountById(id)),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Remove the bank account from the list
        setState(() {
          _bankAccounts.removeWhere((bankAccount) => bankAccount.id == id);
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حساب بانکی با موفقیت حذف شد'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف حساب بانکی: ${response.statusCode}'),
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

  void _navigateToAddBankAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BankAccountAddForm()),
    );
    
    // Refresh the list when returning from the add screen
    if (result == true || result == null) {
      _fetchBankAccounts();
    }
  }

  void _editBankAccount(BankAccount bankAccount) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BankAccountEditForm(bankAccount: bankAccount),
      ),
    );
    
    // Refresh the list when returning from the edit screen with a true result
    if (result == true) {
      _fetchBankAccounts();
    }
  }

  Future<void> _confirmDeleteBankAccount(BankAccount bankAccount) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تایید حذف'),
            content: Text('آیا از حذف حساب بانکی "${bankAccount.bankName} - ${bankAccount.accountHolderName}" اطمینان دارید؟'),
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
                  _deleteBankAccount(bankAccount.id);
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
          title: const Text('لیست حساب‌های بانکی'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchBankAccounts,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AppButtons.extendedFloatingActionButton(
          onPressed: _navigateToAddBankAccount,
          icon: Icons.add,
          label: 'افزودن حساب بانکی',
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
              onPressed: _fetchBankAccounts,
              icon: Icons.refresh,
              label: 'تلاش مجدد',
            ),
          ],
        ),
      );
    }

    if (_bankAccounts.isEmpty) {
      return const Center(
        child: Text(
          'هیچ حساب بانکی‌ای یافت نشد',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: _bankAccounts.length,
      itemBuilder: (context, index) {
        final bankAccount = _bankAccounts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text(
              '${bankAccount.bankName} - ${bankAccount.accountHolderName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: bankAccount.iban != null
                ? Text(bankAccount.iban!)
                : const Text('بدون شماره شبا', style: TextStyle(fontStyle: FontStyle.italic)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bankAccount.cardNumber != null)
                      ListTile(
                        leading: const Icon(Icons.credit_card),
                        title: const Text('شماره کارت'),
                        subtitle: Text(bankAccount.cardNumber!),
                        dense: true,
                      ),
                    if (bankAccount.iban != null)
                      ListTile(
                        leading: const Icon(Icons.account_balance_wallet),
                        title: const Text('شماره شبا (IBAN)'),
                        subtitle: Text(bankAccount.iban!),
                        dense: true,
                      ),
                    ButtonBar(
                      alignment: MainAxisAlignment.center,
                      children: [
                        AppButtons.primaryButton(
                          onPressed: () => _editBankAccount(bankAccount),
                          icon: Icons.edit,
                          label: 'ویرایش',
                        ),
                        AppButtons.dangerButton(
                          onPressed: () => _confirmDeleteBankAccount(bankAccount),
                          icon: Icons.delete,
                          label: 'حذف',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 