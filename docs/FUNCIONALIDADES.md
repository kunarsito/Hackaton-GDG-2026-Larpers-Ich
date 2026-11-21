# RutaJunior — Funcionalidades, consideraciones y viabilidad

> Plataforma de comunidad, práctica y empleo para estudiantes universitarios de programación.
> Una sola base de código Flutter para **Android y Web**, con backend **Node.js + Express + SQLite**.
>
> Documento elaborado a partir del código actual del repositorio (no sólo del SRS). Donde el código
> y el SRS (`docs/SRS.md`) difieren, se indica en la sección de *Puntos a considerar*.

---

## 1. Resumen en una frase

RutaJunior lleva al estudiante por una ruta continua: **aprende** (historia de los pioneros) →
**practica** (retos con validación automática) → **pide o da ayuda** (foro con código) →
**gana reputación** (Karma Técnico) → **consigue empleo** (vacantes, CV y contacto directo con reclutadores).

---

## 2. Navegación general

| Entorno | Ancho de pantalla | Navegación | Particularidades |
|---|---|---|---|
| Móvil | < 600 px | Barra inferior (`NavigationBar`) con 5 pestañas | Teclado de símbolos (`SymbolKeyboard`) en el editor de código |
| Web / escritorio | ≥ 600 px | Barra lateral (`NavigationRail`) | Vista dividida en retos y atajo **Ctrl/Cmd + Enter** |

**Pestañas principales:** Biblioteca · Práctica · Comunidad · Empleos · Perfil.

**Barra superior (siempre visible):** logo y nombre, chip de **Karma** en vivo, acceso a
**Mensajes** con contador de no leídos y menú de **Cuenta** (Mensajes, Ranking, Cerrar sesión).

---

## 3. Funcionalidades por pantalla

### 3.1 Inicio de sesión y registro (`login_screen.dart`)
- Inicio de sesión con **correo y contraseña**; registro con nombre/usuario, universidad, correo y contraseña.
- Validación de campos vacíos antes de enviar.
- Muestra **a qué servidor está conectada** la app o por qué no, con opción de reintentar.
- **"Entrar con cuenta demo (Ada Dev)"**: rellena el correo y la contraseña de la cuenta de prueba.
- **"Continuar sin conexión (modo demo)"**: entra con datos de ejemplo en memoria cuando no hay backend
  (lo que se publica así no se guarda).
- La sesión se recuerda en el dispositivo: al reabrir la app se entra directamente.
- Cuentas de prueba: `ada@faro.dev`, `carlos@faro.dev`, `valeria@faro.dev`, `mateo@faro.dev`,
  `grace@faro.dev`, `linus@faro.dev`, `laura@faro.dev` (reclutadora). Contraseña: `faro1234`.

### 3.2 Biblioteca (`library_screen.dart`) — MOD_01
- Tres secciones: **Oficial**, **Comunidad** y **Cursos**.
  - *Oficial*: artículos históricos sobre pioneros (Dijkstra, Grace Hopper, Ada Lovelace).
  - *Comunidad*: artículos publicados por los usuarios, ordenables por **Top** (votos) o **Recientes**.
  - *Cursos*: acceso a la pantalla de cursos (ver 3.6).
- Botón **PUBLICAR** para que cualquier usuario escriba un artículo (título, resumen, contenido,
  personaje y época opcionales, y reto propio vinculado).
- **Lector de artículo** en hoja deslizable. Si el artículo tiene un reto asociado aparece
  **"Pon en práctica su legado →"**, que abre directamente ese reto (inicio del *Happy Path*).

### 3.3 Práctica (`practice_screen.dart`) — MOD_02
- Listado de retos **Oficiales** y de **Comunidad**, con orden **Top / Recientes**.
- Tarjetas con dificultad (Básico, Intermedio, Avanzado), categoría, número de casos de prueba
  y estado (resuelto / pendiente).
- Botón **CREAR RETO**: enunciado, dificultad, categoría, código base en Dart y casos de prueba.
  Al publicar el primer reto o curso el usuario obtiene el rol **creator**.

### 3.4 Detalle del reto / editor (`challenge_detail_screen.dart`)
- Enunciado, categoría y casos de prueba esperados (entrada → salida).
- **Editor de código Dart** y botón **EJECUTAR PRUEBAS (< 2 s)**.
  - Móvil: vista apilada con desplazamiento; el **SymbolKeyboard** (`{ } ( ) [ ] ; " ' = == => return print < > + - TAB`)
    queda justo encima del teclado táctil.
  - Web: vista dividida (enunciado a la izquierda, editor y consola a la derecha) y **Ctrl/Cmd + Enter**.
