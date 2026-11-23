# Jalisco Cómo Vamos · Aplicación móvil

Aplicación Android desarrollada en **Flutter y Dart** para explorar los resultados de la Encuesta de Bienestar de Jóvenes del Área Metropolitana de Guadalajara (AMG). Conserva la identidad visual de Jalisco Cómo Vamos y consulta agregados desde **Supabase**. El producto está **en desarrollo**: los resultados AMG ya se muestran, mientras la consulta por IA/voz ya está conectada en el código y requiere validación desplegada; otras integraciones siguen en desarrollo.

> **Estado al 6 de noviembre de 2026:** login y dashboard funcionales; ocho dimensiones navegables con datos AMG. Hay una base implementada para **5 de las 10 fases** del plan; las fases restantes incluyen integraciones y validaciones importantes. Esto **no equivale a 50 % del esfuerzo total**.

## Qué funciona hoy

| Funcionalidad | Estado | Alcance actual |
| --- | --- | --- |
| Inicio y cierre de sesión | Implementado | Supabase Auth y acceso a resultados restringido a lectores autorizados. |
| Dashboard de bienestar | Implementado | Tres indicadores reales de AMG: satisfacción con la vida, felicidad y salud mental. |
| Filtros | Implementado | Fuente, seis municipios, tres grupos de edad y dimensión temática. |
| Ocho dimensiones | Implementado; revisión pendiente | Bienestar subjetivo y 53 distribuciones de respuesta repartidas entre otras siete dimensiones. |
| Comparar AMG / Tec | Interfaz preparada | Presenta AMG; Tec indica ausencia de datos en vez de inventar porcentajes. |
| Participa: encuesta Tec | Pendiente | La navegación muestra un aviso; no captura ni envía respuestas todavía. |
| Pregúntale a los datos | Implementado; validación desplegada pendiente | Texto o dictado editable → `ask`; muestra respuesta y fuentes citadas del total AMG. |
| Apoya: donativos | Pendiente | La interfaz muestra un aviso; no procesa pagos. |

Las dimensiones disponibles en la interfaz son **Bienestar subjetivo, Educación y trabajo, Salud, Seguridad, Tiempo libre, Hogar y familia, Comunidad y Transporte**. La captura de Tiempo libre en el emulador confirma la integración de esa pantalla; el recorrido completo por las ocho, sus filtros y estados de error está pendiente de una prueba integral del equipo.

## Tecnología y estructura

- **Cliente:** Flutter/Dart, Material 3 y Google Fonts; navegación inferior para Inicio, Comparar, Participa y Apoya.
- **Identidad:** azul `#003E79`, rojo `#ED1849`, amarillo `#FFC425` y logo en `assets/images/logo_jaliscocomovamos.png`.
- **Datos y autenticación:** Supabase Auth, PostgreSQL y funciones RPC. `JcvApi` obtiene catálogos y resultados agregados; los cuestionarios individuales permanecen en `jcv_private`.
- **Fuente AMG:** archivo `DatosEncuestaBienestar de Jovenes - Jul-Ago 2026.zip`, con **1207 cuestionarios**. Excel, CSV, JSON y SPSS son representaciones de la misma encuesta: no se suman entre sí.

```text
jalisco_como_vamos/
├── android/
├── assets/images/logo_jaliscocomovamos.png
├── lib/
│   ├── main.dart                     # Inicialización, tema y AuthGate
│   ├── auth/
│   │   ├── auth_gate.dart            # Sesión y rutas privadas
│   │   └── login_page.dart
│   ├── data/
│   │   ├── jcv_api.dart              # RPC de catálogos, resumen y dimensiones
│   │   ├── jcv_models.dart
│   │   └── dimension_models.dart
│   └── screens/
│       ├── dashboard_page.dart       # Dashboard, filtros y navegación
│       └── dimension_contenido.dart  # Distribuciones y estados de consulta
├── pubspec.yaml
└── README.md
```

Los scripts SQL de las entregas pueden conservarse en una carpeta **`backend/` privada del equipo**; no van dentro de `assets/` ni del APK. El árbol muestra los archivos principales de la integración preparada y debe ajustarse si el equipo añade otros archivos al proyecto local.

## Ejecutar la app en Android Studio

