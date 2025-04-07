class Driver {
  final int id;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final double? salaryPercentage;
  final int? bankAccountId;
  final String? nationalId;
  final String? nationalIdCardImage;
  final String? driverLicenseImage;
  final String? driverSmartCardImage;

  Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.salaryPercentage,
    this.bankAccountId,
    this.nationalId,
    this.nationalIdCardImage,
    this.driverLicenseImage,
    this.driverSmartCardImage,
  });

  // Create a Driver from JSON data
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: int.parse(json['id']),
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      salaryPercentage: json['salary_percentage'] != null 
          ? double.parse(json['salary_percentage']) 
          : null,
      bankAccountId: json['bank_account_id'] != null 
          ? int.parse(json['bank_account_id']) 
          : null,
      nationalId: json['national_id'],
      nationalIdCardImage: json['national_id_card_image'],
      driverLicenseImage: json['driver_license_image'],
      driverSmartCardImage: json['driver_smart_card_image'],
    );
  }

  // Convert Driver to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'salary_percentage': salaryPercentage,
      'bank_account_id': bankAccountId,
      'national_id': nationalId,
      'national_id_card_image': nationalIdCardImage,
      'driver_license_image': driverLicenseImage,
      'driver_smart_card_image': driverSmartCardImage,
    };
  }

  // Full name helper
  String get fullName => "$firstName $lastName";
} 