- Resultado de la validación: aprobado (con el Karma ganado) o fallido (con el caso que falló,
  lo esperado y lo obtenido).
- Si falla aparece **"Pedir ayuda en el foro →"**, que abre una publicación con el título,
  el código y el reto ya precargados.

### 3.5 Comunidad / Feed (`community_screen.dart`) — MOD_03
- Feed estilo **Facebook + GitHub** con orden **Top / Recientes / Guardados**.
- Botón **CREAR**: publicación o pregunta, con descripción, fragmento de código y hasta
  **4 adjuntos de 10 MB** (imágenes, PDF, ZIP, código).
- En cada publicación:
  - **Votar** a favor o en contra.
  - **Guardar**.
  - **Fork**: copia propia de un código para mejorarlo, enlazada al original.
  - Abrir el **hilo de respuestas**. El autor puede **marcar una respuesta como solución**,
    lo que da +15 de Karma a quien respondió.
- Las publicaciones que anuncian un reto, curso o artículo enlazan directamente a ese contenido.

### 3.6 Cursos (`courses_screen.dart`)
- Botón **CREAR CURSO** en su propia fila (no se superpone a los filtros en teléfonos pequeños):
  título, descripción, nivel, etiquetas y lecciones (artículos y retos, propios u oficiales).
- Filtros: **Todos / Oficiales / Creadores / Inscrito / Mis cursos**. Orden: **Mejor valorados / Recientes**.
- **Mis cursos (gestión del creador):** en cada tarjeta propia, menú **⋮ → Editar / Eliminar**; los
  mismos botones aparecen en la barra superior del detalle. Editar reutiliza el formulario de creación
  y actualiza el anuncio del feed; eliminar pide confirmación y borra inscripciones, calificaciones y el
  anuncio. Sólo el autor (o un admin) puede hacerlo; los cursos oficiales no se tocan.
- Detalle del curso: lista de lecciones, **Inscribirme**, barra **"Prácticas resueltas x/y"**,
  **Marcar como completado** (sólo se habilita al resolver **todas** las prácticas del curso; el
  backend también lo exige) con +20 de Karma al creador, y **calificar** de 1 a 5.

### 3.7 Empleos (`jobs_screen.dart`) — MOD_04
- Vacantes de tipo **Pasantía, Junior y Freelance**, filtrables, con modalidad y requisitos.
- **POSTULARME**: envía el **CV en PDF** del perfil (o uno nuevo) y un mensaje al publicador.
- **PUBLICAR VACANTE**: puesto, empresa, tipo, modalidad, descripción, requisitos y enlace externo
  opcional. Quien publica obtiene el rol **recruiter**.
- El publicador ve la **lista de postulantes** de cada vacante.
- **BUSCAR TALENTO**: lleva a la búsqueda de candidatos (ver 3.10).

### 3.8 Perfil (`profile_screen.dart`)
- Perfil estilo **Instagram**: avatar, nombre, universidad, **biografía** (hasta 300 caracteres),
  enlaces (GitHub, LinkedIn, web), habilidades, roles, **Karma**, seguidores y seguidos.
- Insignia **"Abierto a oportunidades"** al subir el CV.
- Pestañas: **Publicaciones · Cursos · Retos · Guardados** (Guardados sólo en el perfil propio).
- En el perfil propio: **EDITAR PERFIL** y subir CV.
- En perfiles ajenos: **SEGUIR**, **MENSAJE** y **REGALAR KARMA** (hasta 5 puntos al día, tomados del propio saldo).

### 3.9 Mensajes (`messages_screen.dart`)
- Bandeja de conversaciones 1 a 1 con contador de no leídos.
- Chat con texto y **archivos adjuntos**; se actualiza cada 5 segundos (sin WebSockets).
- Pensado para **contratación** y contacto personal entre estudiantes y reclutadores.

### 3.10 Ranking y búsqueda de talento (`talent_screen.dart`)
- **Top usuarios** y **Top creadores** por Karma.
- **Buscar talento**: búsqueda por nombre, habilidades y universidad, opción de mostrar sólo
  perfiles "Abiertos a oportunidades", resultados **ordenados por Karma**, con acceso directo
  al perfil o a un mensaje privado.

### 3.11 Reglas de Karma Técnico (backend, `karma.service.ts`)

