// App API endpoints and operations
class AppLinks {
  // Base URL for API
  static const String baseUrl = 'http://khatoonbar.ir/api';
  
  // Core resource endpoints
  static String get cargos => '$baseUrl/cargos.php';
  static String get vehicles => '$baseUrl/vehicles.php';
  static String get drivers => '$baseUrl/drivers.php';
  static String get cargoTypes => '$baseUrl/cargo_types.php';
  static String get customers => '$baseUrl/customers.php';
  static String get cargoSellingCompanies => '$baseUrl/cargo_selling_companies.php';
  static String get shippingCompanies => '$baseUrl/shipping_companies.php';
  static String get bankAccounts => '$baseUrl/bank_accounts.php';
  static String get payments => '$baseUrl/payments.php';
  static String get expenses => '$baseUrl/expenses.php';
  static String get uploadImage => '$baseUrl/upload.php';
  static String get driverSalary => '$baseUrl/driver_salary.php';
  
  // Delete operationsimage.png
  static String deleteCargoTypeById(int id) => '$cargoTypes?id=$id';
  static String deleteDriverById(int id) => '$drivers?id=$id';
  static String deleteCustomerById(int id) => '$customers?id=$id';
  static String deleteCargoSellingCompanyById(int id) => '$cargoSellingCompanies?id=$id';
  static String deleteShippingCompanyById(int id) => '$shippingCompanies?id=$id';
  static String deleteBankAccountById(int id) => '$bankAccounts?id=$id';
  static String deleteVehicleById(int id) => '$vehicles?id=$id';
  
  // Update operations
  static String updateShippingCompanyById(int id) => '$shippingCompanies?id=$id';
  static String updateVehicleById(int id) => '$vehicles?id=$id';
  static String updateCustomerById(int id) => '$customers?id=$id';
  static String updateCargoTypeById(int id) => '$cargoTypes?id=$id';
  static String updateCargoSellingCompanyById(int id) => '$cargoSellingCompanies?id=$id';
  static String updateBankAccountById(int id) => '$bankAccounts?id=$id';
  static String updateCargoById(int id) => '$cargos?id=$id';
} 