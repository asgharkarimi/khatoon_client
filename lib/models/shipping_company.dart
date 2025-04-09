class ShippingCompany {
  final int id;
  final String name;
  final String? phoneNumber;

  ShippingCompany({
    required this.id,
    required this.name,
    this.phoneNumber,
  });

  // Create a ShippingCompany from JSON data
  factory ShippingCompany.fromJson(Map<String, dynamic> json) {
    return ShippingCompany(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      phoneNumber: json['phone_number'],
    );
  }

  // Convert ShippingCompany to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
    };
  }
} 