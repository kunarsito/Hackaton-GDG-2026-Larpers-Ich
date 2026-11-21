import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Permite apuntar a otra URL sin tocar código:
  /// flutter run --dart-define=API_BASE_URL=http://localhost:3001/api
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  static String get articlesEndpoint => '$baseUrl/articles';
  static String get challengesEndpoint => '$baseUrl/challenges';
  static String get communityEndpoint => '$baseUrl/community';
  static String get jobsEndpoint => '$baseUrl/jobs';
  static String get validateCodeEndpoint => '$baseUrl/challenges/validate';
  static String get userEndpoint => '$baseUrl/user';
  static String get authEndpoint => '$baseUrl/auth';
}
