import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/dashboard_page.dart';
import 'login_page.dart';

/// Cambia de pantalla al entrar o salir; no deja rutas privadas detrás del login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authChanges;

  @override
  void initState() {
    super.initState();
    _authChanges = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authChanges,
      builder: (context, snapshot) {
        // StreamBuilder también atiende los errores del stream de autenticación.
        if (snapshot.hasError) {
          return const LoginPage(
            aviso: 'No se pudo recuperar la sesión. Revisa tu conexión e intenta entrar.',
          );
        }
        final session = snapshot.hasData
            ? snapshot.data!.session
            : Supabase.instance.client.auth.currentSession;

        if (session == null) return const LoginPage();

        // Cambiar de cuenta crea un estado nuevo y descarta los resultados previos.
        // Las rutas privadas (incluidos filtros y diálogos) pertenecen a la sesión.
        // Al salir o cambiar de cuenta se descarta este Navigator completo.
        return _SesionPrivada(key: ValueKey(session.user.id));
      },
    );
  }
}

class _SesionPrivada extends StatefulWidget {
  const _SesionPrivada({super.key});

  @override
  State<_SesionPrivada> createState() => _SesionPrivadaState();
}

class _SesionPrivadaState extends State<_SesionPrivada> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => NavigatorPopHandler<Object?>(
    onPopWithResult: (resultado) => _navigatorKey.currentState!.pop(resultado),
    child: Navigator(
      key: _navigatorKey,
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => const DashboardPage()),
    ),
  );
}
