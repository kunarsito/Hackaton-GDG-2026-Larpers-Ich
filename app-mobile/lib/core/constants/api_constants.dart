import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Permite fijar la URL sin tocar código (p. ej. un teléfono físico en la red local):
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3001/api
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Puertos donde se busca el backend si no hay API_BASE_URL. El 3000 suele
  /// estar ocupado por otros proyectos, por eso se prueban varios y se elige el
  /// que responde como FARO_DEV en /api/health (ApiService.discoverServer).
  static const List<int> candidatePorts = [3000, 3001, 3002];

  static String? _resolved;

  /// Web y escritorio: localhost. Emulador Android: 10.0.2.2 (el localhost de la PC).
  static String get _host =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

  static bool get hasOverride => _override.isNotEmpty;

  static List<String> get candidateUrls =>
      hasOverride ? [_override] : [for (final p in candidatePorts) 'http://$_host:$p/api'];

  static String get baseUrl => _resolved ?? (hasOverride ? _override : 'http://$_host:3000/api');

  static void useBaseUrl(String url) => _resolved = url;

  static String get articlesEndpoint => '$baseUrl/articles';
  static String get challengesEndpoint => '$baseUrl/challenges';
  static String get communityEndpoint => '$baseUrl/community';
  static String get jobsEndpoint => '$baseUrl/jobs';
  static String get validateCodeEndpoint => '$baseUrl/challenges/validate';
  static String get userEndpoint => '$baseUrl/user';
  static String get authEndpoint => '$baseUrl/auth';
}
