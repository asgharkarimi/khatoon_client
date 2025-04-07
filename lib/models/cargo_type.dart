class CargoType {
  final int id;
  final String name;

  CargoType({
    required this.id,
    required this.name,
  });

  // Create a CargoType from JSON data
  factory CargoType.fromJson(Map<String, dynamic> json) {
    return CargoType(
      id: int.parse(json['id']),
      name: json['name'],
    );
  }

  // Convert CargoType to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
} 