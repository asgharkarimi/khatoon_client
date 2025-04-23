import 'package:flutter/material.dart';
import 'bank_account_list.dart';
import 'bank_account_form.dart';
import 'bank_account_edit_form.dart';
import 'cargo_list.dart';
import 'cargo_form.dart';
import 'cargo_edit_form.dart';
import 'cargo_details.dart';
import 'cargo_selling_company_list.dart';
import 'cargo_selling_company_form.dart';
import 'cargo_selling_company_edit_form.dart';
import 'cargo_type_list.dart';
import 'cargo_type_form.dart';
import 'cargo_type_edit_form.dart';
import 'customer_list.dart';
import 'customer_form.dart';
import 'customer_edit_form.dart';
import 'driver_list.dart';
import 'driver_form.dart';
import 'driver_edit_form.dart';
import 'shipping_company_list.dart';
import 'shipping_company_form.dart';
import 'vehicle_list.dart';
import 'vehicle_form.dart';
import 'vehicle_edit_form.dart';
import 'login_screen.dart';
import 'payment_list.dart';
import 'payment_form.dart';
import 'expense_list.dart';
import 'expense_form.dart';
import 'driver_income_report.dart';
import 'dashboard.dart';
import '../common/app_theme.dart';

class AllScreensButtons extends StatelessWidget {
  static const routeName = '/all-screens';

  const AllScreensButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تمام صفحات', style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          )),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // داشبورد
                  _buildCategoryHeader('داشبورد', Icons.dashboard),
                  _buildScreenButton(context, 'داشبورد اصلی', Icons.dashboard, Dashboard.routeName),
                  
                  const SizedBox(height: 16),
                  
                  // مدیریت بار
                  _buildCategoryHeader('مدیریت بار', Icons.local_shipping),
                  _buildScreenButton(context, 'لیست بارها', Icons.view_list, CargoListScreen.routeName),
                  _buildScreenButton(context, 'افزودن بار جدید', Icons.add_box, CargoForm.routeName),
                  _buildScreenButton(context, 'جزئیات بار', Icons.info, CargoDetailsScreen.routeName),
                  _buildScreenButton(context, 'انواع بار', Icons.category, CargoTypeListScreen.routeName),
                  _buildScreenButton(context, 'افزودن نوع بار', Icons.add_circle, CargoTypeForm.routeName),
                  
                  const SizedBox(height: 16),
                  
                  // مدیریت افراد
                  _buildCategoryHeader('مدیریت افراد', Icons.people),
                  _buildScreenButton(context, 'لیست رانندگان', Icons.person, DriverListScreen.routeName),
                  _buildScreenButton(context, 'افزودن راننده', Icons.person_add, DriverForm.routeName),
                  _buildScreenButton(context, 'لیست مشتریان', Icons.groups, CustomerListScreen.routeName),
                  _buildScreenButton(context, 'افزودن مشتری', Icons.person_add_alt_1, CustomerAddForm.routeName),
                  
                  const SizedBox(height: 16),
                  
                  // مدیریت شرکت‌ها
                  _buildCategoryHeader('مدیریت شرکت‌ها', Icons.business),
                  _buildScreenButton(context, 'لیست شرکت‌های فروش', Icons.store, CargoSellingCompanyListScreen.routeName),
                  _buildScreenButton(context, 'افزودن شرکت فروش', Icons.add_business, CargoSellingCompanyForm.routeName),
                  _buildScreenButton(context, 'لیست شرکت‌های حمل', Icons.local_shipping, ShippingCompanyListScreen.routeName),
                  _buildScreenButton(context, 'افزودن شرکت حمل', Icons.add_business, ShippingCompanyForm.routeName),
                  
                  const SizedBox(height: 16),
                  
                  // مدیریت وسایل نقلیه
                  _buildCategoryHeader('مدیریت وسایل نقلیه', Icons.directions_car),
                  _buildScreenButton(context, 'لیست خودروها', Icons.directions_car, VehicleListScreen.routeName),
                  _buildScreenButton(context, 'افزودن خودرو', Icons.add_circle, VehicleForm.routeName),
                  
                  const SizedBox(height: 16),
                  
                  // مدیریت مالی
                  _buildCategoryHeader('مدیریت مالی', Icons.account_balance),
                  _buildScreenButton(context, 'حساب‌های بانکی', Icons.account_balance, BankAccountListScreen.routeName),
                  _buildScreenButton(context, 'افزودن حساب بانکی', Icons.add_card, BankAccountForm.routeName),
                  _buildScreenButton(context, 'لیست پرداخت‌ها', Icons.payment, PaymentListScreen.routeName),
                  _buildScreenButton(context, 'ثبت پرداخت', Icons.payments, PaymentForm.routeName),
                  _buildScreenButton(context, 'لیست هزینه‌ها', Icons.receipt, ExpenseListScreen.routeName),
                  _buildScreenButton(context, 'ثبت هزینه', Icons.receipt_long, ExpenseForm.routeName),
                  _buildScreenButton(context, 'گزارش درآمد راننده', Icons.monetization_on, DriverIncomeReportScreen.routeName),
                  
                  const SizedBox(height: 16),
                  
                  // سایر
                  _buildCategoryHeader('سایر', Icons.more_horiz),
                  _buildScreenButton(context, 'ورود به سیستم', Icons.login, LoginScreen.routeName),
                
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenButton(BuildContext context, String title, IconData icon, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        onPressed: () {
          try {
            Navigator.pushNamed(context, route);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطا در باز کردن صفحه: $e')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          alignment: Alignment.centerRight,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
} 