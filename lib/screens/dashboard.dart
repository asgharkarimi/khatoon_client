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
import 'all_screens_buttons.dart';
import '../common/enums.dart';
import '../common/app_theme.dart';

// Helper class for screen information
class ScreenInfo {
  final String title;
  final IconData icon;
  final String route;
  
  ScreenInfo({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class Dashboard extends StatelessWidget {
  static const routeName = '/dashboard';
  
  final UserRole userRole;

  const Dashboard({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('داشبورد', style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          )),
          centerTitle: true,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Implement drawer or menu functionality
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // عملیات مالی
                  _buildSectionHeader(context, 'عملیات مالی', Icons.attach_money),
                  const SizedBox(height: 16),
                  
                  // عملیات مالی کارت‌ها
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          icon: Icons.money_rounded,
                          iconColor: AppTheme.primaryColor,
                          iconBgColor: Colors.purple.shade100,
                          title: 'ثبت حقوق راننده',
                          onTap: () => Navigator.pushNamed(context, DriverIncomeReportScreen.routeName),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          icon: Icons.receipt_long,
                          iconColor: Colors.teal,
                          iconBgColor: Colors.teal.shade100,
                          title: 'ثبت دریافتی',
                          onTap: () => Navigator.pushNamed(context, PaymentForm.routeName),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          icon: Icons.receipt,
                          iconColor: Colors.orange,
                          iconBgColor: Colors.orange.shade100,
                          title: 'ثبت هزینه',
                          onTap: () => Navigator.pushNamed(context, ExpenseForm.routeName),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          icon: Icons.credit_card,
                          iconColor: Colors.red,
                          iconBgColor: Colors.red.shade100,
                          title: 'ثبت رسید پرداختی',
                          onTap: () => Navigator.pushNamed(context, PaymentForm.routeName),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // عملیات بار
                  _buildSectionHeader(context, 'عملیات بار', Icons.local_shipping),
                  const SizedBox(height: 16),
                  
                  // عملیات بار کارت‌ها
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          icon: Icons.view_list,
                          iconColor: Colors.blue.shade700,
                          iconBgColor: Colors.blue.shade100,
                          title: 'مدیریت بارها',
                          onTap: () => Navigator.pushNamed(context, CargoListScreen.routeName),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          icon: Icons.add_box_rounded,
                          iconColor: Colors.indigo,
                          iconBgColor: Colors.indigo.shade100,
                          title: 'ثبت بار جدید',
                          onTap: () => Navigator.pushNamed(context, CargoForm.routeName),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // مدیریت مالی
                  _buildSectionHeader(context, 'مدیریت مالی', Icons.account_balance),
                  const SizedBox(height: 16),
                  
                  // مدیریت مالی کارت‌ها
                  Row(
                    children: [
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          icon: Icons.account_balance_wallet,
                          iconColor: AppTheme.primaryColor,
                          iconBgColor: Colors.purple.shade100,
                          title: 'مدیریت حساب‌ها',
                          onTap: () => Navigator.pushNamed(context, BankAccountListScreen.routeName),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCategoryCard(
                          context,
                          icon: Icons.bar_chart,
                          iconColor: Colors.teal,
                          iconBgColor: Colors.teal.shade100,
                          title: 'گزارش‌ها',
                          onTap: () {
                            // Navigate to reports
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // منوی دسترسی به همه صفحات
                  _buildSectionHeader(context, 'دسترسی سریع', Icons.menu),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AllScreensButtons.routeName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('دسترسی به همه صفحات', style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                        ],
                      ),
                    ),
                  ),
                  
                  // حاشیه پایین
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // ساخت سربرگ بخش با آیکون
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
      ],
    );
  }

  // ساخت کارت دسته‌بندی
  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 