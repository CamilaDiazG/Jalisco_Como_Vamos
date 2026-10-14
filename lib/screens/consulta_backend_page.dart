import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/jcv_api.dart';

/// Pantalla de comprobación de la integración. Solo muestra consultas reales.
class ConsultaBackendPage extends StatefulWidget {
  const ConsultaBackendPage({super.key});

  @override
  State<ConsultaBackendPage> createState() => _ConsultaBackendPageState();
}

class _ConsultaBackendPageState extends State<ConsultaBackendPage> {
  static const _azul = Color(0xFF003E79);
  late final JcvApi _api;
  late Future<_ResultadoConsulta> _consulta;
  int _municipio = 0;
  int _grupoEdad = 0;
  bool _cerrandoSesion = false;

  @override
  void initState() {
    super.initState();
    _api = JcvApi(Supabase.instance.client);
    _consulta = _cargar();
  }

  Future<_ResultadoConsulta> _cargar() async {
    // Capturamos los filtros antes del await para mantener coherente cada solicitud.
    final municipio = _municipio == 0 ? null : _municipio;
    final grupoEdad = _grupoEdad == 0 ? null : _grupoEdad;
    final catalogos = await _api.catalogos();

    // ESTE es el lugar donde va el fragmento con "await api.resumen(...)".
    final indicadores = await _api.resumen(
      fuente: 'AMG',
      municipio: municipio,
      grupoEdad: grupoEdad,
    );
    return _ResultadoConsulta(catalogos, indicadores);
  }

  void _recargar() => setState(() => _consulta = _cargar());

  Future<void> _salir() async {
    if (_cerrandoSesion) return;
    setState(() => _cerrandoSesion = true);
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      // AuthGate vuelve automáticamente a LoginPage.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cerrar la sesión. Intenta nuevamente.')),
      );
    } finally {
      if (mounted) setState(() => _cerrandoSesion = false);
    }
  }

  Widget _selector({
    required String label,
    required int valor,
    required List<dynamic> opciones,
    required String todos,
    required ValueChanged<int> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: valor,
          isExpanded: true,
          isDense: true,
          items: [
            DropdownMenuItem(value: 0, child: Text(todos)),
            for (final opcion in opciones)
              DropdownMenuItem<int>(
                value: (opcion['codigo'] as num).toInt(),
                child: Text(opcion['nombre'] as String, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  String _mensajeError(Object? error) {
    if (error is PostgrestException) {
      if (error.code == '42501') {
        return 'La sesión se inició, pero esta cuenta no tiene permiso para consultar '
            'los resultados. Comprueba que su UUID esté autorizado en lectores.';
      }
      return 'No se pudo consultar la base: ${error.message}';
    }
    return 'No se pudieron cargar los resultados. Revisa la conexión y vuelve a intentar.';
  }

  String _titulo(String indicador) {
    switch (indicador) {
      case 'satisfaccion_vida': return 'Satisfacción con la vida';
      case 'felicidad': return 'Felicidad';
      case 'salud_mental': return 'Salud mental';
      default: return indicador;
    }
  }

  Widget _tarjeta(IndicadorJcv indicador) {
    final disponible = indicador.tieneDato;
    final explicacion = disponible
        ? indicador.etiquetaPositiva
        : indicador.estado == 'muestra_insuficiente'
            ? 'El grupo no alcanza el mínimo de respuestas válidas para mostrar el porcentaje.'
            : 'No hay datos para esta selección.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_titulo(indicador.indicador), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _azul)),
          const SizedBox(height: 8),
          Text(
            disponible ? '${indicador.porcentaje!.toStringAsFixed(2)}%' : '—',
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: _azul),
          ),
          const SizedBox(height: 4),
          Text(explicacion),
          const SizedBox(height: 12),
          Text('${indicador.nMuestra} cuestionarios · ${indicador.nValidas} respuestas válidas', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Resultados de la encuesta'),
        actions: [
          IconButton(tooltip: 'Actualizar resultados', onPressed: _recargar, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Cerrar sesión', onPressed: _cerrandoSesion ? null : _salir, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FutureBuilder<_ResultadoConsulta>(
            future: _consulta,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Icon(Icons.info_outline, size: 40, color: _azul),
                    const SizedBox(height: 16),
                    Text(_mensajeError(snapshot.error)),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _recargar, child: const Text('Reintentar')),
                  ],
                );
              }
              final resultado = snapshot.data;
              if (resultado == null) return const Center(child: Text('Sin resultados disponibles.'));

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Bienestar de jóvenes · AMG 2026', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _azul)),
                  const SizedBox(height: 8),
                  const Text('Resultados reales de la base de la encuesta.'),
                  const SizedBox(height: 24),
                  _selector(
                    label: 'Municipio', valor: _municipio, todos: 'Todo el AMG',
                    opciones: resultado.catalogos['municipios'] as List,
                    onChanged: (value) => setState(() {
                      _municipio = value;
                      _consulta = _cargar();
                    }),
                  ),
                  const SizedBox(height: 16),
                  _selector(
                    label: 'Edad', valor: _grupoEdad, todos: 'Todas las edades (15–29)',
                    opciones: resultado.catalogos['grupos_edad'] as List,
                    onChanged: (value) => setState(() {
                      _grupoEdad = value;
                      _consulta = _cargar();
                    }),
                  ),
                  const SizedBox(height: 20),
                  for (final indicador in resultado.indicadores) _tarjeta(indicador),
                  const SizedBox(height: 8),
                  const Text('Porcentajes ponderados sobre el total seleccionado, incluyendo no respuesta en el denominador.', style: TextStyle(fontSize: 12)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ResultadoConsulta {
  final Map<String, dynamic> catalogos;
  final List<IndicadorJcv> indicadores;
  const _ResultadoConsulta(this.catalogos, this.indicadores);
}
