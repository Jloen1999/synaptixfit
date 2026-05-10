import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env_config.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!EnvConfig.hasSupabase) {
      debugPrint(
        'SUPABASE_URL y SUPABASE_ANON_KEY no definidos. Se ejecuta en modo mock.',
      );
      _initialized = true;
      return;
    }

    await Supabase.initialize(
        url: EnvConfig.supabaseUrl, anonKey: EnvConfig.supabaseAnonKey);
    _initialized = true;
  }
}