| Acción | Karma |
|---|---|
| Resolver un reto oficial (sólo la primera vez) | +10 |
| Resolver un reto de comunidad | +5 |
| Publicar en el foro | +10 |
| Recibir un voto a favor / en contra | +2 / −1 (nunca baja de 0) |
| Tu respuesta marcada como solución | +15 |
| Alguien completa tu curso | +20 al creador |
| Regalar Karma a otro usuario | hasta 5 al día |

Cada movimiento queda registrado (`karma_events`) para auditoría.

---

## 4. Flujo de demostración recomendado (5 minutos)

1. **Biblioteca → Oficial**: abrir el artículo de Edsger Dijkstra.
2. Pulsar **"Pon en práctica su legado"**: se abre su reto.
3. Escribir con el **SymbolKeyboard** (en móvil) y **ejecutar pruebas**; provocar un fallo.
4. **"Pedir ayuda en el foro"**: la publicación sale con el código y el reto precargados. Publicar (+10 Karma).
5. Con otra cuenta: responder y que el autor la **marque como solución** (+15 Karma).
6. **Perfil**: mostrar Karma, biografía y subir CV ("Abierto a oportunidades").
7. Con la cuenta de reclutadora (`laura@faro.dev`): **Buscar talento**, encontrar al estudiante
   y enviarle un **mensaje**; el estudiante se **postula** a una vacante.
8. *(Opcional)* **Biblioteca → Cursos**: crear un curso con un reto, inscribirse con otra cuenta y mostrar
   que **no se puede completar** hasta resolver las prácticas; luego editarlo o eliminarlo desde **Mis cursos**.

---

## 5. Puntos a considerar

### 5.1 Técnicos (pendientes reales en el código)

| # | Punto | Impacto | Recomendación |
|---|---|---|---|
| 1 | El validador usa un tiempo límite por defecto de **2500 ms** (el SRS pide < 2 s) y **no limita la memoria a 64 MB**. | Incumple el SRS; un código que consume mucha memoria no se corta. | Bajar `CODE_TIMEOUT_MS` tras medir en la máquina de la demo y añadir límite de memoria al proceso de Dart. |
| 2 | El validador ejecuta Dart real **sólo si encuentra el SDK** en el servidor; si no, hace una revisión estática. | En otra máquina los retos pueden "aprobar" sin ejecutarse. | Definir `DART_PATH` en `backend/.env` en el equipo de la demo. |
| 3 | El **código inicial de los retos ya pasa las pruebas**. | El botón "Pedir ayuda" sólo aparece si se rompe el código a propósito. | Dejar el código base incompleto en los retos de la demo. |
| 4 | En **modo demo sin conexión** lo que se publica vive en memoria y **no se guarda**. | Riesgo de "perder" datos en vivo si la app no encuentra el backend. | Comprobar `/api/health` antes de presentar. |
| 5 | En un teléfono físico la **IP del backend queda fija al compilar**. | Si cambia la red (por ejemplo en el lugar del evento) hay que recompilar. | Usar cable con `adb reverse` o recompilar con la nueva IP. |
| 6 | `REQUIRE_AUTH=false` por defecto. | Algunas rutas aceptan el usuario demo sin token. | Activarlo fuera de la demo. |
| 7 | Archivos en disco local (`backend/uploads/`) y base SQLite local. | Válido para el MVP; no escala a varios servidores. | Migrar a almacenamiento en la nube y una base gestionada si se despliega. |
| 8 | Mensajes por *polling* cada 5 s. | Más tráfico y algo de retraso. | WebSockets en una versión futura. |
| 9 | Código Flutter **duplicado** en `app/` y `app-mobile/`. | Se pueden desincronizar. | Mantener una sola carpeta. |
| 10 | **iOS no está configurado** (no existe `ios/`). | Sólo Android y Web. | Ejecutar `flutter create --platforms=ios .` si se necesita. |
| 11 | El identificador interno sigue siendo `com.example.faro_dev_app`. | No es válido para publicar en Play Store. | Cambiarlo antes de publicar (por ejemplo `com.rutajunior.app`). |
| 12 | El logo sigue siendo el diseñado para el nombre anterior. | Coherencia de marca. | Diseñar un logo propio de RutaJunior. |

### 5.2 Relación con el SRS

- El SRS (`docs/SRS.md`) está **actualizado con el código**: nombre RutaJunior, contratos de casos de prueba
  (`{ input, expectedOutput, description }`), modalidad de vacante como texto libre, conectividad (puertos 3000–3002
  y `API_BASE_URL`), endpoints reales y CRUD/finalización de cursos.
- Los contratos de datos (15 entidades) **coinciden** entre `app/lib/models/` y `backend/src/types/models.ts`.
- Requisitos del SRS **aún no cumplidos**: límite de 64 MB y tiempo < 2 s del validador (punto 1 de 5.1);
  se listan en la sección 5.3 del SRS.

