// lib/app_links.dart

class AppLinks {
  // --- Base URL Configuration ---
  // Use 10.0.2.2 for Android Emulator accessing localhost
  // Use your machine's local IP for physical device testing on the same network
  // Use the deployed domain in production
  static const String _baseUrl = "http://192.168.53.166/khatooonbar"; // <-- UPDATE FOR DIFFERENT ENVIRONMENTS
  
  // Make baseUrl accessible
  static String get baseUrl => _baseUrl;

  // --- API Endpoints ---
  static const String customers = "$_baseUrl/customers.php";
  static const String bankAccounts = "$_baseUrl/bank_accounts.php";
  static const String vehicles = "$_baseUrl/vehicles.php";
  static const String cargoSellingCompanies = "$_baseUrl/cargo_selling_companies.php";
  static const String cargoTypes = "$_baseUrl/cargo_types.php";
  static const String drivers = "$_baseUrl/drivers.php";
  static const String upload = "$_baseUrl/upload.php";
  
  // Helper methods for customer operations
  static String getCustomerById(int id) => "$customers?id=$id";
  static String deleteCustomerById(int id) => "$customers?id=$id";
  static String updateCustomerById(int id) => "$customers?id=$id";
  
  // Helper methods for bank account operations
  static String getBankAccountById(int id) => "$bankAccounts?id=$id";
  static String deleteBankAccountById(int id) => "$bankAccounts?id=$id";
  static String updateBankAccountById(int id) => "$bankAccounts?id=$id";
  
  // Helper methods for vehicle operations
  static String getVehicleById(int id) => "$vehicles?id=$id";
  static String deleteVehicleById(int id) => "$vehicles?id=$id";
  static String updateVehicleById(int id) => "$vehicles?id=$id";
  
  // Helper methods for cargo selling company operations
  static String getCargoSellingCompanyById(int id) => "$cargoSellingCompanies?id=$id";
  static String deleteCargoSellingCompanyById(int id) => "$cargoSellingCompanies?id=$id";
  static String updateCargoSellingCompanyById(int id) => "$cargoSellingCompanies?id=$id";
  
  // Helper methods for cargo type operations
  static String getCargoTypeById(int id) => "$cargoTypes?id=$id";
  static String deleteCargoTypeById(int id) => "$cargoTypes?id=$id";
  static String updateCargoTypeById(int id) => "$cargoTypes?id=$id";
  
  // Helper methods for driver operations
  static String getDriverById(int id) => "$drivers?id=$id";
  static String deleteDriverById(int id) => "$drivers?id=$id";
  static String updateDriverById(int id) => "$drivers?id=$id";
  
  // Add other API endpoints here as needed
  // static const String cargos = "$_baseUrl/api/cargos.php";
  // ... etc.
} 