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
          title: const Text('خاتون بار', style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          )),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              tooltip: 'خروج',
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with welcome message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Quick Stats Row has been removed as requested
                    ],
                  ),
                ),
                
                // Large Add Cargo Button
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, CargoForm.routeName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_box_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'افزودن بار جدید',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Quick Actions section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دسترسی سریع',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Quick action buttons - first row
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                        children: [
                          _buildActionButton(
                            context,
                            icon: Icons.view_list,
                            label: 'لیست بارها',
                            bgColor: AppTheme.primaryColor.withOpacity(0.1),
                            iconColor: AppTheme.primaryColor,
                            onTap: () => Navigator.pushNamed(context, CargoListScreen.routeName),
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.payments_rounded,
                            label: 'پرداخت جدید',
                            bgColor: AppTheme.successColor.withOpacity(0.1),
                            iconColor: AppTheme.successColor,
                            onTap: () => Navigator.pushNamed(context, PaymentForm.routeName),
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.receipt_long,
                            label: 'ثبت هزینه',
                            bgColor: AppTheme.warningColor.withOpacity(0.1),
                            iconColor: AppTheme.warningColor,
                            onTap: () => Navigator.pushNamed(context, ExpenseForm.routeName),
                          ),
                        ],
                      ),
                      
                      // Quick action buttons - second row
                      const SizedBox(height: 16),
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                        children: [
                          _buildActionButton(
                            context,
                            icon: Icons.payment,
                            label: 'پرداخت‌ها',
                            bgColor: Colors.purple.withOpacity(0.1),
                            iconColor: Colors.purple,
                            onTap: () => Navigator.pushNamed(context, PaymentListScreen.routeName),
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.receipt,
                            label: 'هزینه‌ها',
                            bgColor: Colors.deepOrange.withOpacity(0.1),
                            iconColor: Colors.deepOrange,
                            onTap: () => Navigator.pushNamed(context, ExpenseListScreen.routeName),
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.info_outline,
                            label: 'جزئیات بار',
                            bgColor: Colors.blue.withOpacity(0.1),
                            iconColor: Colors.blue,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ابتدا یک بار را انتخاب کنید')),
                              );
                            },
                          ),
                          _buildActionButton(
                            context,
                            icon: Icons.monetization_on,
                            label: 'درآمد رانندگان',
                            bgColor: Colors.green.withOpacity(0.1),
                            iconColor: Colors.green,
                            onTap: () => Navigator.pushNamed(context, DriverIncomeReportScreen.routeName),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Management Section
                if (userRole == UserRole.admin) ...[
                  // Cargo Management
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مدیریت بار',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Cargo management section
                        _buildExpandableSection(
                          context, 
                          screens: [
                            ScreenInfo(
                              title: 'لیست بارها',
                              icon: Icons.view_list,
                              route: CargoListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'انواع بار',
                              icon: Icons.category,
                              route: CargoTypeListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'ثبت نوع بار',
                              icon: Icons.add_circle_outline,
                              route: CargoTypeForm.routeName,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // People Management
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مدیریت افراد',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // People management section
                        _buildExpandableSection(
                          context, 
                          screens: [
                            ScreenInfo(
                              title: 'لیست رانندگان',
                              icon: Icons.person,
                              route: DriverListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'راننده جدید',
                              icon: Icons.person_add,
                              route: DriverForm.routeName,
                            ),
                            ScreenInfo(
                              title: 'لیست مشتریان',
                              icon: Icons.people,
                              route: CustomerListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'مشتری جدید',
                              icon: Icons.person_add_alt_1,
                              route: CustomerAddForm.routeName,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Companies Management
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مدیریت شرکت‌ها',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Companies management section
                        _buildExpandableSection(
                          context, 
                          screens: [
                            ScreenInfo(
                              title: 'شرکت‌های فروش',
                              icon: Icons.business,
                              route: CargoSellingCompanyListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'ثبت شرکت فروش',
                              icon: Icons.add_business,
                              route: CargoSellingCompanyForm.routeName,
                            ),
                            ScreenInfo(
                              title: 'شرکت‌های حمل',
                              icon: Icons.local_shipping,
                              route: ShippingCompanyListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'ثبت شرکت حمل',
                              icon: Icons.add_circle,
                              route: ShippingCompanyForm.routeName,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Vehicles Management
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مدیریت خودروها',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Vehicles management section
                        _buildExpandableSection(
                          context, 
                          screens: [
                            ScreenInfo(
                              title: 'لیست خودروها',
                              icon: Icons.directions_car,
                              route: VehicleListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'ثبت خودرو',
                              icon: Icons.add_circle,
                              route: VehicleForm.routeName,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Financial Management
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مدیریت مالی',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Financial management section
                        _buildExpandableSection(
                          context, 
                          screens: [
                            ScreenInfo(
                              title: 'حساب‌های بانکی',
                              icon: Icons.account_balance,
                              route: BankAccountListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'ثبت حساب بانکی',
                              icon: Icons.add_card,
                              route: BankAccountForm.routeName,
                            ),
                            ScreenInfo(
                              title: 'پرداخت‌ها',
                              icon: Icons.payment,
                              route: PaymentListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'ثبت پرداخت',
                              icon: Icons.payments,
                              route: PaymentForm.routeName,
                            ),
                            ScreenInfo(
                              title: 'هزینه‌ها',
                              icon: Icons.receipt,
                              route: ExpenseListScreen.routeName,
                            ),
                            ScreenInfo(
                              title: 'ثبت هزینه',
                              icon: Icons.receipt_long,
                              route: ExpenseForm.routeName,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Reports Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'گزارش‌ها',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Report cards
                      _buildReportCards(context),
                    ],
                  ),
                ),
                
                // Bottom padding
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpandableSection(
    BuildContext context, {
    required List<ScreenInfo> screens,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 16,
        children: screens.map((screen) => 
          _buildFeatureCard(
            context,
            title: screen.title,
            icon: screen.icon,
            onTap: () => Navigator.pushNamed(context, screen.route),
          )
        ).toList(),
      ),
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 72) / 2, // 2 cards per row with margins
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildReportCards(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'گزارش‌های مالی و وضعیت',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildReportButton(
                context, 
                icon: Icons.insights, 
                title: 'درآمد رانندگان',
                onTap: () {
                  try {
                    Navigator.pushNamed(context, DriverIncomeReportScreen.routeName);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('این بخش در حال توسعه است')),
                    );
                  }
                },
              ),
              const SizedBox(width: 16),
              _buildReportButton(
                context, 
                icon: Icons.bar_chart, 
                title: 'گزارش مالی',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('این بخش در حال توسعه است')),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildReportButton(
                context, 
                icon: Icons.local_shipping, 
                title: 'بارهای جاری',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('این بخش در حال توسعه است')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 