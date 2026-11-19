# Entrega: consultas y participación

## Pregúntale a los datos

Desplegar `supabase functions deploy ask-data` en el proyecto correspondiente.
La función requiere SUPABASE_URL y SUPABASE_ANON_KEY (variables estándar de
Supabase), un JWT válido y las RPC existentes con autorización de lectores.
No utiliza service_role, SQL dinámico, un proveedor de IA ni claves de IA.
Solo invoca jcv_resumen_bienestar o jcv_dimension con el JWT del solicitante.
No guarda preguntas, audio ni respuestas. No agregar logs del cuerpo de petición.

El alcance inicial es búsqueda de dimensión por palabras y presentación literal
de agregados, no un asistente generativo. La fuente se elige explícitamente;
edad y municipio son null. No interpreta filtros, comparaciones ni causalidad
en el texto; la respuesta informa esta limitación. Las consultas sin tema
reconocido reciben orientación, sin consulta a datos. Un despliegue público debe
definir límites de uso y revisar los permisos de las RPC en el proyecto real.

La voz usa speech_to_text 7.5: frase breve, permiso al pulsar el micrófono,
transcripción editable y envío manual por el mismo flujo. Configuración basada
en https://pub.dev/packages/speech_to_text. La app no almacena audio; el servicio
nativo puede utilizar servidores. Probar reconocimiento en español en dispositivo
Android/iOS real, rechazo del permiso, silencio, regreso del segundo plano y
reapertura de la pantalla. Bluetooth no está configurado en esta entrega.

Verificación externa pendiente: usuario anónimo → 401, lector no autorizado →
403 al consultar una dimensión, lector autorizado → agregados; Tec vacío y
muestra insuficiente sin porcentajes. Comprobar RPC ausente, token expirado,
JSON inválido y caída de red. El repositorio no contiene las migraciones de las
RPC originales; sus permisos deben comprobarse contra el backend instalado.

## Tec: contenido exacto pendiente

No se encontró un cuestionario Tec aprobado en el repositorio. La pantalla
muestra introducción, consentimiento, instrumento y envío en estado pendiente.
No permite consentir un texto provisional ni capturar respuestas.

El responsable debe entregar y aprobar:

- Objetivo, población, criterios de inclusión/exclusión, duración y responsable.
- Identificador y versión inmutable del instrumento; preguntas literales,
  identificadores, opciones/códigos, tipos, obligatoriedad, saltos y validaciones.
- Texto y versión del consentimiento, aviso de privacidad, finalidades,
  conservación, retiro, contacto y reglas de participación de menores.
- Criterios para duplicados, retiro/borrado, acceso de investigadores y publicación
  de agregados Tec; aprobación documentada con responsable y fecha.

`012_tec_private_structure.sql` prepara tablas sin datos en jcv_private, RLS
y sin acceso para anon/authenticated. Aplicar con el proceso habitual de
migraciones del equipo; esta entrega no modifica la base remota.

Contrato de envío futuro: request_id UUID (idempotencia), instrument_id,
instrument_version, consent_version, consent_accepted=true y answers por ID de
pregunta. El servidor debe tomar user_id del JWT y la hora de consentimiento
de su reloj, verificar instrumento aprobado y consentimiento vigente, validar
elegibilidad, saltos y todas las respuestas contra esa versión, rechazar campos
extra y guardar en una transacción. Devolver solo ID/fecha del recibo; nunca
respuestas individuales. Reintentos del mismo usuario/request_id deben devolver
el mismo recibo; cambios de contenido con el mismo ID deben rechazarse.

No se expone un endpoint de envío hasta implementar estas reglas con el
cuestionario aprobado. Tampoco se conectan estas tablas a los agregados Tec:
requiere una decisión metodológica explícita y no equivale a cargar datos AMG.
