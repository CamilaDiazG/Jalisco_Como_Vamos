/// Contratos de agregados. Ninguna clase representa una respuesta individual.
class CategoriaDistribucion {
  final int codigo;
  final String etiqueta;
  final bool esAusencia;
  final double? porcentaje;

  const CategoriaDistribucion({
    required this.codigo,
    required this.etiqueta,
    required this.esAusencia,
    required this.porcentaje,
  });

  factory CategoriaDistribucion.fromJson(Map<String, dynamic> json) {
    final raw = json['porcentaje'];
    final value = raw == null ? null : num.parse(raw.toString()).toDouble();
    if (value != null && (!value.isFinite || value < 0 || value > 100)) {
      throw const FormatException('Porcentaje de distribución inválido.');
    }
    return CategoriaDistribucion(
      codigo: (json['codigo'] as num).toInt(),
      etiqueta: json['etiqueta'] as String,
      esAusencia: json['es_ausencia'] as bool,
      porcentaje: value,
    );
  }
}

class PreguntaDistribucion {
  final String variable;
  final String titulo;
  final String textoOriginal;
  final String estado;
  final int nMuestra;
  final int nValidas;
  final int minimoValidas;
  final String fuente;
  final bool ponderado;
  final String versionMetodologia;
  final String denominador;
  final List<CategoriaDistribucion> categorias;

  const PreguntaDistribucion({
    required this.variable,
    required this.titulo,
    required this.textoOriginal,
    required this.estado,
    required this.nMuestra,
    required this.nValidas,
    required this.minimoValidas,
    required this.fuente,
    required this.ponderado,
    required this.versionMetodologia,
    required this.denominador,
    required this.categorias,
  });

  bool get publicable => estado == 'ok';

  factory PreguntaDistribucion.fromJson(Map<String, dynamic> json) {
    final estado = json['estado'] as String;
    final n = (json['n_muestra'] as num).toInt();
    final validas = (json['n_validas'] as num).toInt();
    final minimo = (json['minimo_validas'] as num).toInt();
    final categorias = (json['categorias'] as List)
        .map(
          (e) => CategoriaDistribucion.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(growable: false);
    if (!const ['ok', 'sin_datos', 'muestra_insuficiente'].contains(estado) ||
        n < 0 ||
        validas < 0 ||
        validas > n ||
        minimo < 30 ||
        (estado == 'ok' &&
            (validas < minimo ||
                categorias.isEmpty ||
                categorias.any((c) => c.porcentaje == null))) ||
        (estado == 'sin_datos' && n != 0) ||
        (estado == 'muestra_insuficiente' && (n == 0 || validas >= minimo)) ||
        (estado != 'ok' && categorias.any((c) => c.porcentaje != null))) {
      throw const FormatException('Distribución o supresión inconsistente.');
    }
    return PreguntaDistribucion(
      variable: json['variable'] as String,
      titulo: json['titulo'] as String,
      textoOriginal: json['texto_original'] as String,
      estado: estado,
      nMuestra: n,
      nValidas: validas,
      minimoValidas: minimo,
      fuente: json['fuente'] as String,
      ponderado: json['ponderado'] as bool,
      versionMetodologia: json['version_metodologia'] as String,
      denominador: json['denominador'] as String,
      categorias: List.unmodifiable(categorias),
    );
  }
}

class DimensionDetalle {
  final String id;
  final String nombre;
  final String fuente;
  final List<PreguntaDistribucion> preguntas;

  const DimensionDetalle({
    required this.id,
    required this.nombre,
    required this.fuente,
    required this.preguntas,
  });

  factory DimensionDetalle.fromJson(Map<String, dynamic> json) {
    final fuente = json['fuente'] as String;
    if (!const ['AMG', 'TEC'].contains(fuente)) {
      throw const FormatException('Fuente desconocida.');
    }
    final preguntas = (json['preguntas'] as List)
        .map(
          (e) => PreguntaDistribucion.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList(growable: false);
    if (preguntas.any(
      (p) => p.fuente != fuente || p.ponderado != (fuente == 'AMG'),
    )) {
      throw const FormatException('Las preguntas no corresponden a la fuente.');
    }
    return DimensionDetalle(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      fuente: fuente,
      preguntas: List.unmodifiable(preguntas),
    );
  }
}
