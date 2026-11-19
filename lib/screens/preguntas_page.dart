import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Una instancia por aplicación; los callbacks se redirigen a la pantalla activa.
class _Voz {
  static final speech = SpeechToText();
  static VoidCallback? actualizar;
  static ValueChanged<String>? error;
  static Future<bool> iniciar() => speech.initialize(
    onStatus: (_) => actualizar?.call(),
    onError: (_) => error?.call('No se pudo reconocer la frase. Puedes escribirla.'),
  );
}

class PreguntasPage extends StatefulWidget {
  const PreguntasPage({super.key});
  @override
  State<PreguntasPage> createState() => _PreguntasPageState();
}

class _PreguntasPageState extends State<PreguntasPage> with WidgetsBindingObserver {
  final _texto = TextEditingController();
  bool _enviando = false;
  bool _iniciando = false;
  String _fuente = 'AMG';
  String? _respuesta;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _Voz.actualizar = () { if (mounted) setState(() {}); };
    _Voz.error = (mensaje) { if (mounted) setState(() => _error = mensaje); };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _Voz.speech.cancel();
  }

  Future<void> _escuchar() async {
    if (_Voz.speech.isListening) { await _Voz.speech.stop(); return; }
    setState(() { _iniciando = true; _error = null; });
    try {
      final disponible = await _Voz.iniciar();
      if (!mounted) return;
      if (!disponible) {
        setState(() => _error = 'Micrófono o reconocimiento no disponible. Revisa los permisos o escribe tu pregunta.');
        return;
      }
      final idiomas = await _Voz.speech.locales();
      if (!mounted) return;
      final espanol = idiomas.where((l) => l.localeId.startsWith('es')).toList();
      if (espanol.isEmpty) {
        setState(() => _error = 'Instala reconocimiento en español o escribe tu pregunta.');
        return;
      }
      await _Voz.speech.listen(
        localeId: espanol.first.localeId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(cancelOnError: true, listenMode: ListenMode.confirmation),
        onResult: (r) {
          if (!mounted) return;
          final frase = r.recognizedWords;
          _texto.value = TextEditingValue(text: frase, selection: TextSelection.collapsed(offset: frase.length));
          setState(() {});
        },
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo iniciar el micrófono. Puedes escribir la pregunta.');
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  Future<void> _enviar() async {
    final pregunta = _texto.text.trim();
    if (pregunta.isEmpty || pregunta.length > 500) {
      setState(() => _error = 'Escribe una pregunta de 1 a 500 caracteres.');
      return;
    }
    setState(() { _enviando = true; _error = null; _respuesta = null; });
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession == null) throw StateError('Sesión requerida');
      final result = await client.functions.invoke('ask-data', body: {
        'pregunta': pregunta, 'fuente': _fuente,
      });
      if (mounted) setState(() => _respuesta = (result.data as Map)['respuesta'] as String);
    } on FunctionException catch (e) {
      if (mounted) setState(() => _error = e.status == 401 || e.status == 403
        ? 'Tu sesión necesita acceso autorizado a los agregados.'
        : 'No se pudo consultar. Reintenta; si persiste, falta configurar el servicio.');
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo consultar. Revisa tu sesión y conexión.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _Voz.actualizar = null; _Voz.error = null;
    _Voz.speech.cancel(); _texto.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pregúntale a los datos')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Consulta bienestar, felicidad, salud, educación, trabajo, seguridad, tiempo libre, hogar, comunidad o transporte. Ejemplo: ¿Cómo está la salud?'),
      const SizedBox(height: 12),
      SegmentedButton<String>(segments: const [
        ButtonSegment(value: 'AMG', label: Text('AMG')),
        ButtonSegment(value: 'TEC', label: Text('Tec')),
      ], selected: {_fuente}, onSelectionChanged: _enviando ? null : (v) => setState(() { _fuente = v.single; _respuesta = null; })),
      const SizedBox(height: 12),
      TextField(controller: _texto, minLines: 2, maxLines: 5, maxLength: 500,
        enabled: !_enviando && !_Voz.speech.isListening,
        decoration: const InputDecoration(labelText: 'Pregunta o transcripción editable', border: OutlineInputBorder())),
      const Text('Al pulsar el micrófono se escucha una frase. Revisa el texto antes de enviarlo. La app no guarda audio; el servicio de voz del dispositivo puede procesarlo en sus servidores.'),
      Row(children: [
        IconButton(onPressed: _enviando || _iniciando ? null : _escuchar,
          tooltip: _Voz.speech.isListening ? 'Detener escucha' : 'Escuchar una frase',
          icon: Icon(_Voz.speech.isListening ? Icons.stop : Icons.mic)),
        Expanded(child: FilledButton(onPressed: _enviando || _iniciando || _Voz.speech.isListening ? null : _enviar,
          child: Text(_enviando ? 'Consultando…' : 'Enviar pregunta'))),
      ]),
      if (_Voz.speech.isListening) const Text('Escuchando…'),
      if (_error != null) Text(_error!, semanticsLabel: _error),
      if (_respuesta != null) SelectableText(_respuesta!),
    ]),
  );
}
