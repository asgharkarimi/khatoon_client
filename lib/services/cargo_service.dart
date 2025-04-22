import '../models/cargo_model.dart';
import 'api_service.dart';
import '../app_links.dart';

class CargoService {
  // Fetch all cargos
  static Future<ApiResponse<List<Cargo>>> getAllCargos() async {
    return await ApiService.get<List<Cargo>>(
      AppLinks.cargos,
      (data) {
        if (data is List) {
          return data.map((item) => Cargo.fromJson(item)).toList();
        }
        return [];
      },
    );
  }

  // Fetch a specific cargo by ID
  static Future<ApiResponse<Cargo>> getCargoById(int id) async {
    return await ApiService.get<Cargo>(
      '${AppLinks.cargos}?id=$id',
      (data) => Cargo.fromJson(data),
    );
  }

  // Create a new cargo
  static Future<ApiResponse<Cargo>> createCargo(Cargo cargo) async {
    return await ApiService.post<Cargo>(
      AppLinks.cargos,
      cargo.toJson(),
      (data) => Cargo.fromJson(data),
    );
  }

  // Update an existing cargo
  static Future<ApiResponse<Cargo>> updateCargo(Cargo cargo) async {
    if (cargo.id == null) {
      return ApiResponse(
        success: false,
        message: 'Cargo ID is required for update',
      );
    }

    return await ApiService.put<Cargo>(
      AppLinks.updateCargoById(cargo.id!),
      cargo.toJson(),
      (data) => Cargo.fromJson(data),
    );
  }

  // Delete a cargo
  static Future<ApiResponse<bool>> deleteCargo(int id) async {
    return await ApiService.delete<bool>(
      '${AppLinks.cargos}?id=$id',
      (data) => data is bool ? data : false,
    );
  }
} 