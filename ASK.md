# IA de Jalisco Cómo Vamos: primera versión

## Revisión y requisitos pendientes

Se revisaron `lib/auth`, los contratos de `lib/data`, `ask-data`, las migraciones
011/012, README y TEC_Y_CONSULTAS. Auth usa Supabase; las consultas existentes
usan el JWT del usuario. El README describe 1207 cuestionarios de 2026, tres
indicadores y 53 distribuciones; **no se verificaron esos conteos en la base**.

Este checkout no contiene los datos originales de la encuesta, las cargas SQL
01–10 ni la definición de `jcv_private.lectores`. Durante la implementación
apareció el paquete `jcvevals/`: se revisó y adaptó su `evals/provider.js` real,
que reutiliza el transporte validado de `evals/provider.js` en la raíz.
Los CSV del paquete de evaluación se conservan sin cambios y no forman el corpus.
No hubo acceso administrativo ni sesión
de lector para inspeccionar la base remota. No se modificó ningún CSV ni Flutter.

Antes de aplicar la migración, ejecutar `supabase/inspect_ask_backend.sql` en el
SQL Editor del proyecto y revisar el resultado. Debe confirmarse que
`jcv_private.lectores.usuario_id` es UUID y que la presencia de la fila autoriza
lectura. Si usa otra columna o condiciones de vigencia, adaptar **013** a esa
definición real. La migración aborta si no existe `usuario_id uuid`; no crea ni
modifica lectores. Las RPC originales deben mantener sus controles. `ask` exige
también que `jcv_catalogos` permita acceso antes de consultar el corpus.

## Contrato y seguridad

`POST /functions/v1/ask`, encabezados `apikey` publicable,
`Authorization: Bearer <access_token de lector>` y `Content-Type: application/json`.

Entrada: `{ "question": "¿Qué resultados hay de felicidad?", "case_id": "manual-01" }`.
`question` tiene máximo 2000 caracteres; `case_id` admite 1–100 caracteres
alfanuméricos, guion y guion bajo. No se aceptan campos adicionales.

Salida 200: `{ "answer": "…", "citations": ["…"], "retrieved_source_ids": ["…"] }`.
Ambas listas contienen strings. `retrieved_source_ids` se obtiene directamente
del recuperador del backend, incluso cuando se abstiene; nunca lo genera el
modelo ni se deduce de las citas. `case_id` no llega al modelo ni al recuperador.
No se guarda historial en base ni se registran cuerpos/tokens en logs.

Sin información suficiente, grupos no disponibles o muestras menores de 30:
`No tengo datos suficientes en las fuentes disponibles para responder.`
Las citas de una abstención son `[]`. Los errores de infraestructura **no** se
disfrazan de abstención: 401 sesión ausente/inválida, 403 lector no autorizado,
400 entrada inválida, 413 cuerpo excesivo, 503 autorización/proveedor sin
configurar y 502 error de consulta/proveedor/contrato.

`verify_jwt=false` permite claves de firma modernas; la función verifica siempre
el token con Auth `getUser` antes de consultar RPC. No utiliza `service_role`.
El permiso SQL solo devuelve si la sesión está en lectores. Las claves estándar
SUPABASE_URL/SUPABASE_ANON_KEY las proporciona el runtime.

## Corpus e IDs reproducibles

El corpus se materializa en memoria por petición con el JWT del lector a partir
de `jcv_resumen_bienestar` y las siete `jcv_dimension`. Parámetros cerrados:
`p_fuente=AMG`, `p_municipio=null`, `p_grupo_edad=null`. No se consultan
cuestionarios individuales ni archivos del repositorio. No hay dependencia
desde la función hacia `evals`, ground truth, `cases.csv` ni sus respuestas.

Una fuente corresponde a un indicador/distribución. ID:

```text
jcv:juventudes2026:v1:AMG:municipio%3Dall:edad%3Dall:<dimension>:<variable>
```

