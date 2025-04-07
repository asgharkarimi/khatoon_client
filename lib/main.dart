import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:khatoonbar_client/screens/customer_form.dart';
import 'screens/customer_list.dart';
import 'screens/bank_account_list.dart';
import 'screens/vehicle_list.dart';
import 'screens/cargo_selling_company_list.dart';
import 'screens/cargo_type_list.dart';
import 'screens/driver_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'خاتون بار',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5), // Indigo as the primary color
          brightness: Brightness.light,
          secondary: const Color(0xFFFF9800), // Orange as the secondary color
        ),
        fontFamily: 'Vazir',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          bodyMedium: TextStyle(fontSize: 14.0, letterSpacing: 0.25),
        ),
        // Card styling
        cardTheme: CardTheme(
          elevation: 3,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        // AppBar styling
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          backgroundColor: Color(0xFF3F51B5),
          foregroundColor: Colors.white,
        ),
        // Input decoration theme for forms
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        // Button styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F51B5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // Floating action button styling
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFF9800),
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      locale: const Locale('fa'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fa'),
      ],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // RTL for Persian language
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خاتون‌بار'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildMenuCard(
                context,
                title: 'مدیریت مشتریان',
                icon: Icons.people,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CustomerListScreen()),
                  );
                },
              ),
              _buildMenuCard(
                context,
                title: 'مدیریت حساب‌های بانکی',
                icon: Icons.account_balance,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BankAccountListScreen()),
                  );
                },
              ),
              _buildMenuCard(
                context,
                title: 'مدیریت خودروها',
                icon: Icons.directions_car,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VehicleListScreen()),
                  );
                },
              ),
              _buildMenuCard(
                context,
                title: 'مدیریت بارها',
                icon: Icons.local_shipping,
                onTap: () {
                  // TODO: Navigate to cargo management
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('این قسمت هنوز آماده نیست')),
                  );
                },
              ),
              _buildMenuCard(
                context,
                title: 'شرکت‌های فروشنده بار',
                icon: Icons.business,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CargoSellingCompanyListScreen()),
                  );
                },
              ),
              _buildMenuCard(
                context,
                title: 'انواع بار',
                icon: Icons.category,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CargoTypeListScreen()),
                  );
                },
              ),
              _buildMenuCard(
                context,
                title: 'مدیریت رانندگان',
                icon: Icons.drive_eta,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DriverListScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

