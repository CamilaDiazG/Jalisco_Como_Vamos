import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/jcv_api.dart';

/// Se integra en el dashboard; conserva su cabecera, filtros y navegación.
class DimensionContenido extends StatefulWidget {
  final JcvApi api;
  final String dimension;
  final String fuente;
  final int? municipio;
  final int? grupoEdad;

  const DimensionContenido({
    super.key,
    required this.api,
    required this.dimension,
    required this.fuente,
    this.municipio,
    this.grupoEdad,
  });

  @override
  State<DimensionContenido> createState() => _DimensionContenidoState();
}

class _DimensionContenidoState extends State<DimensionContenido> {
  late Future<List<DimensionDetalle>> _consulta;

  @override
  void initState() {
    super.initState();
    _consulta = _cargar();
  }

  Future<List<DimensionDetalle>> _cargar() => Future.wait(
    (widget.fuente == 'COMPARAR' ? ['AMG', 'TEC'] : [widget.fuente]).map(
          (fuente) => widget.api.dimension(
        dimension: widget.dimension,
        fuente: fuente,
        municipio: widget.municipio,
        grupoEdad: widget.grupoEdad,
      ),
    ),
  );

  @override
  void didUpdateWidget(covariant DimensionContenido oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.api != oldWidget.api ||
        widget.dimension != oldWidget.dimension ||
        widget.fuente != oldWidget.fuente ||
        widget.municipio != oldWidget.municipio ||
        widget.grupoEdad != oldWidget.grupoEdad) {
      _consulta = _cargar();
    }
  }

  void _reintentar() => setState(() => _consulta = _cargar());

  @override
  Widget build(BuildContext context) => FutureBuilder<List<DimensionDetalle>>(
    key: ObjectKey(_consulta),
    future: _consulta,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        final sinPermiso = error is PostgrestException && error.code == '42501';
        final sinInstalar =
            error is PostgrestException && error.code == 'PGRST202';
        return _Mensaje(
          titulo: sinPermiso
              ? 'Tu cuenta aún no tiene acceso'
              : sinInstalar
              ? 'Esta dimensión aún no está conectada'
              : 'No se pudieron cargar los resultados',
          texto: sinPermiso
              ? 'La cuenta necesita autorización para consultar la encuesta.'
              : sinInstalar
              ? 'Esta dimensión estará disponible cuando se complete su configuración.'
              : 'Revisa tu conexión y vuelve a intentarlo.',
          reintentar: _reintentar,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final detalle in snapshot.data!) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${detalle.nombre} · ${detalle.fuente == 'TEC' ? 'Tec' : 'AMG'}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (detalle.preguntas.isEmpty ||
                detalle.preguntas.every((p) => p.estado == 'sin_datos'))
              _Mensaje(
                titulo: detalle.fuente == 'TEC'
                    ? 'Todavía no hay datos Tec de ${detalle.nombre}'
                    : 'Sin respuestas para esta selección',
                texto: 'Prueba con otros filtros o consulta los resultados del AMG.',
              )
            else
              for (final pregunta in detalle.preguntas)
                _TarjetaPregunta(pregunta: pregunta),
            const SizedBox(height: 12),
          ],
          Text(
            'Los porcentajes incluyen No sabe/No contestó. '
                'AMG utiliza el factor de expansión de la encuesta. '
                '${widget.dimension == 'educacion_trabajo'
                ? 'Las actividades de estudio y trabajo pueden coincidir en una persona. No aplica también permanece en el denominador. '
                : ''}'
                '${widget.dimension == 'seguridad'
                ? 'Estos resultados describen percepciones, no tasas reales de delitos. '
                : ''}'
                '${widget.dimension == 'transporte'
                ? 'No se desplaza se conserva como una categoría visible del tiempo de traslado. '
                : ''}'
                'No se calcula un índice ni se muestran respuestas individuales.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (widget.fuente == 'COMPARAR')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Tec describe a quienes participan. No equivale a una muestra representativa del AMG.',
              ),
            ),
        ],
      );
    },
  );
}

class _TarjetaPregunta extends StatelessWidget {
  final PreguntaDistribucion pregunta;
  const _TarjetaPregunta({required this.pregunta});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pregunta.titulo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cómo se calcula: ${pregunta.titulo}',
                icon: Icon(Icons.info_outline, size: 19, color: scheme.primary),
                onPressed: () => showDialog<void>(
                  context: context,
                  useRootNavigator: false,
                  builder: (context) => AlertDialog(
                    title: Text(pregunta.titulo),
                    content: SingleChildScrollView(
                      child: Text(
                        'Variable: ${pregunta.variable}\n'
                            'Fuente: ${pregunta.fuente}\n'
                            'Versión: ${pregunta.versionMetodologia}\n\n'
                            '${pregunta.denominador}\n\n'
                            '${pregunta.ponderado ? 'Cada categoría suma FACTOR y divide entre el peso total seleccionado.' : 'Cada respuesta tiene peso 1.'}\n\n'
                            'Se requieren al menos ${pregunta.minimoValidas} respuestas válidas. '
                            'Este umbral inicial no garantiza anonimato ni precisión estadística.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!pregunta.publicable)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                pregunta.estado == 'muestra_insuficiente'
                    ? 'Muestra insuficiente: no se publican porcentajes con menos de ${pregunta.minimoValidas} respuestas válidas.'
                    : 'Sin respuestas disponibles.',
              ),
            )
          else
            for (final categoria in pregunta.categorias) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      categoria.etiqueta,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${categoria.porcentaje!.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Semantics(
                label:
                '${categoria.etiqueta}: ${categoria.porcentaje!.toStringAsFixed(2)} por ciento',
                child: ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: categoria.porcentaje! / 100,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(8),
                    color: categoria.esAusencia
                        ? scheme.outline
                        : scheme.primary,
                    backgroundColor: scheme.primary.withValues(alpha: .09),
                  ),
                ),
              ),
            ],
          const SizedBox(height: 14),
          Text(
            '${pregunta.nMuestra} cuestionarios · ${pregunta.nValidas} respuestas válidas',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  final String titulo;
  final String texto;
  final VoidCallback? reintentar;
  const _Mensaje({required this.titulo, required this.texto, this.reintentar});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(texto),
          if (reintentar != null)
            TextButton(onPressed: reintentar, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