Cada segmento se codifica con `encodeURIComponent` y se une con `:`. La variable
es la clave del agregado original; no se usan títulos, posiciones ni IDs de
caso. Cambiar el orden o actualizar porcentajes no cambia el ID lógico. Para
otra encuesta o definición metodológica incompatible debe cambiarse la versión
del espacio de IDs. Estos IDs no son hashes de snapshots históricos. Se rechazan
duplicados, fuentes de otra población y porcentajes inválidos.

Se exige `estado=ok`, conteos enteros, `n_muestra >= n_validas >= 30` y el mínimo
de la RPC cuando existe. Fuentes suprimidas conservan identidad/título para la
recuperación pero no porcentajes ni conteos pequeños en el contexto del modelo.

Recuperación léxica determinista: normalizar acentos/minúsculas, quitar palabras
vacías, ordenar por intersección de términos únicos entre pregunta y
título/texto/categorías, desempatar por ID y recuperar hasta ocho fuentes.
Sin coincidencias se abstiene sin llamar al proveedor. Si alguna fuente
recuperada está suprimida, también se abstiene. Esto privilegia prudencia sobre
cobertura y puede producir abstenciones adicionales.

El modelo `gemini-3.5-flash-lite` recibe solo las fuentes recuperadas y selecciona
IDs con JSON Schema estricto. El backend valida nuevamente los IDs y ensambla
extractos de los agregados: no retorna prosa libre ni números del modelo.
Así cada cifra publicada procede literalmente de una fuente validada.
`cost_usd` se omite: no hay una tarifa facturada verificada, y no se estima.

Alcance V1: totales AMG 2026, todas las edades/municipios. Los cortes, cruces,
comparaciones históricas, causas y Tec no se responden con el total. Hay controles
deterministas para grupos/periodos comunes y un control semántico del modelo para
las demás solicitudes. La pertinencia semántica y resistencia a instrucciones
adversarias necesitan la evaluación real; las pruebas locales no la certifican.
No se implementó índice persistente, sinónimos exhaustivos ni límite de gasto
por lector. Flutter ahora usa `ask` y muestra respuesta, fuentes y cuota agotada. La integración de
este endpoint conserva el dashboard existente. Consulta README.md para el despliegue con Gemini 3.5 Flash-Lite en Free tier.

## Secreto y despliegue (PowerShell)

Configurar **GEMINI_API_KEY** en Supabase → Edge Functions → Secrets. No ponerlo
en Flutter, GitHub, código, argumentos de terminal ni archivos versionados.
Alternativamente, con un archivo privado fuera del repositorio que contenga
`GEMINI_API_KEY=...`, usar el comando `secrets set` siguiente. Ese archivo debe
crearlo el operador; no existe ni se ha configurado un secreto desde esta sesión.

Después de revisar el SQL anterior y ajustar 013 si corresponde:

```powershell
npx supabase login
$projectRef = 'lyzmbhfozrtfqcvmgsln'
npx supabase link --project-ref $projectRef
npx supabase secrets set --project-ref $projectRef --env-file "$env:USERPROFILE\.jcv\ask-secrets.env"
npx supabase db push --linked --dry-run
```

Revisar las migraciones que anuncia dry-run: el backend original se instaló por
SQL y puede no tener historial CLI reconciliado. No marcar migraciones antiguas
como aplicadas sin comprobarlas. Si el historial está reconciliado y el dry-run
solo incluye las migraciones esperadas:

```powershell
npx supabase db push --linked
npx supabase functions deploy ask --project-ref $projectRef
```

Si no lo está, aplicar **solo** el contenido completo de
`supabase/migrations/013_ask_reader.sql` en SQL Editor y luego ejecutar el comando
de despliegue de `ask`. No reinstalar las cargas ni alterar el dashboard.

