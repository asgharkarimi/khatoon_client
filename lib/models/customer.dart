class Customer {
  final int id;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  // Create a Customer from JSON data
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: int.parse(json['id']),
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
    );
  }

  // Convert Customer to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
    };
  }

  // Full name helper
  String get fullName => "$firstName $lastName";
} 