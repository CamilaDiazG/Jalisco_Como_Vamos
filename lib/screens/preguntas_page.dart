import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Una instancia por aplicación; los callbacks se redirigen a la pantalla activa.
class _Voz {
  static final speech = SpeechToText();
  static VoidCallback? actualizar;
  static ValueChanged<String>? error;
  // Se pide una vez por sesión de la app, antes del permiso del sistema.
  static bool avisoAceptado = false;
  static Future<bool> iniciar() => speech.initialize(
    onStatus: (_) => actualizar?.call(),
    onError: (_) =>
        error?.call('No se pudo reconocer la frase. Puedes escribirla.'),
  );
}

void reiniciarAvisoVoz() => _Voz.avisoAceptado = false;

class PreguntasPage extends StatefulWidget {
  const PreguntasPage({super.key, this.invoke});
  final Future<FunctionResponse> Function(String, Map<String, dynamic>)? invoke;
  @override
  State<PreguntasPage> createState() => _PreguntasPageState();
}

class _PreguntasPageState extends State<PreguntasPage>
    with WidgetsBindingObserver {
  final _texto = TextEditingController();
  bool _enviando = false;
  bool _iniciando = false;
  String? _respuesta;
  List<String> _fuentes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _Voz.actualizar = () {
      if (mounted) setState(() {});
    };
    _Voz.error = (mensaje) {
      if (mounted) setState(() => _error = mensaje);
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _Voz.speech.cancel();
  }

  Future<bool> _aceptarAvisoVoz() async {
    if (_Voz.avisoAceptado) return true;
    final acepto = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Aviso de privacidad del micrófono'),
        content: const Text(
          'Tu voz la recibe y la convierte en texto el servicio de voz de tu teléfono '
          '(normalmente Google), que puede procesarla en sus servidores.\n\n'
          'Jalisco Cómo Vamos no recibe ni guarda tu audio. Si pulsas "Enviar pregunta", '
          'el texto llega a nuestro servidor y a Gemini, de Google, para buscar la respuesta. '
          'No incluyas datos personales.\n\n'
          'Si no quieres usar el micrófono, puedes escribir tu pregunta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Prefiero escribir'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar y usar micrófono'),
          ),
        ],
      ),
    );
    _Voz.avisoAceptado = acepto == true;
    return _Voz.avisoAceptado;
  }

  Future<void> _escuchar() async {
    if (_Voz.speech.isListening) {
      await _Voz.speech.stop();
      return;
    }
    if (!await _aceptarAvisoVoz() || !mounted) return;
    setState(() {
      _iniciando = true;
      _error = null;
    });
    try {
      final disponible = await _Voz.iniciar();
      if (!mounted) return;
      if (!disponible) {
        setState(
          () => _error = 'Micrófono o reconocimiento no disponible. Revisa los permisos o escribe tu pregunta.',
        );
        return;
      }
      final idiomas = await _Voz.speech.locales();
      if (!mounted) return;
      final espanol = idiomas
          .where((l) => l.localeId.startsWith('es'))
          .toList();
      if (espanol.isEmpty) {
        setState(
          () => _error =
              'Instala reconocimiento en español o escribe tu pregunta.',
        );
        return;
      }
      await _Voz.speech.listen(
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
          localeId: espanol.first.localeId,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
        ),
        onResult: (r) {
          if (!mounted) return;
          final frase = r.recognizedWords;
          _texto.value = TextEditingValue(
            text: frase,
            selection: TextSelection.collapsed(offset: frase.length),
          );
          setState(() {});
        },
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No se pudo iniciar el micrófono. Puedes escribir la pregunta.',
        );
      }
    } finally {
      if (mounted) setState(() => _iniciando = false);
    }
  }

  Future<void> _enviar() async {
    if (_enviando || _iniciando || _Voz.speech.isListening) return;
    final pregunta = _texto.text.trim();
    if (pregunta.isEmpty || pregunta.length > 500) {
      setState(() => _error = 'Escribe una pregunta de 1 a 500 caracteres.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
      _respuesta = null;
      _fuentes = [];
    });
    try {
      final body = <String, dynamic>{
        'question': pregunta,
        'case_id': const Uuid().v4(),
      };
      final FunctionResponse result;
      if (widget.invoke != null) {
        result = await widget.invoke!('ask', body);
      } else {
        final client = Supabase.instance.client;
        if (client.auth.currentSession == null) {
          throw FunctionException(status: 401);
        }
        result = await client.functions.invoke('ask', body: body);
      }
      if (result.status != 200) throw FunctionException(status: result.status);
      final data = result.data;
      if (data is! Map ||
          data['answer'] is! String ||
          (data['answer'] as String).trim().isEmpty ||
          data['citations'] is! List ||
          data['retrieved_source_ids'] is! List) {
        throw const FormatException('Respuesta inválida');
      }
      final citations = data['citations'] as List;
      final retrieved = data['retrieved_source_ids'] as List;
      if (retrieved.any((id) => id is! String || id.trim().isEmpty) ||
          citations.any(
            (id) =>
                id is! String || id.trim().isEmpty || !retrieved.contains(id),
          )) {
        throw const FormatException('Fuentes inválidas');
      }
      if (mounted) {
        setState(() {
          _respuesta = data['answer'] as String;
          _fuentes = citations.cast<String>();
        });
      }
    } on FunctionException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.status == 401 || e.status == 403
              ? 'Tu sesión necesita acceso autorizado a los agregados.'
              : e.status == 429
              ? 'La cuota de IA está agotada temporalmente. Tu pregunta se conserva; intenta más tarde.'
              : 'No se pudo consultar. Reintenta; si persiste, falta configurar el servicio.',
        );
      }
    } on FormatException catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'El servicio devolvió una respuesta inválida. Intenta de nuevo.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo consultar. Revisa tu sesión y conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _Voz.actualizar = null;
    _Voz.error = null;
    _Voz.speech.cancel();
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pregúntale a los datos')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Consulta bienestar, felicidad, salud, educación, trabajo, seguridad, tiempo libre, hogar, comunidad o transporte. Ejemplo: ¿Cómo está la salud?',
        ),
        const SizedBox(height: 12),
        const Text(
          'Fuente: encuesta de juventudes 2026, total AMG. Esta consulta no admite Tec ni filtros por municipio, edad u otros subgrupos.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _texto,
          minLines: 2,
          maxLines: 5,
          maxLength: 500,
          enabled: !_enviando && !_Voz.speech.isListening,
          decoration: const InputDecoration(
            labelText: 'Pregunta o transcripción editable',
            border: OutlineInputBorder(),
          ),
        ),
        const Text(
          'Al pulsar el micrófono se escucha una frase. Revisa el texto antes de enviarlo. La app no guarda audio; el servicio de voz del dispositivo puede procesarlo en sus servidores. Al enviar, el texto llega a nuestro servidor y a Gemini, de Google. No incluyas datos personales.',
        ),
        Row(
          children: [
            IconButton(
              onPressed: _enviando || _iniciando ? null : _escuchar,
              tooltip: _Voz.speech.isListening
                  ? 'Detener escucha'
                  : 'Escuchar una frase',
              icon: Icon(_Voz.speech.isListening ? Icons.stop : Icons.mic),
            ),
            Expanded(
              child: FilledButton(
                onPressed: _enviando || _iniciando || _Voz.speech.isListening
                    ? null
                    : _enviar,
                child: Text(_enviando ? 'Consultando…' : 'Enviar pregunta'),
              ),
            ),
          ],
        ),
        if (_Voz.speech.isListening) const Text('Escuchando…'),
        if (_enviando)
          const LinearProgressIndicator(
            semanticsLabel: 'Consultando los datos',
          ),
        if (_error != null) Text(_error!, semanticsLabel: _error),
        if (_respuesta != null) SelectableText(_respuesta!),
        if (_respuesta != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Fuentes citadas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_fuentes.isEmpty)
            const Text('Sin fuentes citadas para esta respuesta.'),
          for (final fuente in _fuentes) SelectableText(fuente),
        ],
      ],
    ),
  );
}