1. Abre la **raíz del proyecto Flutter** en Android Studio y selecciona un emulador Android operativo.
2. Confirma que `pubspec.yaml` incluya `supabase_flutter`, `google_fonts` y, dentro de `flutter:`, la carpeta `assets/images/`.
3. Revisa `lib/main.dart`: la configuración de Supabase debe apuntar a **tu proyecto de desarrollo** y usar solo la **clave publicable**. No coloques contraseñas de usuarios, claves secretas ni `service_role` en Flutter.
4. Desde la terminal de la raíz del proyecto, ejecuta:

   ```powershell
   flutter doctor
   flutter pub get
   flutter analyze
   flutter run
   ```

5. Inicia sesión con una cuenta autorizada en la tabla de lectores de Supabase. En filtros, elige una dimensión, municipio y edad; pulsa **Aplicar filtros**. Desliza hacia arriba sobre las tarjetas para leer las preguntas siguientes.

La versión actual inicializa Supabase en `main.dart`. **La migración de la URL y la clave publicable a configuración por ambiente está pendiente**; no des por hecho que `--dart-define` ya esté implementado. Después de modificar assets, dependencias o archivos Dart que reemplazan pantallas, detén la app y ejecútala otra vez.

## Preparar el backend desde cero

Los SQL provienen de las entregas del equipo. Para una **base nueva de desarrollo**, ejecútalos en **Supabase → SQL Editor** en este orden, pegando cada archivo **completo** y pulsando **Run** sin seleccionar fragmentos:

| Orden | Archivo | Resultado esperado |
| --- | --- | ---: |
| 1 | `01_instalar_backend.sql` | 1207 cuestionarios AMG |
| 2 | `02_verificar.sql` | Consultas y permisos sin errores |
| 3 | `03_autorizar_usuario.sql` | Autoriza el UUID de una cuenta creada en Auth |
| 4 | `05_instalar_salud.sql` | 8449 valores (7 preguntas) |
| 5 | `06_verificar_salud.sql` | Salud correcta |
| 6 | `07_instalar_educacion_trabajo.sql` | 10863 valores (9 preguntas) |
| 7 | `08_verificar_educacion_trabajo.sql` | Educación y Salud correctas |
| 8 | `09_instalar_dimensiones_restantes.sql` **versión compacta** | 44659 valores (37 preguntas) |
| 9 | `10_verificar_dimensiones_restantes.sql` | Cinco dimensiones nuevas y las anteriores correctas |

En un proyecto Supabase **ya instalado**, no es necesario ejecutar todo otra vez. El SQL 09 compacto conserva una transacción y una tabla temporal: ejecútalo completo en una sola consulta. Los archivos de la encuesta y la carga SQL contienen datos individuales; mantenlos en almacenamiento privado del equipo.

El cliente consulta `jcv_catalogos`, `jcv_resumen_bienestar` y `jcv_dimension`. La tabla `jcv_private.lectores` autoriza qué sesiones pueden obtener agregados; la app no recibe filas individuales. **La clave publicable no sustituye la sesión del usuario.**

## Cómo leer los resultados

- **AMG:** porcentajes ponderados con el factor `FACTOR` de la encuesta. El denominador de las distribuciones incluye las categorías de no respuesta y, cuando corresponde, “No aplica”. La suma puede variar ligeramente de 100 % por redondeo.
- **Muestra insuficiente:** si una pregunta tiene menos de **30 respuestas válidas** en la selección, sus porcentajes no se publican. Este umbral es provisional; no garantiza anonimato ni precisión estadística.
- **Tec:** aún no hay cuestionarios Tec cargados. Su ausencia se presenta como **sin datos**, nunca como `0 %` ni como una copia de AMG.
- **Interpretación:** las preguntas de estudio y trabajo no son excluyentes; Seguridad muestra percepciones, no tasas de delitos; Transporte conserva “No se desplaza” como categoría. No se calcula un índice adicional a partir de estas distribuciones.

## Roadmap del producto completo

Estado: **hecho** = implementado en la entrega; **revisar** = existe código pero falta validación de extremo a extremo o aprobación; **pendiente** = aún no implementado. El avance corresponde a funcionalidades y evidencia disponible, no a horas invertidas.