### 5.3 Calidad verificada

- `flutter analyze` sin incidencias en `app/` y `app-mobile/`.
- **32 pruebas automáticas** pasando, entre ellas:
  - `overflow_test.dart`: 20 escenarios en pantallas de 320 y 360 px, texto al 130 % y teclado abierto, sin desbordes.
  - `happy_path_test.dart`: recorre el flujo de demostración completo sin backend.
  - `courses_layout_test.dart`: el botón **CREAR CURSO** no se superpone a los filtros en 320–360 px.
- Backend compila sin errores de tipos (`npx tsc --noEmit`) tras `npm install`.
- Los cursos se probaron de extremo a extremo contra el backend (crear, completar sin prácticas → rechazado,
  completar tras resolverlas, editar, eliminar y permisos de autor/oficial).
- Contraseñas guardadas con **scrypt + sal aleatoria**.

---

## 6. Viabilidad frente a otras opciones

### 6.1 Frente a plataformas existentes

| Necesidad del estudiante | Opción habitual | Qué aporta RutaJunior |
|---|---|---|
| Practicar algoritmos | LeetCode, HackerRank, Codewars | Retos ligados a una **historia** (pioneros) y a una **comunidad** que ayuda con el mismo código; los estudiantes también **crean** retos. |
| Resolver dudas de código | Stack Overflow, Discord | El fallo de un reto se convierte en **pregunta con el código precargado** en un clic. |
| Mostrar lo que sabe | GitHub, LinkedIn | El **Karma Técnico** refleja ayuda y retos resueltos, visible en el perfil y en rankings. |
| Encontrar primer empleo | LinkedIn, bolsas universitarias | Vacantes **junior, pasantías y freelance** con **postulación con CV** y **búsqueda de talento por habilidades, ordenada por Karma**, en la misma app. |
| Cursos | Platzi, freeCodeCamp, YouTube | Cursos **creados por los propios estudiantes** y valorados por la comunidad. |

**Diferencial:** no compite en profundidad con cada plataforma por separado, sino en **unir el recorrido**
(aprender → practicar → pedir ayuda → reputación → empleo) en un solo lugar y con una sola identidad,
pensado para **estudiantes universitarios en su primer empleo**.

### 6.2 Fortalezas para un hackatón

- **Funciona de verdad de punta a punta**: backend con base de datos, autenticación, validación de código real,
  adjuntos y mensajería; no es sólo una maqueta.
- **Multiplataforma real**: el mismo código corre en Android y Web, adaptado a cada pantalla.
- **Demo robusta**: si el backend falla, la app sigue funcionando con datos de ejemplo.
- **Alcance acotado y documentado** (SRS con requisitos RF-01 a RF-18) y **pruebas automáticas**.
- **Problema claro y cercano** al jurado y a los usuarios: la brecha entre estudiar y conseguir el primer empleo.

### 6.3 Riesgos y debilidades

- **Efecto red**: una red social necesita masa crítica de estudiantes y reclutadores para tener valor.
  *Mitigación*: lanzar por universidad o facultad, con contenido oficial que aporte valor desde el primer usuario.
- **Competidores grandes y consolidados** en cada función por separado.
- **Moderación** de contenido de comunidad (artículos, retos y archivos) no resuelta en el MVP.
- **Seguridad del validador**: ejecutar código de usuarios exige un aislamiento más fuerte antes de producción.
- **Infraestructura** pensada para demo (SQLite y archivos locales).

### 6.4 Camino a producción (propuesta)

1. Corregir los puntos 1 a 6 de la sección 5.1 (necesarios antes de usuarios reales).
2. Desplegar el backend en la nube con base de datos gestionada y almacenamiento de archivos externo.
3. Aislar el validador en contenedores con límites de CPU, memoria y red.
4. Piloto en una universidad con docentes que publiquen contenido oficial y empresas locales que publiquen vacantes.
5. Publicar en Play Store con un identificador propio y añadir iOS.

### 6.5 Conclusión

RutaJunior es **viable como MVP de hackatón**: el flujo principal está implementado, probado y se ejecuta en
Android y Web con persistencia real. Su valor está en **integrar** aprendizaje, comunidad, reputación y empleo
para un público concreto (estudiantes junior), más que en superar a cada plataforma especializada.
Para convertirse en un producto real, los retos principales son **atraer a la comunidad inicial** y
**reforzar seguridad e infraestructura**, ambos abordables con los pasos de la sección 6.4.
