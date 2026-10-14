import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

// ------------------------------------------------------------
// MARCA
// ------------------------------------------------------------

abstract class Marca {
  static const azul = Color(0xFF0E3B70);
  static const rojo = Color(0xFFE10E41);
  static const amarillo = Color(0xFFFFC629);
  static const lima = Color(0xFFC1D100);
  static const naranja = Color(0xFFF28C00);

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
        textTheme: GoogleFonts.montserratTextTheme(base.textTheme),
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
      home: const DashboardPage(),
    );
  }
}

// ------------------------------------------------------------
// FILTROS Y DATOS DE DEMOSTRACIÓN
// Sustituye DemoRepository cuando conectes tu base real.
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

class Indicadores {
  final int satisfaccion;
  final int felicidad;
  final int saludMental;

  const Indicadores(
      this.satisfaccion,
      this.felicidad,
      this.saludMental,
      );

  List<int> get valores => [
    satisfaccion,
    felicidad,
    saludMental,
  ];
}

class ResumenDemo {
  final Indicadores amg;
  final Indicadores tec;

  const ResumenDemo({
    required this.amg,
    required this.tec,
  });
}

abstract class DemoRepository {
  // Cifras ilustrativas. NO son resultados de la encuesta.
  // No se inventan resultados para combinaciones sin datos.
  static const ejemplos = <String, ResumenDemo>{
    'Todo el AMG|Todos': ResumenDemo(
      amg: Indicadores(72, 68, 64),
      tec: Indicadores(78, 74, 61),
    ),
    'Guadalajara|20–24': ResumenDemo(
      amg: Indicadores(70, 66, 62),
      tec: Indicadores(77, 71, 59),
    ),
  };

