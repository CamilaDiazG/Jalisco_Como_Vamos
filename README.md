# Jalisco Cómo Vamos · Aplicación móvil

Aplicación Android desarrollada en **Flutter y Dart** para explorar los resultados de la Encuesta de Bienestar de Jóvenes del Área Metropolitana de Guadalajara (AMG). Conserva la identidad visual de Jalisco Cómo Vamos y consulta agregados desde **Supabase**. El producto está **en desarrollo**: los resultados AMG ya se muestran, mientras la participación Tec, la consulta por IA/voz y los donativos siguen en construcción.

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
| Pregúntale a los datos | Pendiente | La interfaz muestra un aviso; no hay transcripción ni respuesta de IA. |
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
| 7. Preguntas por texto y voz | **Pendiente** | Captura de voz, respuesta basada en agregados verificables, límites del asistente y manejo de errores. |
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
