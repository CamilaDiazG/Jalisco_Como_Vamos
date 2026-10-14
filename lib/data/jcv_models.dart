class IndicadorJcv {
  final String indicador;
  final String variable;
  final String etiquetaPositiva;
  final double? porcentaje;
  final int nMuestra;
  final int nValidas;
  final double? porcentajeSinRespuesta;
  final String estado;
  final bool ponderado;
  final String fuente;

  const IndicadorJcv({
    required this.indicador,
    required this.variable,
    required this.etiquetaPositiva,
    required this.porcentaje,
    required this.nMuestra,
    required this.nValidas,
    required this.porcentajeSinRespuesta,
    required this.estado,
    required this.ponderado,
    required this.fuente,
  });

  factory IndicadorJcv.fromJson(Map<String, dynamic> json) {
    return IndicadorJcv(
      indicador: json['indicador'] as String,
      variable: json['variable'] as String,
      etiquetaPositiva: json['etiqueta_positiva'] as String,
      porcentaje: (json['porcentaje'] as num?)?.toDouble(),
      nMuestra: (json['n_muestra'] as num).toInt(),
      nValidas: (json['n_validas'] as num).toInt(),
      porcentajeSinRespuesta: (json['porcentaje_sin_respuesta'] as num?)
          ?.toDouble(),
      estado: json['estado'] as String,
      ponderado: json['ponderado'] as bool,
      fuente: json['fuente'] as String,
    );
  }

  bool get tieneDato => estado == 'ok' && porcentaje != null;

  /// Nulo significa no disponible; nunca debe convertirse automáticamente en 0%.
  double? get fraccion => porcentaje == null ? null : porcentaje! / 100;
}

class OpcionCatalogo {
  final int codigo;
  final String nombre;
  const OpcionCatalogo({required this.codigo, required this.nombre});

  factory OpcionCatalogo.fromJson(Map<String, dynamic> json) => OpcionCatalogo(
    codigo: (json['codigo'] as num).toInt(),
    nombre: json['nombre'] as String,
  );
}

class CatalogosJcv {
  final List<OpcionCatalogo> municipios;
  final List<OpcionCatalogo> gruposEdad;
  const CatalogosJcv({required this.municipios, required this.gruposEdad});

  factory CatalogosJcv.fromJson(Map<String, dynamic> json) {
    List<OpcionCatalogo> leer(String clave) => (json[clave] as List)
        .map(
          (fila) =>
              OpcionCatalogo.fromJson(Map<String, dynamic>.from(fila as Map)),
        )
        .toList(growable: false);
    return CatalogosJcv(
      municipios: leer('municipios'),
      gruposEdad: leer('grupos_edad'),
    );
  }

  int codigoMunicipio(String nombre) =>
      municipios.firstWhere((opcion) => opcion.nombre == nombre).codigo;
  int codigoEdad(String nombre) => gruposEdad
      .firstWhere((opcion) => opcion.nombre.replaceFirst(' años', '') == nombre)
      .codigo;
}

class Indicadores {
  final List<IndicadorJcv> filas;
  Indicadores(List<IndicadorJcv> datos)
    : filas = ['satisfaccion_vida', 'felicidad', 'salud_mental']
          .map((id) {
            final coincidencias = datos.where((fila) => fila.indicador == id);
            if (coincidencias.length != 1) {
              throw FormatException(
                'La consulta no devolvió el indicador $id.',
              );
            }
            return coincidencias.single;
          })
          .toList(growable: false);

  double? get satisfaccion => valor(filas[0]);
  double? get felicidad => valor(filas[1]);
  double? get saludMental => valor(filas[2]);
  List<double?> get valores => [satisfaccion, felicidad, saludMental];
  int get nMuestra => filas.first.nMuestra;
  bool get ponderado => filas.first.ponderado;
  bool get tieneMuestraInsuficiente =>
      filas.any((fila) => fila.estado == 'muestra_insuficiente');

  static double? valor(IndicadorJcv fila) =>
      fila.tieneDato ? fila.porcentaje : null;
}

class ResumenEncuesta {
  final Indicadores? amg;
  final Indicadores? tec;
  const ResumenEncuesta({this.amg, this.tec});
}

String porcentaje(double? valor) =>
    valor == null ? '—' : '${valor.toStringAsFixed(2)}%';
