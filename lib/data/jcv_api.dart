import 'package:supabase_flutter/supabase_flutter.dart';

import 'jcv_models.dart';
export 'jcv_models.dart';

/// Solo lectura de agregados. Requiere una sesión de usuario autorizada.
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
        .map(
          (row) => IndicadorJcv.fromJson(Map<String, dynamic>.from(row as Map)),
    )
        .toList();
  }
}
