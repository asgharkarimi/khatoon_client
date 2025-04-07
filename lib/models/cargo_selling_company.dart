class CargoSellingCompany {
  final int id;
  final String name;
  final String? phoneNumber;

  CargoSellingCompany({
    required this.id,
    required this.name,
    this.phoneNumber,
  });

  // Create a CargoSellingCompany from JSON data
  factory CargoSellingCompany.fromJson(Map<String, dynamic> json) {
    return CargoSellingCompany(
      id: int.parse(json['id']),
      name: json['name'],
      phoneNumber: json['phone_number'],
    );
  }

  // Convert CargoSellingCompany to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
    };
  }
} 