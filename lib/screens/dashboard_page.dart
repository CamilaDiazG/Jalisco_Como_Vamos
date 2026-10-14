import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/jcv_api.dart';

abstract class Marca {
  static const azul = Color(0xFF003E79);
  static const rojo = Color(0xFFED1849);
  static const amarillo = Color(0xFFFFC425);
  static const lima = Color(0xFFD5E04D);
  static const naranja = Color(0xFFF8981D);

  static const fondo = Color(0xFFF4F6F9);
  static const secundario = Color(0xFF596B80);
  static const borde = Color(0xFFDBE3EC);
  static const azulClaro = Color(0xFFE8EFF7);
  static const amarilloClaro = Color(0xFFFFF5D2);
}

TextStyle estilo(
  double size, {
  FontWeight peso = FontWeight.w400,
  Color color = Marca.azul,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: peso,
    color: color,
    height: 1.35,
  );
}

// ------------------------------------------------------------
// FILTROS Y RESULTADOS DE LA ENCUESTA
// ------------------------------------------------------------

enum Fuente { amg, tec, comparar }

extension FuenteNombre on Fuente {
  String get nombre {
    switch (this) {
      case Fuente.amg:
        return 'AMG';
      case Fuente.tec:
        return 'Tec';
      case Fuente.comparar:
        return 'Comparar';
    }
  }
}

class Filtros {
  final Fuente fuente;
  final String municipio;
  final String edad;
  final String tema;

  const Filtros({
    this.fuente = Fuente.amg,
    this.municipio = 'Todo el AMG',
    this.edad = 'Todos',
    this.tema = 'Bienestar subjetivo',
  });

  Filtros copyWith({
    Fuente? fuente,
    String? municipio,
    String? edad,
    String? tema,
  }) {
    return Filtros(
      fuente: fuente ?? this.fuente,
      municipio: municipio ?? this.municipio,
      edad: edad ?? this.edad,
      tema: tema ?? this.tema,
    );
  }

  String get edadVisible => edad == 'Todos' ? '15–29 años' : '$edad años';
}

const temas = [
  'Bienestar subjetivo',
  'Educación y trabajo',
  'Salud',
  'Seguridad',
  'Tiempo libre',
  'Hogar y familia',
  'Comunidad',
  'Transporte',
];

// ------------------------------------------------------------
// CABECERA Y COMPONENTES COMPARTIDOS
// ------------------------------------------------------------

void mostrarAviso(BuildContext context, String titulo, String mensaje) {
  showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

PreferredSizeWidget cabecera(BuildContext context, {bool volver = false}) {
  return AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    toolbarHeight: 64,
    titleSpacing: volver ? 0 : 20,
    leading: volver
        ? IconButton(
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back, color: Marca.azul),
            onPressed: () => Navigator.pop(context),
          )
        : null,
    title: Image.asset(
      'assets/images/logo_jaliscocomovamos.png',
      width: 146,
      height: 52,
      fit: BoxFit.contain,
      semanticLabel: 'Jalisco Cómo Vamos, observatorio ciudadano',
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 16),
        child: IconButton(
          tooltip: 'Perfil',
          style: IconButton.styleFrom(backgroundColor: Marca.azulClaro),
          icon: const Icon(Icons.person_outline, color: Marca.azul),
          onPressed: () => mostrarPerfil(context),
        ),
      ),
    ],
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(4),
      child: FranjaMarca(),
    ),
  );
}

