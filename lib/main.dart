import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/dashboard.dart';
import 'screens/cargo_list.dart';
import 'screens/cargo_form.dart';
import 'screens/cargo_type_list.dart';
import 'screens/driver_list.dart';
import 'screens/customer_list.dart';
import 'screens/cargo_selling_company_list.dart';
import 'screens/shipping_company_list.dart';
import 'screens/bank_account_list.dart';
import 'screens/vehicle_list.dart';
import 'screens/payment_list.dart';
import 'screens/payment_form.dart';
import 'screens/expense_list.dart';
import 'screens/expense_form.dart';
import 'screens/login_screen.dart';
import 'screens/driver_income_report.dart';
import 'screens/driver_form.dart';
import 'screens/customer_form.dart';
import 'screens/cargo_type_form.dart';
import 'screens/shipping_company_form.dart';
import 'screens/cargo_selling_company_form.dart';
import 'screens/bank_account_form.dart';
import 'screens/vehicle_form.dart';
import 'common/enums.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'خاتون بار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Vazir',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5E35B1), // Deep purple
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
        ),
        // Enhanced visual styles
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF5E35B1),
          titleTextStyle: const TextStyle(
            fontFamily: 'Vazir',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5E35B1),
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF5E35B1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 2, color: Color(0xFF5E35B1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(width: 1, color: Colors.grey.shade400),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      localizationsDelegates: const [
        
        PersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa', ''),
      ],
      home: Dashboard(userRole: UserRole.admin),
      routes: {
        Dashboard.routeName: (ctx) => const Dashboard(userRole: UserRole.admin),
        CargoListScreen.routeName: (ctx) => const CargoListScreen(),
        CargoForm.routeName: (ctx) => const CargoForm(),
        VehicleListScreen.routeName: (ctx) => const VehicleListScreen(),
        DriverListScreen.routeName: (ctx) => const DriverListScreen(),
        CargoTypeListScreen.routeName: (ctx) => const CargoTypeListScreen(),
        CustomerListScreen.routeName: (ctx) => const CustomerListScreen(),
        CargoSellingCompanyListScreen.routeName: (ctx) => const CargoSellingCompanyListScreen(),
        ShippingCompanyListScreen.routeName: (ctx) => const ShippingCompanyListScreen(),
        BankAccountListScreen.routeName: (ctx) => const BankAccountListScreen(),
        PaymentListScreen.routeName: (ctx) => const PaymentListScreen(),
        PaymentForm.routeName: (ctx) => const PaymentForm(),
        ExpenseListScreen.routeName: (ctx) => const ExpenseListScreen(),
        ExpenseForm.routeName: (ctx) => const ExpenseForm(),
        DriverIncomeReportScreen.routeName: (ctx) => const DriverIncomeReportScreen(),
        DriverForm.routeName: (ctx) => const DriverForm(),
        CustomerAddForm.routeName: (ctx) => const CustomerAddForm(),
        CargoTypeForm.routeName: (ctx) => const CargoTypeForm(),
        ShippingCompanyForm.routeName: (ctx) => const ShippingCompanyForm(),
        CargoSellingCompanyForm.routeName: (ctx) => const CargoSellingCompanyForm(),
        BankAccountForm.routeName: (ctx) => const BankAccountForm(),
        VehicleForm.routeName: (ctx) => const VehicleForm(),
      },
    );
  }
}











// echo "# khatoonbarapi" >> README.md
// git init
// git add README.md
// git commit -m "first commit"
// git branch -M main
// git remote add origin https://github.com/asgharkarimi/khatoonbar_client.git
// git push -u origin main