class Vehicle {
  final int id;
  final String name;
  final String? smartCardNumber;
  final String? healthCode;

  Vehicle({
    required this.id,
    required this.name,
    this.smartCardNumber,
    this.healthCode,
  });

  // Create a Vehicle from JSON data
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: int.parse(json['id']),
      name: json['name'],
      smartCardNumber: json['smart_card_number'],
      healthCode: json['health_code'],
    );
  }

  // Convert Vehicle to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': name,
      'smart_card_number': smartCardNumber,
      'health_code': healthCode,
    };
  }
} 