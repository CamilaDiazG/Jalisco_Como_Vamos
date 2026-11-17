import 'package:supabase_flutter/supabase_flutter.dart';

/// Solo lectura de agregados. Requiere una sesión de usuario autorizada.
/// Este archivo se integra después de verificar la carga en Supabase.
class JcvApi {
  final SupabaseClient client;
  JcvApi(this.client);

  void _exigirSesion() {
    if (client.auth.currentSession == null) {
      throw StateError('Inicia sesión antes de consultar los resultados.');
    }
  }

  Future<Map<String, dynamic>> catalogos() async {
    _exigirSesion();
    final data = await client.rpc('jcv_catalogos');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<IndicadorJcv>> resumen({
    String fuente = 'AMG',
    int? municipio,
    int? grupoEdad,
  }) async {
    _exigirSesion();
    final data = await client.rpc(
      'jcv_resumen_bienestar',
      params: {
        'p_fuente': fuente,
        'p_municipio': municipio,
        'p_grupo_edad': grupoEdad,
      },
    );
    return (data as List)
        .map((row) => IndicadorJcv.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
  }
}

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
      porcentajeSinRespuesta:
          (json['porcentaje_sin_respuesta'] as num?)?.toDouble(),
      estado: json['estado'] as String,
      ponderado: json['ponderado'] as bool,
      fuente: json['fuente'] as String,
    );
  }

  bool get tieneDato => estado == 'ok' && porcentaje != null;

  /// Nulo significa no disponible; nunca debe convertirse automáticamente en 0%.
  double? get fraccion => porcentaje == null ? null : porcentaje! / 100;
}
