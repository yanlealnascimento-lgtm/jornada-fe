import 'package:flutter/foundation.dart';
import 'dart:io';

class AppConfig {
  AppConfig._();

  /// URL da API injetada via --dart-define=API_URL=http://...
  /// Padrão automático:
  ///   Emulador Android  → 10.0.2.2:4000
  ///   Simulador iOS     → localhost:4000
  ///   Release/produção  → deve ser definida via --dart-define
  static const String _injectedUrl = String.fromEnvironment('API_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (_injectedUrl.isNotEmpty) return _injectedUrl;
    if (kReleaseMode) return 'https://api.journeyfaith.app/api/v1';
    // Debug Android: funciona tanto em emulador (10.0.2.2) quanto em
    // device físico via "adb reverse tcp:4000 tcp:4000" (localhost)
    if (Platform.isAndroid) return 'http://192.168.1.6:4000/api/v1';
    return 'http://localhost:4000/api/v1';
  }

  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