| Fase | Estado | Entregable y criterio de cierre |
| --- | --- | --- |
| 1. Plataforma y marca | **Hecho** | Flutter abre en Android con logo, tema y navegación básica. |
| 2. Datos AMG y permisos | **Revisar** | Cargas y RPC de AMG implementadas; ejecutar verificaciones completas y revisar privacidad de resultados pequeños. |
| 3. Autenticación | **Hecho** | Login, gate de sesión, lector autorizado y logout. Revisar recuperación de cuenta y reglas finales de acceso. |
| 4. Dashboard y filtros | **Revisar** | Indicadores reales y filtros funcionan; comprobar todos los estados y la navegación en el emulador. |
| 5. Ocho dimensiones | **Revisar** | 53 distribuciones preparadas; probar las ocho con municipio/edad, scroll, Tec vacío y errores de red. |
| 6. Participa / encuesta Tec | **Pendiente · siguiente bloque** | Instrumento aprobado y versionado, consentimiento, borrador, validación, envío seguro y confirmación. |
| 7. Preguntas por texto y voz | **Revisar** | Pantalla conectada a `ask`, dictado editable, respuesta y citas, estados de carga y error. Falta validar el servicio desplegado y el micrófono en dispositivo. |
| 8. Donativos | **Pendiente** | Stripe en modo de prueba, creación segura del pago, webhook, idempotencia y confirmación; habilitar producción después. |
| 9. Calidad y seguridad | **Pendiente** | Pruebas automatizadas, accesibilidad, controles de privacidad, permisos, fallos de red y revisión OWASP MASVS. |
| 10. Entrega y publicación | **Pendiente** | Ambientes, firma Android, App Bundle, documentación operativa y aprobación del socio formador. |

**Lectura rápida del avance:** las **fases 1–5 tienen implementación base**, aunque 2, 4 y 5 requieren cierre de pruebas y revisión metodológica. Las **fases 6–10 siguen abiertas**; incluyen partes de gran esfuerzo, por lo que no conviene convertir 5/10 fases en un “50 % terminado”.

### Próxima sesión de trabajo

1. Confirmar el desplazamiento de las tarjetas y ejecutar `flutter analyze` con la versión actual.
2. Ejecutar `10_verificar_dimensiones_restantes.sql` y probar las ocho dimensiones con filtros representativos, Tec sin datos y comparación.
3. Revisar con Jalisco Cómo Vamos la publicación de categorías pequeñas y el alcance del cuestionario Tec.
4. Implementar **Participa**, empezando por el contrato de datos y la versión del cuestionario.

## Decisiones pendientes del equipo y del socio formador

- Confirmar qué resultados y cortes demográficos pueden publicarse, especialmente categorías pequeñas o diferencias entre filtros.
- Aprobar las preguntas, consentimiento y población objetivo de la encuesta Tec; distinguirla de la muestra AMG.
- Definir fuentes permitidas y ejemplos de respuesta para “Pregúntale a los datos”.
- Definir destinatario, montos, política y cuenta de Stripe para donativos; mientras tanto, desarrollar solo con pagos de prueba.

**Uso y publicación:** material de desarrollo académico. Antes de publicar código, datos o resultados, confirmar permisos del equipo y de Jalisco Cómo Vamos. No incluir en un repositorio público el ZIP original de la encuesta ni las cargas SQL con respuestas individuales.

## Consulta por IA y voz (actualización del 23 de noviembre de 2026)

La pantalla `lib/screens/preguntas_page.dart` invoca la Edge Function `ask`.
`supabase/functions/ask/index.ts` delega en `handler.mjs`: requiere una sesión
válida, autorización de lector y este cuerpo exacto (sin `fuente` ni `pregunta`):

```json
{"question":"¿Cómo está la salud?","case_id":"identificador-unico"}
```

`case_id` es un UUID nuevo por envío; solo sirve como metadato, no como criterio
de búsqueda. El backend admite hasta 2000 caracteres; la pantalla conserva su
límite de 500. La respuesta satisfactoria tiene este formato:

```json
{"answer":"Respuesta basada en agregados","citations":["id-de-fuente"],"retrieved_source_ids":["id-de-fuente"]}
```

La pantalla muestra `answer` y los identificadores de `citations` como texto
seleccionable. No son enlaces ni se presentan todas las fuentes recuperadas como
si estuvieran citadas. Valida que las citas pertenezcan a `retrieved_source_ids`.
Una abstención con citas vacías se muestra normalmente, sin inventar fuentes.

El alcance actual es la encuesta de juventudes 2026, total AMG, sin cortes por
municipio, edad u otros subgrupos y sin Tec. Por eso la pantalla ya no ofrece el
selector AMG/Tec. Se mantienen el aviso del micrófono, el reconocimiento del
dispositivo y la transcripción editable antes del envío. Durante la consulta se
muestra progreso y se bloquean nuevos envíos; los errores conservan la pregunta
para reintentar. No se modificó la lógica de supresión de muestras pequeñas.

