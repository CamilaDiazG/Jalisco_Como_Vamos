import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'preguntas_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const _blue = Color(0xFF003E79);
  final _email = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;
  String? _message;
  String? _error;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void dispose() {
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() action, String message) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      await action();
      if (mounted) setState(() => _message = message);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo completar la acción. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeEmail() async {
    final newEmail = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(newEmail)) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    if (newEmail == _client.auth.currentUser?.email) {
      setState(() => _error = 'Ese ya es tu correo actual.');
      return;
    }
    await _perform(() async {
      await _client.auth.updateUser(UserAttributes(email: newEmail));
      if (!mounted) return;
      _email.clear();
    }, 'Revisa tu correo actual y el nuevo para confirmar el cambio.');
  }

  Future<void> _changePassword() async {
    final current = _currentPassword.text;
    final next = _newPassword.text;
    if (current.isEmpty || next.length < 12 || next != _confirmPassword.text) {
      setState(() => _error = 'Escribe tu contraseña actual y una nueva de al menos 12 caracteres; confirma que coincidan.');
      return;
    }
    await _perform(() async {
      await _client.auth.updateUser(
        UserAttributes(currentPassword: current, password: next),
      );
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
    }, 'Contraseña actualizada.');
  }

  Future<void> _signOut() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir de tu cuenta en este dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Salir')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _perform(
      () => _client.auth.signOut(scope: SignOutScope.local),
      'Sesión cerrada.',
    );
  }

  Future<void> _withdrawMicrophone() async {
    reiniciarAvisoVoz();
    await _perform(
      () => const MethodChannel('jcv/settings').invokeMethod<void>('openAppSettings'),
      'En Permisos, desactiva el micrófono. La app volverá a mostrar el aviso antes de usarlo.',
    );
  }

  Future<void> _deleteAccount() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (!mounted || confirmed != true) return;
    await _perform(() async {
      await _client.functions.invoke('delete-account');
      await _client.auth.signOut(scope: SignOutScope.local);
    }, 'Cuenta eliminada.');
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(title: const Text('Tu cuenta'), foregroundColor: _blue, backgroundColor: Colors.white),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('CUENTA · JALISCO CÓMO VAMOS', style: TextStyle(color: _blue, fontSize: 12)),
              const SizedBox(height: 12),
              _card([
                const Icon(Icons.account_circle_outlined, color: _blue, size: 36),
                const SizedBox(height: 8),
                const Text('Correo de tu cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
                SelectableText(user?.email ?? 'Sin correo disponible'),
              ]),
              const SizedBox(height: 12),
              _card([
                const Text('Cambiar correo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _blue)),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Correo nuevo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _busy ? null : _changeEmail, child: const Text('Enviar confirmación')),
              ]),
              const SizedBox(height: 12),
              _card([
                const Text('Cambiar contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _blue)),
                const SizedBox(height: 12),
                TextField(controller: _currentPassword, enabled: !_busy, obscureText: true, enableSuggestions: false, autocorrect: false, decoration: const InputDecoration(labelText: 'Contraseña actual', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _newPassword, enabled: !_busy, obscureText: true, enableSuggestions: false, autocorrect: false, decoration: const InputDecoration(labelText: 'Contraseña nueva (mínimo 12 caracteres)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: _confirmPassword, enabled: !_busy, obscureText: true, enableSuggestions: false, autocorrect: false, decoration: const InputDecoration(labelText: 'Repite la contraseña nueva', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _busy ? null : _changePassword, child: const Text('Actualizar contraseña')),
              ]),
              const SizedBox(height: 12),
              _card([
                const Text('Tus datos y permisos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _blue)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _busy ? null : _withdrawMicrophone, child: const Text('Retirar permiso del micrófono')),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _busy ? null : _deleteAccount,
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB00020)),
                  child: const Text('Eliminar mi cuenta'),
                ),
              ]),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Color(0xFFB00020)))),
              if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, style: const TextStyle(color: _blue))),
              if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
              const SizedBox(height: 20),
              OutlinedButton.icon(onPressed: _busy ? null : _signOut, icon: const Icon(Icons.logout), label: const Text('Cerrar sesión')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Eliminar mi cuenta'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Se borran tu cuenta, tus accesos y tus respuestas. No se puede deshacer. '
          'Los registros de donaciones se conservan sin estar ligados a ti.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmation,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Escribe ELIMINAR', border: OutlineInputBorder()),
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
      TextButton(
        onPressed: _confirmation.text == 'ELIMINAR' ? () => Navigator.pop(context, true) : null,
        child: const Text('Eliminar'),
      ),
    ],
  );
}
