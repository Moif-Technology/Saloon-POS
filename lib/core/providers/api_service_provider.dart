import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/config/api_config.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/services/mock_api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  if (useMockData) return MockApiService();
  return ApiService();
});