class FranjaMarca extends StatelessWidget {
  const FranjaMarca({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 4,
      child: Row(
        children: [
          Expanded(flex: 9, child: ColoredBox(color: Marca.rojo)),
          Expanded(flex: 2, child: ColoredBox(color: Marca.naranja)),
          Expanded(flex: 11, child: ColoredBox(color: Marca.amarillo)),
          Expanded(flex: 9, child: ColoredBox(color: Marca.lima)),
          Expanded(flex: 2, child: ColoredBox(color: Marca.borde)),
          Expanded(flex: 10, child: ColoredBox(color: Marca.azul)),
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class TituloPagina extends StatelessWidget {
  final String etiqueta;
  final String titulo;

  const TituloPagina({super.key, required this.etiqueta, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: estilo(11, color: Marca.secundario)),
        const SizedBox(height: 6),
        Text(titulo, style: estilo(22, peso: FontWeight.w700)),
      ],
    );
  }
}

class SelectorFuente extends StatelessWidget {
  final Fuente value;
  final ValueChanged<Fuente> onChanged;

  const SelectorFuente({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Marca.azulClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: Fuente.values.map((fuente) {
          final seleccionada = fuente == value;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: seleccionada ? Marca.azul : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onChanged(fuente),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      fuente.nombre,
                      textAlign: TextAlign.center,
                      style: estilo(
                        13,
                        peso: FontWeight.w600,
                        color: seleccionada ? Colors.white : Marca.azul,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class NotaDatos extends StatelessWidget {
  final Indicadores indicadores;
  const NotaDatos({super.key, required this.indicadores});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${indicadores.ponderado ? 'Resultados ponderados' : 'Respuestas de participantes'}'
      ' · ${indicadores.nMuestra} cuestionarios.\n'
      'Porcentajes sobre el total, incluyendo NS/NC.'
      '${indicadores.tieneMuestraInsuficiente ? '\n—: muestra insuficiente para publicar este porcentaje.' : ''}',
      style: estilo(11, color: Marca.secundario),
    );
  }
}

class EstadoConsulta extends StatelessWidget {
  final String titulo;
  final String mensaje;
  final VoidCallback? reintentar;
  final String etiquetaAccion;
  const EstadoConsulta({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.reintentar,
    this.etiquetaAccion = 'Reintentar',
  });

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.query_stats, size: 36, color: Marca.azul),
        const SizedBox(height: 12),
        Text(titulo, style: estilo(17, peso: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(mensaje, style: estilo(13, color: Marca.secundario)),
        if (reintentar != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: reintentar, child: Text(etiquetaAccion)),
        ],
      ],
    ),
  );
}

Future<void> mostrarPerfil(BuildContext context) async {
  final salir = await showDialog<bool>(
    context: context,
    useRootNavigator: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Tu cuenta'),
      content: Text(
        Supabase.instance.client.auth.currentUser?.email ?? 'Sesión iniciada',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Volver'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (salir != true || !context.mounted) return;
  try {
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo cerrar sesión. Intenta nuevamente.'),
      ),
    );
  }
}

// ------------------------------------------------------------
// DASHBOARD PRINCIPAL
// ------------------------------------------------------------

class DashboardPage extends StatefulWidget {
  final JcvApi? api;
  const DashboardPage({super.key, this.api});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Filtros _filtros = const Filtros();
  late final JcvApi _api;
  CatalogosJcv? _catalogos;
  late Future<ResumenEncuesta> _consulta;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? JcvApi(Supabase.instance.client);
    _consulta = _cargar(_filtros);
  }

  Future<ResumenEncuesta> _cargar(Filtros filtros) async {
    if (filtros.tema != 'Bienestar subjetivo') return const ResumenEncuesta();
    final catalogos =
        _catalogos ?? CatalogosJcv.fromJson(await _api.catalogos());
    // Esta caché pertenece exclusivamente al dashboard de la sesión actual.
    if (!mounted) return const ResumenEncuesta();
    _catalogos = catalogos;
    final municipio = filtros.municipio == 'Todo el AMG'
        ? null
        : catalogos.codigoMunicipio(filtros.municipio);
    final grupoEdad = filtros.edad == 'Todos'
        ? null
        : catalogos.codigoEdad(filtros.edad);

    Future<Indicadores> consultar(String fuente) async => Indicadores(
      await _api.resumen(
        fuente: fuente,
        municipio: municipio,
        grupoEdad: grupoEdad,
      ),
    );
    if (filtros.fuente == Fuente.comparar) {
      final resultados = await Future.wait([
        consultar('AMG'),
        consultar('TEC'),
      ]);
      return ResumenEncuesta(amg: resultados[0], tec: resultados[1]);
    }
    if (filtros.fuente == Fuente.tec)
      return ResumenEncuesta(tec: await consultar('TEC'));
    return ResumenEncuesta(amg: await consultar('AMG'));
  }

  void _actualizar(Filtros filtros) {
    setState(() {
      _filtros = filtros;
      _consulta = _cargar(filtros);
    });
  }

  Future<void> _abrirFiltros({String? tema}) async {
    final catalogos = _catalogos;
    if (catalogos == null) {
      mostrarAviso(
        context,
        'Filtros',
        'Espera a que cargue el catálogo. Si ocurrió un error, pulsa Reintentar.',
      );
      return;
    }
    final resultado = await Navigator.push<Filtros>(
      context,
      MaterialPageRoute(
        builder: (_) => FiltrosPage(
          initial: _filtros.copyWith(tema: tema),
          catalogos: catalogos,
        ),
      ),
    );
    if (!mounted || resultado == null) return;
    _actualizar(resultado);
  }

  void _cambiarFuente(Fuente fuente) =>
      _actualizar(_filtros.copyWith(fuente: fuente));

  Widget _contenido() {
    if (_filtros.tema != 'Bienestar subjetivo') {
      return EstadoConsulta(
        titulo: 'Esta dimensión aún no está disponible',
        etiquetaAccion: 'Ver bienestar subjetivo',
        mensaje: 'Por ahora están conectados satisfacción con la vida, felicidad y salud mental, en Bienestar subjetivo.',
        reintentar: () =>
            _actualizar(_filtros.copyWith(tema: 'Bienestar subjetivo')),
      );
    }
    return FutureBuilder<ResumenEncuesta>(
      // Impide mostrar resultados de filtros anteriores durante una nueva consulta.
      key: ObjectKey(_consulta),
      future: _consulta,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Panel(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: Marca.azul),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final sinPermiso =
              error is PostgrestException && error.code == '42501';
          return EstadoConsulta(
            titulo: sinPermiso
                ? 'Tu cuenta aún no tiene acceso'
                : 'No se pudieron cargar los resultados',
            mensaje: sinPermiso
                ? 'La sesión está iniciada, pero esta cuenta necesita autorización para consultar la encuesta.'
                : 'Revisa tu conexión y vuelve a intentarlo.',
            reintentar: () => _actualizar(_filtros),
          );
        }
        final resumen = snapshot.data!;
        if (_filtros.fuente == Fuente.comparar)
          return ComparacionContenido(resumen: resumen);
        final indicadores = _filtros.fuente == Fuente.tec
            ? resumen.tec!
            : resumen.amg!;
        if (indicadores.nMuestra == 0) {
          return EstadoConsulta(
            titulo: _filtros.fuente == Fuente.tec
                ? 'La encuesta Tec aún no tiene datos para esta selección'
                : 'Sin respuestas para esta selección',
            mensaje: 'Prueba con otros filtros. Los resultados aparecerán cuando existan respuestas disponibles.',
          );
        }
        return ResumenContenido(indicadores: indicadores);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final comparar = _filtros.fuente == Fuente.comparar;

    return Scaffold(
      appBar: cabecera(context),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TituloPagina(
                etiqueta: comparar
                    ? 'DOS COMUNIDADES · UNA CONVERSACIÓN'
                    : 'ENCUESTA DE BIENESTAR · 2026',
                titulo: comparar
                    ? 'Dos miradas,\nun mismo territorio.'
                    : _filtros.fuente == Fuente.tec
                    ? '¿Cómo vive\nla comunidad Tec?'
                    : '¿Cómo viven\nlas juventudes del AMG?',
              ),
              const SizedBox(height: 16),
              SelectorFuente(value: _filtros.fuente, onChanged: _cambiarFuente),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _abrirFiltros(),
                      child: Text(
                        _filtros.municipio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: estilo(12, peso: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _abrirFiltros(),
                      child: Text(
                        _filtros.edadVisible,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: estilo(12, peso: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => _abrirFiltros(),
                      child: const Icon(Icons.tune, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _contenido(),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _actualizar(_filtros),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar'),
                ),
              ),
              if (!comparar) ...[
                const SizedBox(height: 12),
                Material(
                  color: Marca.azulClaro,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => mostrarAviso(
                      context,
                      'Consulta por voz',
                      'Este acceso está listo en la interfaz. '
                          'Falta conectar reconocimiento de voz y el servicio de IA.',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: Marca.azul,
                            child: Icon(Icons.mic_none, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pregúntale a los datos',
                                  style: estilo(13, peso: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Consulta el bienestar por voz',
                                  style: estilo(12, color: Marca.secundario),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Explora otras dimensiones',
                  style: estilo(13, peso: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Salud', 'Seguridad', 'Transporte']
                      .map(
                        (tema) => OutlinedButton(
                          onPressed: () => _abrirFiltros(tema: tema),
                          child: Text(tema, style: estilo(12)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: comparar ? 1 : 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Marca.amarilloClaro,
        elevation: 0,
        height: 76,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              _cambiarFuente(Fuente.amg);
              break;
            case 1:
              _cambiarFuente(Fuente.comparar);
              break;
            case 2:
              mostrarAviso(
                context,
                'Participa',
                'El módulo de encuesta Tec está pendiente de integración.',
              );
              break;
            case 3:
              mostrarAviso(
                context,
                'Apoya al observatorio',
                'La pasarela de donativos está pendiente de integración.',
              );
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Marca.azul),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart, color: Marca.azul),
            label: 'Comparar',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined, color: Marca.azul),
            label: 'Participa',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border, color: Marca.azul),
            label: 'Apoya',
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// RESUMEN Y GRÁFICA CIRCULAR
// ------------------------------------------------------------

class ResumenContenido extends StatelessWidget {
  final Indicadores indicadores;

  const ResumenContenido({super.key, required this.indicadores});

  @override
  Widget build(BuildContext context) {
    final lectura = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Satisfacción\ncon la vida',
          style: estilo(17, peso: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          indicadores.filas[0].etiquetaPositiva,
          style: estilo(12, color: Marca.secundario),
        ),
      ],
    );

    final grafica = Semantics(
      label:
          'Satisfacción con la vida: ${indicadores.satisfaccion == null ? 'porcentaje no disponible' : porcentaje(indicadores.satisfaccion)}',
      child: SizedBox(
        width: 132,
        height: 132,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CircularProgressIndicator(
                semanticsValue: indicadores.satisfaccion == null
                    ? 'Porcentaje no disponible'
                    : porcentaje(indicadores.satisfaccion),
                value:
                    (indicadores.satisfaccion ?? 0) /
                    100, // Sin dato: anillo vacío, texto —.
                strokeWidth: 14,
                color: Marca.amarillo,
                backgroundColor: Marca.azulClaro,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 106,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      porcentaje(indicadores.satisfaccion),
                      style: estilo(28, peso: FontWeight.w700),
                    ),
                  ),
                ),
                Text(
                  'satisfacción',
                  style: estilo(10, color: Marca.secundario),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Column(
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bienestar subjetivo',
                      style: estilo(17, peso: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Acerca del indicador',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.info_outline,
                      size: 19,
                      color: Marca.azul,
                    ),
                    onPressed: () => mostrarAviso(
                      context,
                      'Satisfacción con la vida',
                      'Respuestas Algo o Muy satisfecha/o (códigos 4 y 5). '
                          'El porcentaje se calcula sobre el total seleccionado, incluyendo NS/NC. '
                          'AMG utiliza el factor de expansión de la encuesta. ',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 300) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: grafica),
                        const SizedBox(height: 20),
                        lectura,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      grafica,
                      const SizedBox(width: 22),
                      Expanded(child: lectura),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              NotaDatos(indicadores: indicadores),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TarjetaIndicador(
                titulo: 'Felicidad',
                valor: indicadores.felicidad,
                descripcion: indicadores.filas[1].etiquetaPositiva,
                nValidas: indicadores.filas[1].nValidas,
                acento: Marca.amarillo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TarjetaIndicador(
                titulo: 'Salud mental',
                valor: indicadores.saludMental,
                descripcion: indicadores.filas[2].etiquetaPositiva,
                nValidas: indicadores.filas[2].nValidas,
                acento: Marca.rojo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TarjetaIndicador extends StatelessWidget {
  final String titulo;
  final double? valor;
  final int nValidas;
  final String descripcion;
  final Color acento;

  const TarjetaIndicador({
    super.key,
    required this.titulo,
    required this.valor,
    required this.descripcion,
    required this.nValidas,
    required this.acento,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: acento,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(titulo, style: estilo(12, peso: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(porcentaje(valor), style: estilo(28, peso: FontWeight.w700)),
          Text(
            '$descripcion\n$nValidas respuestas válidas${valor == null ? '\nPorcentaje no disponible' : ''}',
            style: estilo(11, color: Marca.secundario),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// COMPARACIÓN AMG–TEC
// ------------------------------------------------------------

class ComparacionContenido extends StatelessWidget {
  final ResumenEncuesta resumen;
  const ComparacionContenido({super.key, required this.resumen});

  @override
  Widget build(BuildContext context) {
    const titulos = ['Satisfacción con la vida', 'Felicidad', 'Salud mental'];
    final amg = resumen.amg!;
    final tec = resumen.tec!;
    final satisfaccionAmg = amg.satisfaccion;
    final satisfaccionTec = tec.satisfaccion;
    final diferencia = satisfaccionAmg == null || satisfaccionTec == null
        ? null
        : satisfaccionTec - satisfaccionAmg;

    return Column(
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AMG y comunidad Tec',
                style: estilo(17, peso: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Porcentaje de respuestas positivas',
                style: estilo(11, color: Marca.secundario),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Leyenda(nombre: 'AMG', color: Marca.amarillo),
                  SizedBox(width: 28),
                  Leyenda(nombre: 'Tec', color: Marca.rojo),
                ],
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < titulos.length; i++) ...[
                Text(titulos[i], style: estilo(12)),
                const SizedBox(height: 8),
                BarraDato(
                  fuente: 'AMG',
                  valor: amg.valores[i],
                  color: Marca.amarillo,
                ),
                const SizedBox(height: 6),
                BarraDato(
                  fuente: 'Tec',
                  valor: tec.valores[i],
                  color: Marca.rojo,
                ),
                const SizedBox(height: 18),
              ],
              Text(
                'AMG: ${amg.nMuestra} cuestionarios · Tec: ${tec.nMuestra} cuestionarios',
                style: estilo(11, color: Marca.secundario),
              ),
              if (tec.nMuestra == 0 || amg.nMuestra == 0) ...[
                const SizedBox(height: 8),
                Text(
                  '—: no hay respuestas de esa fuente para esta selección.',
                  style: estilo(11, color: Marca.secundario),
                ),
              ],
              if (tec.tieneMuestraInsuficiente ||
                  amg.tieneMuestraInsuficiente) ...[
                const SizedBox(height: 8),
                Text(
                  '—: muestra insuficiente para publicar el porcentaje.',
                  style: estilo(11, color: Marca.secundario),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          color: Marca.amarilloClaro,
          child: Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    diferencia == null
                        ? '—'
                        : '${diferencia >= 0 ? '+' : ''}${diferencia.toStringAsFixed(2)}',
                    style: estilo(30, peso: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'puntos porcentuales',
                      style: estilo(13, peso: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      diferencia == null
                          ? 'Se necesitan resultados disponibles de ambas fuentes para calcular la diferencia.'
                          : 'en satisfacción con la vida (Tec vs. AMG).',
                      style: estilo(11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          color: Marca.azulClaro,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compara con contexto',
                style: estilo(13, peso: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'AMG utiliza porcentajes ponderados. Tec describe a quienes participan; '
                'no representa a toda la comunidad. Ambos porcentajes incluyen NS/NC en el total.',
                style: estilo(11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Leyenda extends StatelessWidget {
  final String nombre;
  final Color color;

  const Leyenda({super.key, required this.nombre, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(nombre, style: estilo(11)),
      ],
    );
  }
}

class BarraDato extends StatelessWidget {
  final String fuente;
  final double? valor;
  final Color color;

  const BarraDato({
    super.key,
    required this.fuente,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '$fuente: ${valor == null ? 'porcentaje no disponible' : porcentaje(valor)}',
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 10,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Marca.fondo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FractionallySizedBox(
                widthFactor:
                    (valor ?? 0) / 100, // Sin dato: barra vacía, texto —.
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(porcentaje(valor), style: estilo(11)),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// PANTALLA DE FILTROS
// Los cambios se aplican únicamente al pulsar "Aplicar filtros".
// ------------------------------------------------------------

class FiltrosPage extends StatefulWidget {
  final Filtros initial;
  final CatalogosJcv catalogos;

  const FiltrosPage({
    super.key,
    required this.initial,
    required this.catalogos,
  });

  @override
  State<FiltrosPage> createState() => _FiltrosPageState();
}

class _FiltrosPageState extends State<FiltrosPage> {
  late Filtros _borrador;

  @override
  void initState() {
    super.initState();
    _borrador = widget.initial;
  }

  Widget _label(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(texto, style: estilo(13, peso: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final municipios = [
      'Todo el AMG',
      ...widget.catalogos.municipios.map((opcion) => opcion.nombre),
    ];
    final edades = [
      'Todos',
      ...widget.catalogos.gruposEdad.map(
        (opcion) => opcion.nombre.replaceFirst(' años', ''),
      ),
    ];
    return Scaffold(
      appBar: cabecera(context, volver: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const TituloPagina(
                etiqueta: 'PERSONALIZA TU CONSULTA',
                titulo: 'Elige qué quieres ver.',
              ),
              const SizedBox(height: 12),
              Text(
                'Consulta información agregada de las juventudes.',
                style: estilo(12, color: Marca.secundario),
              ),
              const SizedBox(height: 20),
              _label('Fuente de datos'),
              SelectorFuente(
                value: _borrador.fuente,
                onChanged: (value) {
                  setState(() {
                    _borrador = _borrador.copyWith(fuente: value);
                  });
                },
              ),
              const SizedBox(height: 20),
              _label('Municipio'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Marca.borde),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _borrador.municipio,
                    isExpanded: true,
                    style: estilo(14),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Marca.azul,
                    ),
                    items: municipios
                        .map(
                          (municipio) => DropdownMenuItem(
                            value: municipio,
                            child: Text(municipio),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _borrador = _borrador.copyWith(municipio: value);
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label('Edad'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: edades.map((edad) {
                  final seleccionada = _borrador.edad == edad;

                  return ChoiceChip(
                    label: Text(
                      edad,
                      style: estilo(
                        12,
                        peso: FontWeight.w600,
                        color: seleccionada ? Colors.white : Marca.azul,
                      ),
                    ),
                    selected: seleccionada,
                    showCheckmark: false,
                    selectedColor: Marca.azul,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: seleccionada ? Marca.azul : Marca.borde,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _borrador = _borrador.copyWith(edad: edad);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _label('Dimensión temática'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final ancho = (constraints.maxWidth - 8) / 2;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: temas.map((tema) {
                      final seleccionada = _borrador.tema == tema;

                      return SizedBox(
                        width: ancho,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: seleccionada
                                ? Marca.azul
                                : Colors.white,
                            side: BorderSide(
                              color: seleccionada ? Marca.azul : Marca.borde,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _borrador = _borrador.copyWith(tema: tema);
                            });
                          },
                          child: Text(
                            tema,
                            textAlign: TextAlign.center,
                            style: estilo(
                              12,
                              peso: FontWeight.w600,
                              color: seleccionada ? Colors.white : Marca.azul,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              Panel(
                color: Marca.azulClaro,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Marca.azul),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Se muestran resultados agregados.\n'
                        'Nunca respuestas individuales.',
                        style: estilo(11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _borrador = const Filtros();
                    });
                  },
                  child: Text(
                    'Limpiar',
                    style: estilo(13, peso: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context, _borrador);
                    },
                    child: const Text('Aplicar filtros'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