Para habilitar el servicio se requieren las RPC existentes, `jcv_ask_authorized`,
lectores autorizados y `GEMINI_API_KEY` configurada únicamente como secreto del
backend de Supabase. Nunca colocar esa clave en Flutter. El despliegue y una
consulta autenticada real siguen pendientes de verificación; las pruebas locales
usan respuestas controladas y no prueban las credenciales ni el proveedor real.

Validación local: `flutter test`, `flutter analyze` y
`node --test evals/ask.test.mjs`. Las pruebas de pantalla cubren contrato, carga,
respuesta y citas, abstención, errores de autorización/servicio y respuestas
inválidas. Probar además dictado, permisos y envío en un dispositivo Android.
La tabla de avance del 6 de noviembre es histórica; esta sección actualiza el
estado de la fase 7 sin afirmar que se haya completado la validación integral.

### Desplegar `ask` con Gemini 2.5 Flash-Lite

El proveedor usa Gemini Developer API, modelo fijo `gemini-2.5-flash-lite`, con
salida JSON estructurada. Gemini selecciona fuentes; la respuesta final sigue
construyéndose exclusivamente con agregados validados de Supabase. Se conservan
las abstenciones y la supresión de muestras pequeñas. La clave solo se lee en
la Edge Function mediante `GEMINI_API_KEY`; no se requiere clave del proveedor
en Flutter.

1. En Google AI Studio crea una clave de un proyecto en **Free tier** y verifica
   sus cuotas disponibles. El nivel gratuito depende de la cuenta/proyecto, no
   de un parámetro del código. No habilites facturación si quieres permanecer
   en ese nivel. Consulta [precios oficiales](https://ai.google.dev/gemini-api/docs/pricing)
   y [límites vigentes](https://ai.google.dev/gemini-api/docs/rate-limits).
   Google indica que el contenido del nivel gratuito puede usarse para mejorar
   sus productos; solo se envían la pregunta y extractos agregados permitidos.
2. En Supabase → Edge Functions → Secrets, agrega `GEMINI_API_KEY` con esa clave.
   No la pegues en el código, Flutter ni comandos guardados en el historial.
3. Verifica las RPC `jcv_catalogos`, `jcv_resumen_bienestar`, `jcv_dimension` y
   `jcv_ask_authorized`, y que la cuenta de prueba pertenezca a los lectores.
   Si falta la última RPC, revisa y aplica completo
   `supabase/migrations/013_ask_reader.sql` en SQL Editor sobre el backend existente.
   Requiere `jcv_private.lectores.user_id` de tipo UUID. No reinstales los datos ni
   ejecutes todas las migraciones a ciegas; `ASK.md` detalla la inspección previa.
4. Desde la raíz, con la CLI de Supabase disponible, despliega únicamente `ask`:

   ```powershell
   npx supabase login
   $jcvProjectRef = 'TU_PROJECT_REF'
   npx supabase functions deploy ask --project-ref $jcvProjectRef
   ```

   `supabase/config.toml` conserva `verify_jwt = false` para `ask`: el handler
   valida el JWT con `auth.getUser` y después la autorización del lector.
   No elimines esas comprobaciones. Consulta el [despliegue oficial de Supabase](https://supabase.com/docs/guides/functions/deploy).
5. Abre Flutter, inicia sesión con un lector autorizado y pregunta por felicidad.
   Comprueba la respuesta y las fuentes; prueba también una pregunta sin datos
   y el dictado en Android. La petición es `{question, case_id}`; la respuesta
   satisfactoria es `{answer, citations, retrieved_source_ids}`.

Si Gemini devuelve HTTP 429, `ask` responde HTTP 429 con
`code: AI_QUOTA_EXCEEDED` y un mensaje seguro. Flutter indica cuota agotada,
conserva el texto y permite reintentar manualmente más tarde. No hay reintentos
automáticos, cambio de proveedor ni activación de facturación. El límite puede
ser temporal o diario; no se promete un tiempo de recuperación. Los fallos del
proveedor/red devuelven 502 y la falta de clave devuelve 503; no se presentan
como abstenciones satisfactorias.

Las pruebas locales de backend pasan (17 casos). Las pruebas de Flutter incluyen
el estado de cuota agotada; el despliegue y la consulta real con Gemini requieren
el secreto y una sesión autorizada y no se han ejecutado en esta revisión.
