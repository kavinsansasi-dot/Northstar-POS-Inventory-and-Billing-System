import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final preferences = await SharedPreferences.getInstance();
          final token = preferences.getString(authTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final preferences = await SharedPreferences.getInstance();
            await preferences.remove(authTokenKey);
            await preferences.remove(authUserKey);
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio dio;
  static void Function()? onUnauthorized;

  static String errorMessage(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic> &&
          responseData['message'] is String) {
        return responseData['message'] as String;
      }
      return error.message ?? 'Could not connect to the POS server.';
    }
    return 'Something went wrong. Please try again.';
  }
}