  static ResumenDemo? consultar(Filtros filtros) {
    if (filtros.tema != 'Bienestar subjetivo') return null;

    return ejemplos['${filtros.municipio}|${filtros.edad}'];
  }
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

const edades = ['Todos', '15–19', '20–24', '25–29'];

// Catálogo de demostración: reemplázalo por el de tu encuesta.
const municipios = ['Todo el AMG', 'Guadalajara', 'Zapopan'];

// ------------------------------------------------------------
// CABECERA Y COMPONENTES COMPARTIDOS
// ------------------------------------------------------------

void mostrarAviso(
    BuildContext context,
    String titulo,
    String mensaje,
    ) {
  showDialog<void>(
    context: context,
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

PreferredSizeWidget cabecera(
    BuildContext context, {
      bool volver = false,
    }) {
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
      'assets/images/jcv_logo.png',
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
          style: IconButton.styleFrom(
            backgroundColor: Marca.azulClaro,
          ),
          icon: const Icon(
            Icons.person_outline,
            color: Marca.azul,
          ),
          onPressed: () => mostrarAviso(
            context,
            'Perfil',
            'La autenticación de usuarios está pendiente de integración.',
          ),
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

  const TituloPagina({
    super.key,
    required this.etiqueta,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: estilo(11, color: Marca.secundario),
        ),
        const SizedBox(height: 6),
        Text(
          titulo,
          style: estilo(22, peso: FontWeight.w700),
        ),
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

class NotaDemo extends StatelessWidget {
  const NotaDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Datos de ejemplo · cifras no oficiales',
      style: estilo(11, color: Marca.secundario),
    );
  }
}

// ------------------------------------------------------------
// DASHBOARD PRINCIPAL
// ------------------------------------------------------------

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Filtros _filtros = const Filtros();

  Future<void> _abrirFiltros({String? tema}) async {
    final resultado = await Navigator.push<Filtros>(
      context,
      MaterialPageRoute(
        builder: (_) => FiltrosPage(
          initial: _filtros.copyWith(tema: tema),
        ),
      ),
    );

    if (!mounted || resultado == null) return;

    setState(() => _filtros = resultado);
  }

  void _cambiarFuente(Fuente fuente) {
    setState(() {
      _filtros = _filtros.copyWith(fuente: fuente);
    });
  }

  @override
  Widget build(BuildContext context) {
    final comparar = _filtros.fuente == Fuente.comparar;
    final resumen = DemoRepository.consultar(_filtros);

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
              SelectorFuente(
                value: _filtros.fuente,
                onChanged: _cambiarFuente,
              ),
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
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _abrirFiltros(),
                      child: const Icon(Icons.tune, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (resumen == null)
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.query_stats,
                        size: 36,
                        color: Marca.azul,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin datos de ejemplo para esta selección',
                        style: estilo(17, peso: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tema: ${_filtros.tema}\n'
                            'Los ejemplos disponibles son:\n'
                            '• Todo el AMG + Todas las edades.\n'
                            '• Guadalajara + 20–24 años.\n\n'
                            'Ambos corresponden a Bienestar subjetivo.',
                        style: estilo(13, color: Marca.secundario),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _abrirFiltros(),
                        child: const Text('Cambiar filtros'),
                      ),
                    ],
                  ),
                )
              else if (comparar)
                ComparacionContenido(resumen: resumen)
              else
                ResumenContenido(
                  indicadores: _filtros.fuente == Fuente.tec
                      ? resumen.tec
                      : resumen.amg,
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
                            child: Icon(
                              Icons.mic_none,
                              color: Colors.white,
                            ),
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
                                  style: estilo(
                                    12,
                                    color: Marca.secundario,
                                  ),
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

  const ResumenContenido({
    super.key,
    required this.indicadores,
  });

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
          'Satisfecha/o o muy satisfecha/o con su vida.',
          style: estilo(12, color: Marca.secundario),
        ),
      ],
    );

    final grafica = Semantics(
      label: 'Satisfacción con la vida: '
          '${indicadores.satisfaccion} por ciento. Dato de ejemplo.',
      child: SizedBox(
        width: 132,
        height: 132,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CircularProgressIndicator(
                value: indicadores.satisfaccion / 100,
                strokeWidth: 14,
                color: Marca.amarillo,
                backgroundColor: Marca.azulClaro,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${indicadores.satisfaccion}%',
                  style: estilo(32, peso: FontWeight.w700),
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
                      'La gráfica muestra un porcentaje ilustrativo de '
                          'respuestas satisfechas o muy satisfechas. '
                          'La agrupación final debe validarse con el código '
                          'de respuestas de la encuesta.',
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
              const NotaDemo(),
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
                descripcion: 'Feliz o muy feliz',
                acento: Marca.amarillo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TarjetaIndicador(
                titulo: 'Salud mental',
                valor: indicadores.saludMental,
                descripcion: 'Satisfecha/o o muy satisfecha/o',
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
  final int valor;
  final String descripcion;
  final Color acento;

  const TarjetaIndicador({
    super.key,
    required this.titulo,
    required this.valor,
    required this.descripcion,
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
                child: Text(
                  titulo,
                  style: estilo(12, peso: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$valor%',
            style: estilo(28, peso: FontWeight.w700),
          ),
          Text(
            descripcion,
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
  final ResumenDemo resumen;

  const ComparacionContenido({
    super.key,
    required this.resumen,
  });

  @override
  Widget build(BuildContext context) {
    final titulos = [
      'Satisfacción con la vida',
      'Felicidad',
      'Salud mental',
    ];

    final diferencia =
        resumen.tec.satisfaccion - resumen.amg.satisfaccion;

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
                  valor: resumen.amg.valores[i],
                  color: Marca.amarillo,
                ),
                const SizedBox(height: 6),
                BarraDato(
                  fuente: 'Tec',
                  valor: resumen.tec.valores[i],
                  color: Marca.rojo,
                ),
                const SizedBox(height: 18),
              ],
              const NotaDemo(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          color: Marca.amarilloClaro,
          child: Row(
            children: [
              Text(
                diferencia >= 0 ? '+$diferencia' : '$diferencia',
                style: estilo(30, peso: FontWeight.w700),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'puntos porcentuales',
                      style: estilo(13, peso: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'en satisfacción con la vida (Tec vs. AMG).',
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
                'Las respuestas Tec corresponden a quienes participan. '
                    'Esta comparación es descriptiva; no representa '
                    'a toda la comunidad.',
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

  const Leyenda({
    super.key,
    required this.nombre,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(nombre, style: estilo(11)),
      ],
    );
  }
}

class BarraDato extends StatelessWidget {
  final String fuente;
  final int valor;
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
      label: '$fuente: $valor por ciento. Dato de ejemplo.',
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
                widthFactor: valor / 100,
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
            width: 36,
            child: Text('$valor%', style: estilo(11)),
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

  const FiltrosPage({
    super.key,
    required this.initial,
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
      child: Text(
        texto,
        style: estilo(13, peso: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        _borrador = _borrador.copyWith(
                          municipio: value,
                        );
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
                        color: seleccionada
                            ? Colors.white
                            : Marca.azul,
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
                            backgroundColor:
                            seleccionada ? Marca.azul : Colors.white,
                            side: BorderSide(
                              color: seleccionada
                                  ? Marca.azul
                                  : Marca.borde,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _borrador = _borrador.copyWith(
                                tema: tema,
                              );
                            });
                          },
                          child: Text(
                            tema,
                            textAlign: TextAlign.center,
                            style: estilo(
                              12,
                              peso: FontWeight.w600,
                              color: seleccionada
                                  ? Colors.white
                                  : Marca.azul,
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
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Marca.azul,
                    ),
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