Referencias de implementación:
[Auth getUser](https://supabase.com/docs/reference/javascript/auth-getuser),
[configuración de funciones](https://supabase.com/docs/guides/functions/function-configuration),
[Gemini y JSON Schema](https://ai.google.dev/gemini-api/docs/structured-output).

## Pruebas

Se intentó el smoke CD-06 con el runner original
`node jcvevals/evals/run_baseline.js --smoke CD-06`; se detuvo antes de llamar al
endpoint por falta de JCV_EVAL_URL/JCV_EVAL_TOKEN. No se inventó el caso ni se
ejecutaron los 279 intentos. Las pruebas locales usan fixtures sintéticos, no
resultados reales ni respuestas esperadas del benchmark.

```powershell
node --test evals/ask.test.mjs
```

Después de desplegar, abrir una sesión real de lector e introducir su
**access token**, no refresh token:

```powershell
$env:JCV_EVAL_URL = 'https://lyzmbhfozrtfqcvmgsln.supabase.co/functions/v1/ask'
$env:SUPABASE_PUBLISHABLE_KEY = Read-Host 'Clave publicable de Supabase'
$sessionToken = Read-Host 'Access token vigente del lector' -AsSecureString
$env:JCV_EVAL_TOKEN = [System.Net.NetworkCredential]::new('', $sessionToken).Password
node jcvevals/evals/run_baseline.js --smoke CD-06
Remove-Item Env:JCV_EVAL_TOKEN
```

El smoke original hace **una** llamada y evalúa el contrato, citas y porcentajes
con su oráculo existente. Sus referencias esperadas de workbook aún no están
alineadas con los IDs de agregados: puede fallar por ese motivo aunque el
contrato sea válido. No se cambiaron respuestas esperadas, umbrales ni IDs de
los CSV para hacer pasar la prueba. El mapeo debe verificarse contra el workbook
y las variables del backend antes de evaluar el conjunto completo.
El runner original conserva `--full`, pero no se ejecutó. El CLI auxiliar
`evals/provider.js` solo permite smoke y no sustituye al runner original.

Pendiente en entorno real: inspección SQL, despliegue, sesión de no-lector/lector,
agregados reales, secreto del proveedor y smoke CD-06. Las pruebas mock no
sustituyen estas verificaciones.

La migración 013 corregida crea public.jcv_ask_authorized() sin argumentos y devuelve boolean. Es idempotente mediante CREATE OR REPLACE y permisos repetibles. Después de aplicarla, ejecutar supabase/test_ask_authorized.sql en SQL Editor: lector=true, no lector=false, sin identidad=false, ejecución anon=false y authenticated=true. El script usa ROLLBACK y no altera lectores. Para comprobar idempotencia, ejecutar 013 dos veces y repetir la prueba.

## Diagnóstico seguro de errores 502

Solo `handler.mjs` devuelve explícitamente HTTP 502, desde su catch general.
La etapa controlada distingue `client_init`, `authentication`,
`reader_authorization`, `catalog`, `request_body`,
`aggregate_load_and_validation`, `retrieval`, `provider_configuration`,
`gemini_request_and_response` y `render_selection`.

Cada excepción registra `event=ask_failure`, `stage`, `status`, `gemini_called`,
`google_http_status`, `google_error_code` y `google_error_status`. Los códigos
numéricos se validan y el estado de Google se limita a una lista cerrada.
No se registran excepciones completas, mensajes del proveedor, stacks,
cabeceras, claves, tokens, case_id, preguntas ni respuestas. Si no hubo respuesta
HTTP del proveedor, sus códigos quedan null; no significa cuota agotada.
HTTP 429 conserva su tratamiento específico. Los rechazos normales 400/401/403
/503 y las abstenciones no se convierten en 502.

Para reproducir: enviar una única pregunta desde una sesión de lector en Flutter
y consultar los eventos `ask_failure` posteriores al despliegue. La CLI actual
usa la tabla `logs` con `source = 'function_logs'` (no una tabla independiente
llamada function_logs). Las pruebas locales verifican que los datos sensibles
no aparezcan en el registro; no sustituyen la petición autenticada real.
