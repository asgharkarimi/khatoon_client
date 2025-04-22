import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../app_links.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? Function(dynamic)? dataParser) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown response',
      data: json['data'] != null && dataParser != null ? dataParser(json['data']) : null,
    );
  }
}

class ApiService {
  // Generic GET request
  static Future<ApiResponse<T>> get<T>(
    String url, 
    T Function(dynamic)? dataParser,
  ) async {
    try {
      final response = await http.get(Uri.parse(url));
      return _handleResponse(response, dataParser);
    } on SocketException {
      return ApiResponse(success: false, message: 'No Internet connection');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }

  // Generic POST request
  static Future<ApiResponse<T>> post<T>(
    String url,
    Map<String, dynamic> body,
    T Function(dynamic)? dataParser,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        body: body,
      );
      return _handleResponse(response, dataParser);
    } on SocketException {
      return ApiResponse(success: false, message: 'No Internet connection');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }

  // Generic PUT request
  static Future<ApiResponse<T>> put<T>(
    String url,
    Map<String, dynamic> body,
    T Function(dynamic)? dataParser,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        body: body,
      );
      return _handleResponse(response, dataParser);
    } on SocketException {
      return ApiResponse(success: false, message: 'No Internet connection');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }

  // Generic DELETE request
  static Future<ApiResponse<T>> delete<T>(
    String url,
    T Function(dynamic)? dataParser,
  ) async {
    try {
      final response = await http.delete(Uri.parse(url));
      return _handleResponse(response, dataParser);
    } on SocketException {
      return ApiResponse(success: false, message: 'No Internet connection');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error: ${e.toString()}');
    }
  }

  // Handle HTTP response
  static ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? dataParser,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final jsonData = json.decode(response.body);
        return ApiResponse.fromJson(jsonData, dataParser);
      } catch (e) {
        return ApiResponse(
          success: false,
          message: 'Error parsing response: ${e.toString()}',
        );
      }
    } else {
      return ApiResponse(
        success: false,
        message: 'Request failed with status: ${response.statusCode}',
      );
    }
  }
} 