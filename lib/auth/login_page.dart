import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  final String? aviso;
  const LoginPage({super.key, this.aviso});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _azul = Color(0xFF003E79);
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _ocupado = false;
  bool _ocultarPassword = true;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_ocupado || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });

    try {
      final respuesta = await Supabase.instance.client.auth.signInWithPassword(
        email: _correo.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      if (respuesta.session == null) {
        setState(
              () => _error = 'No se abrió una sesión. Intenta entrar nuevamente.',
        );
      } else {
        _password.clear();
        // AuthGate recibe el evento de sesión y cambia de pantalla.
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      final mensaje = error.message.toLowerCase();
      setState(() {
        _error = mensaje.contains('invalid login credentials')
            ? 'El correo o la contraseña no coinciden.'
            : mensaje.contains('email not confirmed')
            ? 'La cuenta aún no está confirmada. Revisa el usuario de prueba en Supabase.'
            : error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
            () => _error =
        'No se pudo conectar. Revisa tu conexión e intenta nuevamente.',
      );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error ?? widget.aviso;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo_jaliscocomovamos.png',
                        height: 78,
                        fit: BoxFit.contain,
                        semanticLabel: 'Jalisco Cómo Vamos',
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Bienvenido',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: _azul,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Inicia sesión para consultar los resultados de la encuesta.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _correo,
                        enabled: !_ocupado,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.username],
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.mail_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final correo = value?.trim() ?? '';
                          if (correo.isEmpty) return 'Escribe tu correo.';
                          if (!correo.contains('@'))
                            return 'Revisa el correo electrónico.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !_ocupado,
                        obscureText: _ocultarPassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _entrar(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _ocultarPassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: _ocupado
                                ? null
                                : () {
                              setState(
                                    () =>
                                _ocultarPassword = !_ocultarPassword,
                              );
                            },
                            icon: Icon(
                              _ocultarPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Escribe tu contraseña.'
                            : null,
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          error,
                          style: const TextStyle(color: Color(0xFFC60C46)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _ocupado ? null : _entrar,
                        style: FilledButton.styleFrom(
                          backgroundColor: _azul,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: _ocupado
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Entrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
