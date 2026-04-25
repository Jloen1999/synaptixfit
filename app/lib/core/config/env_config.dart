import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  const EnvConfig._();

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ??
      const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');

  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ??
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasGoogleWebClientId => googleWebClientId.isNotEmpty;

  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;

  static String get cloudflareR2BaseUrl =>
      dotenv.env['CLOUDFLARE_R2_BASE_URL'] ??
      const String.fromEnvironment('CLOUDFLARE_R2_BASE_URL', defaultValue: '');

  static bool get hasCloudflareR2 => cloudflareR2BaseUrl.isNotEmpty;

  /// URL base del Cloudflare Worker que actúa como proxy de subida/borrado R2.
  /// Ejemplo: https://synaptixfit-r2-proxy.TU_SUBDOMINIO.workers.dev
  static String get r2WorkerUrl =>
      dotenv.env['VITE_R2_WORKER_URL'] ??
      const String.fromEnvironment('VITE_R2_WORKER_URL', defaultValue: '');

  static bool get hasR2Worker => r2WorkerUrl.isNotEmpty;
}
