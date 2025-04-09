import 'package:flutter/material.dart';
import 'bank_account_list.dart';
import 'cargo_list.dart';
import 'cargo_form.dart';
import 'cargo_selling_company_list.dart';
import 'cargo_type_list.dart';
import 'customer_list.dart';
import 'driver_list.dart';
import 'shipping_company_list.dart';
import 'vehicle_list.dart';
import 'login_screen.dart';
import 'payment_list.dart';
import 'payment_form.dart';
import 'expense_list.dart';
import 'expense_form.dart';
import '../common/enums.dart';

class Dashboard extends StatelessWidget {
  static const routeName = '/dashboard';
  
  final UserRole userRole;

  const Dashboard({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('داشبورد', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'خروج',
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.grey.shade50,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    SizedBox(height: 20,),
                    
                    // Quick Access
                    _buildSectionTitle(context, 'دسترسی سریع', Icons.speed),
                    const SizedBox(height: 12),
                    
                    GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                      children: [
                        _buildQuickAccessCard(
                          context,
                          title: 'بار جدید',
                          icon: Icons.add_box_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => Navigator.pushNamed(context, CargoForm.routeName),
                        ),
                        _buildQuickAccessCard(
                          context, 
                          title: 'ثبت هزینه',
                          icon: Icons.receipt_long,
                          color: Theme.of(context).colorScheme.tertiary,
                          onTap: () => Navigator.pushNamed(context, ExpenseForm.routeName),
                        ),
                        _buildQuickAccessCard(
                          context,
                          title: 'پرداخت جدید',
                          icon: Icons.payments_rounded,
                          color: Colors.green,
                          onTap: () => Navigator.pushNamed(context, PaymentForm.routeName),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Management Section
                    if (userRole == UserRole.admin) ...[
                      _buildSectionTitle(context, 'مدیریت اطلاعات', Icons.settings),
                      const SizedBox(height: 12),
                      
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                        children: [
                          _buildManagementCard(
                            context,
                            icon: Icons.people,
                            title: 'مشتریان',
                            onTap: () => Navigator.pushNamed(context, CustomerListScreen.routeName),
                            color: Colors.blue,
                          ),
                          _buildManagementCard(
                            context,
                            icon: Icons.person,
                            title: 'رانندگان',
                            onTap: () => Navigator.pushNamed(context, DriverListScreen.routeName),
                            color: Colors.purple,
                          ),
                          _buildManagementCard(
                            context,
                            icon: Icons.directions_car,
                            title: 'خودروها',
                            onTap: () => Navigator.pushNamed(context, VehicleListScreen.routeName),
                            color: Colors.indigo,
                          ),
                          _buildManagementCard(
                            context,
                            icon: Icons.category,
                            title: 'انواع بار',
                            onTap: () => Navigator.pushNamed(context, CargoTypeListScreen.routeName),
                            color: Colors.amber.shade800,
                          ),
                          _buildManagementCard(
                            context,
                            icon: Icons.business,
                            title: 'شرکت‌های فروش',
                            onTap: () => Navigator.pushNamed(context, CargoSellingCompanyListScreen.routeName),
                            color: Colors.deepOrange,
                          ),
                          _buildManagementCard(
                            context,
                            icon: Icons.local_shipping,
                            title: 'شرکت‌های حمل',
                            onTap: () => Navigator.pushNamed(context, ShippingCompanyListScreen.routeName),
                            color: Colors.teal,
                          ),
                          _buildManagementCard(
                            context,
                            icon: Icons.account_balance,
                            title: 'حساب‌های بانکی',
                            onTap: () => Navigator.pushNamed(context, BankAccountListScreen.routeName),
                            color: Colors.green,
                          ),
                          _buildManagementCard(
                            context,
                            icon: Icons.payment,
                            title: 'پرداخت‌ها',
                            onTap: () => Navigator.pushNamed(context, PaymentListScreen.routeName),
                            color: Colors.red,
                          ),
                          _buildManagementCard(
                            context,
                            icon: Icons.receipt,
                            title: 'هزینه‌ها',
                            onTap: () => Navigator.pushNamed(context, ExpenseListScreen.routeName),
                            color: Colors.brown,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                    
                    // Reports Section
                    _buildSectionTitle(context, 'گزارش‌ها', Icons.assessment),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 150,
                            child: _buildReportCard(
                              context,
                              title: 'گزارش حقوق رانندگان',
                              icon: Icons.insights,
                              color: Colors.deepPurple,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('این بخش در حال توسعه است')),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 150,
                            child: _buildReportCard(
                              context,
                              title: 'گزارش مالی',
                              icon: Icons.bar_chart,
                            
                              color: Colors.indigo,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('این بخش در حال توسعه است')),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom padding to avoid overflow
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 