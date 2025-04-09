class Cargo {
  final int? id;
  final int vehicleId;
  final int driverId;
  final int cargoTypeId;
  final int customerId;
  final int shippingCompanyId;
  final int sellingCompanyId;
  final String origin;
  final String destination;
  final String? loadingDate;
  final String? unloadingDate;
  final double weightTonnes;
  final double pricePerTonne;
  final double transportCostPerTonne;
  final int customerPaymentStatusId;
  final bool sellerPaymentStatus;
  final double? waybillAmount;
  final String? waybillImage;
  final int? customerBankAccountId;

  // Additional fields from joins
  final String? vehicleName;
  final String? driverName;
  final String? cargoTypeName;
  final String? customerName;
  final String? shippingCompanyName;
  final String? sellingCompanyName;
  final String? customerPaymentStatusName;
  final String? customerBankAccountName;
  final double? driverSalaryPercentage;
  final double? driverIncome;

  Cargo({
    this.id,
    required this.vehicleId,
    required this.driverId,
    required this.cargoTypeId,
    required this.customerId,
    required this.shippingCompanyId,
    required this.sellingCompanyId,
    required this.origin,
    required this.destination,
    this.loadingDate,
    this.unloadingDate,
    required this.weightTonnes,
    required this.pricePerTonne,
    required this.transportCostPerTonne,
    required this.customerPaymentStatusId,
    required this.sellerPaymentStatus,
    this.waybillAmount,
    this.waybillImage,
    this.customerBankAccountId,
    this.vehicleName,
    this.driverName,
    this.cargoTypeName,
    this.customerName,
    this.shippingCompanyName,
    this.sellingCompanyName,
    this.customerPaymentStatusName,
    this.customerBankAccountName,
    this.driverSalaryPercentage,
    this.driverIncome,
  });

  factory Cargo.fromJson(Map<String, dynamic> json) {
    return Cargo(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      vehicleId: int.parse(json['vehicle_id'].toString()),
      driverId: int.parse(json['driver_id'].toString()),
      cargoTypeId: int.parse(json['cargo_type_id'].toString()),
      customerId: int.parse(json['customer_id'].toString()),
      shippingCompanyId: int.parse(json['shipping_company_id'].toString()),
      sellingCompanyId: int.parse(json['selling_company_id'].toString()),
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      loadingDate: json['loading_date'],
      unloadingDate: json['unloading_date'],
      weightTonnes: double.parse(json['weight_tonnes'].toString()),
      pricePerTonne: double.parse(json['price_per_tonne'].toString()),
      transportCostPerTonne: double.parse(json['transport_cost_per_tonne'].toString()),
      customerPaymentStatusId: int.parse(json['customer_payment_status_id'].toString()),
      sellerPaymentStatus: json['seller_payment_status'] == 1 || json['seller_payment_status'] == true,
      waybillAmount: json['waybill_amount'] != null ? double.parse(json['waybill_amount'].toString()) : null,
      waybillImage: json['waybill_image'],
      customerBankAccountId: json['customer_bank_account_id'] != null ? int.parse(json['customer_bank_account_id'].toString()) : null,
      vehicleName: json['vehicle_name'],
      driverName: json['driver_name'],
      cargoTypeName: json['cargo_type_name'],
      customerName: json['customer_name'],
      shippingCompanyName: json['shipping_company_name'],
      sellingCompanyName: json['selling_company_name'],
      customerPaymentStatusName: json['customer_payment_status_name'],
      customerBankAccountName: json['customer_bank_account_name'],
      driverSalaryPercentage: json['driver_salary_percentage'] != null ? double.parse(json['driver_salary_percentage'].toString()) : null,
      driverIncome: json['driver_income'] != null ? double.parse(json['driver_income'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'cargo_type_id': cargoTypeId,
      'customer_id': customerId,
      'shipping_company_id': shippingCompanyId,
      'selling_company_id': sellingCompanyId,
      'origin': origin,
      'destination': destination,
      'loading_date': loadingDate,
      'unloading_date': unloadingDate,
      'weight_tonnes': weightTonnes,
      'price_per_tonne': pricePerTonne,
      'transport_cost_per_tonne': transportCostPerTonne,
      'customer_payment_status_id': customerPaymentStatusId,
      'seller_payment_status': sellerPaymentStatus ? 1 : 0,
      if (waybillAmount != null) 'waybill_amount': waybillAmount,
      if (waybillImage != null) 'waybill_image': waybillImage,
      if (customerBankAccountId != null) 'customer_bank_account_id': customerBankAccountId,
      'vehicle_name': vehicleName,
      'driver_name': driverName,
      'customer_name': customerName,
      'customer_payment_status_name': customerPaymentStatusName,
      'driver_salary_percentage': driverSalaryPercentage,
    };
  }
}
