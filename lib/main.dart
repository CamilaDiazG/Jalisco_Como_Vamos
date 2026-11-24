import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'data/https_only.dart';
import 'data/secure_session_storage.dart';
import 'screens/dashboard_page.dart';

Future<void> main() async {
  HttpOverrides.global = HttpsOnlyOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lyzmbhfozrtfqcvmgsln.supabase.co',
    publishableKey: 'sb_publishable_ZzijvTalC_flFivZ6s2dXg_tz5e7c3Y',
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(persistSessionKey: 'sb-lyzmbhfozrtfqcvmgsln-auth-token'),
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Marca.fondo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Marca.azul,
        primary: Marca.azul,
        secondary: Marca.rojo,
        surface: Colors.white,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jalisco Cómo Vamos',
      theme: base.copyWith(
        textTheme: GoogleFonts.robotoTextTheme(base.textTheme),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Marca.azul,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Marca.azul,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Marca.borde),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
