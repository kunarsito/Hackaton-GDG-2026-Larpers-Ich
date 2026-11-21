# Especificación de Requerimientos de Software (SRS) - MVP FARO_DEV // CAMPUS

Actúa como un **Arquitecto de Software Principal y Lead Multiplataforma (Flutter/Dart & Web)**. Este documento constituye la **fuente única de verdad (Single Source of Truth)** para todo el desarrollo del proyecto.

> [!IMPORTANT]
> **PRINCIPIO FUNDAMENTAL DE DESARROLLO MULTIPLATAFORMA (MÓVIL & WEB):**
> Este proyecto se desarrolla y valida activamente bajo una arquitectura unificada para **Mobile App (Android / iOS)** y **Web (Navegadores de escritorio y móviles)** mediante **Flutter/Dart**.
> 
> **Regla de Oro:** Cualquier función, endpoint, componente o vista que se agregue, modifique o retire **DEBE ser 100% adecuada, probada y funcional en ambos entornos (Móvil y Web)** sin degradar la experiencia de usuario de ninguno de los dos.

---

### 1. Ideación y Propuesta de Valor del Proyecto
Estamos desarrollando **FARO_DEV // CAMPUS**, una **Plataforma Integral de Comunidad, Práctica y Cultura para Estudiantes Universitarios de Programación** disponible de manera simultánea en **Móvil (Android/iOS) y Web**.

- **Problema:** Los estudiantes universitarios de desarrollo de software aprenden frecuentemente de forma aislada, desconectados del mercado laboral temprano y sin valorar el contexto histórico/técnico de los pioneros de la computación.
- **Solución (Ecosistema Vivo Conectado):** Tres módulos estrechamente interconectados mediante un flujo continuo (*Happy Path*):
  1. **Biblioteca Digital e Historia (`RF-01`, `RF-02`):** Artículos técnicos sobre pioneros (Grace Hopper, Edsger Dijkstra, Ada Lovelace) con acción directa **"Pon en práctica su legado"**, que transporta al usuario al reto práctico asociado.
  2. **Zona de Práctica Interactiva (`RF-03`, `RF-04`, `RF-05`):** Editor de código adaptativo con retos por nivel de dificultad y evaluación de pruebas automatizadas (< 2 segundos). Si la solución falla, el estudiante cuenta con **"Pedir ayuda en el foro"**, que genera automáticamente una publicación con su código y el problema precargados.
  3. **Comunidad y Bolsa de Trabajo Colaborativa (`RF-06`, `RF-07`, `RF-08`):** Foro técnico con bloques de código monoespaciados, sistema de reputación (**Karma Técnico** obtenido al resolver retos o asistir en el foro) y tablero abierto de vacantes junior, pasantías y proyectos freelance.
  4. **Red Social de Creadores (`RF-09` a `RF-18`):** La plataforma evoluciona a una red social técnica (**Facebook + GitHub**): cada usuario tiene perfil público, crea y publica su propio contenido (cursos, prácticas, artículos), adjunta archivos, recibe votos y Karma, y se comunica por mensajes privados con otros estudiantes y reclutadores.

---

### 1.1 Dos Fuentes de Contenido: Oficial vs. Comunidad

Todo el contenido educativo (Biblioteca y Prácticas) se separa en dos espacios claramente distinguibles en la UI y en los datos:

| Espacio | Quién lo crea | Dónde se ve | Distintivo |
|---|---|---|---|
| **Oficial (FARO_DEV)** | El equipo de la plataforma (seedData / admin) | Pestaña **"Oficial"** en Biblioteca y Práctica | Insignia "Oficial", siempre visible, no votable negativamente |
| **Comunidad (Creadores)** | Cualquier usuario registrado | Pestaña **"Comunidad"** en Biblioteca y Práctica, y en el perfil del creador | Nombre y avatar del creador, votos, rating y Karma |

- El campo `source: 'official' | 'community'` y `authorId` (nulo en oficial) identifica el origen en `Article`, `Challenge` y `Course`.
- Los retos de comunidad usan el mismo validador (< 2s) que los oficiales.

---

### 1.2 Requerimientos Funcionales de la Red Social (v2)

- **RF-09 · Cursos de creadores:** Un usuario puede crear un **Curso** (título, descripción, portada, nivel, etiquetas) compuesto por lecciones ordenadas que enlazan artículos y retos propios. Otros usuarios pueden inscribirse, avanzar y calificar el curso.
- **RF-10 · Publicar contenido propio:** Cualquier usuario puede publicar artículos y retos (con casos de prueba) en el espacio **Comunidad**. El contenido aparece en su perfil y en el feed.
- **RF-11 · Feed de Comunidad (Facebook + GitHub):** Feed único con publicaciones de texto, bloques de código, archivos adjuntos, retos y cursos publicados. Cada publicación admite comentarios en hilo, **upvote/downvote**, **guardar (estrella)** y **"fork"** (crear una copia propia de un reto o snippet para mejorarlo, enlazada al original).
- **RF-12 · Archivos adjuntos:** Las publicaciones, comentarios y mensajes permiten adjuntar archivos (imágenes, PDF, `.zip`, archivos de código), como en X o GitHub. Límite: **10 MB por archivo, 4 archivos por publicación**. Las imágenes se previsualizan; el código se muestra con resaltado; el resto se descarga.
- **RF-13 · Ranking por votos y rating:** Todo listado (feed, cursos, retos y artículos de comunidad, creadores) tiene orden **"Top"** (puntaje = upvotes − downvotes, o rating promedio en cursos) como opción por defecto, además de **"Recientes"**. Lo mejor valorado queda arriba. Existe un ranking de **Top Creadores** y **Top Usuarios** por Karma.
- **RF-14 · Karma Técnico visible y otorgable:** El Karma se muestra en el **perfil**, en el avatar de cada publicación y en los rankings. Reglas:
  - +10 al resolver un reto oficial; +5 al resolver un reto de comunidad.
  - +2 por cada upvote recibido (−1 por downvote, sin bajar de 0).
  - +15 cuando una respuesta tuya se marca como **solución** en un hilo.
  - +20 al creador cada vez que alguien completa su curso.
  - Un usuario puede **otorgar Karma** manualmente a otro (máximo 5 puntos por día, tomados de su propio saldo) como agradecimiento.
- **RF-15 · Perfil estilo Instagram:** Perfil con avatar, nombre, universidad, **biografía/descripción libre** (hasta 300 caracteres), enlaces (GitHub, LinkedIn, portafolio), habilidades (etiquetas), **Karma**, número de seguidores/seguidos, retos resueltos y pestañas: *Publicaciones · Cursos · Retos creados · Guardados*. Botones **Seguir** y **Enviar mensaje**.
- **RF-16 · Mensajes privados:** Conversaciones 1 a 1 entre usuarios, con texto y archivos adjuntos, para **contratación** o contacto personal. Bandeja con no leídos. Actualización por polling (cada 5 s) en el MVP, sin WebSockets.
- **RF-17 · Canal de empleo y CV:** 
  - Los usuarios marcan en su perfil **"Abierto a oportunidades"** y suben su **CV (PDF)**.
  - En cada vacante existe el botón **"Postularme"**, que envía el CV y un mensaje al publicador.
  - Quien publica vacantes (reclutador o estudiante) ve la lista de postulantes y puede **buscar talento** filtrando por habilidades, universidad y Karma, y escribirles por mensaje privado.
- **RF-18 · Roles:** `student` (por defecto), `creator` (se activa al publicar su primer curso o reto), `recruiter` (puede publicar vacantes y buscar talento) y `admin` (gestiona contenido oficial). Un usuario puede tener varios roles.

---

### 2. Alcance Estricto del MVP (Qué SÍ y qué NO construir)

- **Incluido (SÍ):**
  - Módulos 100% sincronizados y responsivos para Móvil y Web.
  - 3 artículos históricos vinculados a retos prácticos.
  - 3 a 5 retos interactivos con validador aislado y timeout estricto (< 2s).
  - Flujo automatizado de "pedir ayuda con código precargado" en comunidad.
  - Sistema de Karma Técnico y tablero de vacantes.
  - Mock data / seedData embebido para garantizar ejecución offline inmediata en demostraciones, respaldado por endpoints REST en el backend.
  - Separación de contenido **Oficial** vs. **Comunidad** en Biblioteca y Práctica.
  - Perfiles públicos con biografía, Karma visible, seguidores y pestañas de contenido.
  - Creación de cursos, artículos y retos por usuarios; feed con votos, comentarios, guardados y fork.
  - Archivos adjuntos (≤ 10 MB) guardados en el backend (`backend/uploads/`).
  - Ordenamiento "Top" / "Recientes" y ranking de creadores y usuarios.
  - Mensajes privados 1 a 1 por polling; postulación con CV y búsqueda de talento.
  - Inicio de sesión simple (correo + contraseña con hash) para identificar a cada usuario; en demo, selector de usuarios semilla.
- **Excluido (NO):**
  - CMS administrativo complejo.
  - Sandbox pesado con soporte para decenas de lenguajes de servidor (acotado a JS/Dart/algoritmos base).
  - Videollamadas o salas de streaming.
  - Chat en tiempo real con WebSockets, chats grupales y notificaciones push.
  - Pagos por cursos o suscripciones de creadores.
  - Almacenamiento en la nube de archivos (S3/Firebase Storage); en el MVP se guardan en disco local.
  - Pasarelas de pago o autenticaciones federadas SSO de universidades.

---

### 3. Arquitectura Técnica y Stack Multiplataforma (Monorepo)

El proyecto opera bajo un esquema **Monorepo** (`app/`, `backend/`, `docs/`) diseñado para desarrollo colaborativo ágil:

#### A) Frontend Multiplataforma (`app/`)
- **Framework:** **Flutter (Material 3) + Dart**.
- **Metas de Despliegue:**
  - **Móvil:** APK / App Bundle para Android (teléfonos y tablets).
  - **Web:** SPA servida a través de WebAssembly / CanvasKit / HTML renderer (`flutter run -d edge/chrome`).
- **Adaptabilidad y Responsividad Bidireccional:**
  - **Entorno Móvil (`viewport < 600 px`):**
    - Navegación principal en barra inferior (`NavigationBar`).
    - En la Zona de Práctica, despliegue obligatorio del widget `SymbolKeyboard` (`{ }`, `( )`, `;`, `=`, `return`, `[]`, `"`) posicionado sobre el teclado táctil para eliminar la fricción al escribir código en pantallas táctiles.
    - Flujos modales en pantalla completa o bottom sheets amigables al pulgar.
  - **Entorno Web / Desktop (`viewport >= 600 px`):**
    - Navegación lateral persistente (`NavigationRail`).
    - En la Zona de Práctica, vista dividida en dos paneles (enunciado/casos a la izquierda, editor y consola interactiva a la derecha).
    - Teclas de acceso rápido y uso natural del teclado físico.
- **Conectividad de Red Híbrida (`api_constants.dart`):**
  - Detección inteligente de plataforma:
    - Web: `http://localhost:3000/api`
    - Emulador Android: `http://10.0.2.2:3000/api`
    - Dispositivo Móvil Físico: IP de red local configurable (`http://<LAN_IP>:3000/api`)
  - Manejo de contingencia (Fallback): Si el backend no responde, el servicio conmuta automáticamente a los datos semilla en memoria (`ApiService._initMockData()`) garantizando que la app móvil y web nunca se queden en pantalla en blanco.

#### B) Backend de Servicios (`backend/`)
- **Entorno:** Node.js (v22+) + Express + TypeScript.
- **CORS Habilitado:** Obligatorio para permitir peticiones originadas desde Flutter Web en cualquier puerto.
- **Seguridad en Validación:** Validador de código en subproceso aislado con límite de memoria (64 MB) y tiempo límite estricto de ejecución (< 2s).
- **Compatibilidad API:** Endpoints REST idempotentes y homogéneos tanto para clientes móviles como navegadores web.

---

### 4. Política de Adición o Remoción de Funcionalidades

Para cualquier cambio funcional en el sistema, es obligatorio aplicar el siguiente filtro:

1. **Equivalencia de Capacidades:**
   - Si se añade una función en Web (ej. copiado de código al portapapeles, filtros de dificultad, navegación entre hilos), debe contar con su correspondiente interacción táctil en Móvil.
   - Si se añade una función específica de Móvil (ej. teclado de símbolos especiales `SymbolKeyboard`), debe ofrecer un comportamiento coherente o degradación elegante en Web (ej. ocultarse o transformarse en barra de snippets rápidos).
2. **Consistencia de Contratos de Datos:**
   Cualquier campo nuevo en los modelos debe actualizarse simultáneamente en:
   - Modelos Dart (`app/lib/models/`)
   - Modelos TypeScript (`backend/src/types/models.ts`)
3. **Cero Dependencias de Plataforma Única:**
   No utilizar plugins o librerías que solo compilen en una plataforma salvo que cuenten con su respectivo condicional multiplataforma (`kIsWeb` o `Platform.isAndroid`).

---

### 5. Contratos de Datos (Entidades Principales)

Las entidades se mantienen estrictamente sincronizadas entre Dart y TypeScript:

```typescript
// Usuario
interface User {
  id: string;
  name: string;
  university: string;
  karmaPoints: number;
  solvedChallenges: string[];
}

// Artículo Histórico
interface Article {
  id: string;
  title: string;
  pioneerName: string;
  era: string;
  summary: string;
  content: string;
  relatedChallengeId?: string;
}

// Reto de Programación
interface Challenge {
  id: string;
  title: string;
  difficulty: 'Básico' | 'Intermedio' | 'Avanzado';
  category: string;
  description: string;
  starterCode: string;
  testCases: Array<{ input: any; expected: any; isHidden?: boolean }>;
}

// Publicación en Comunidad
interface ForumPost {
  id: string;
  authorId: string;
  authorName: string;
  title: string;
  body: string;
  codeSnippet: string;
  challengeId?: string;
  replies: Array<{ id: string; authorName: string; body: string; createdAt: string }>;
  upvotes: number;
}

// Oportunidad Laboral
interface JobOpportunity {
  id: string;
  title: string;
  companyOrPoster: string;
  type: 'Pasantía' | 'Junior' | 'Freelance';
  modality: 'Remoto' | 'Híbrido' | 'Presencial';
  description: string;
  contactUrl: string;
}
```

#### 5.1 Contratos de Datos de la Red Social (v2)

Campos nuevos en entidades existentes y entidades nuevas. Mismas reglas de sincronización Dart ↔ TypeScript.

```typescript
type ContentSource = 'official' | 'community';
type Role = 'student' | 'creator' | 'recruiter' | 'admin';

// Usuario (campos añadidos)
interface User {
  // ...campos existentes
  roles: Role[];
  avatarUrl?: string;
  bio: string;                 // máx. 300 caracteres
  links: { github?: string; linkedin?: string; website?: string };
  skills: string[];
  followers: number;
  following: number;
  openToWork: boolean;
  cvUrl?: string;              // PDF
}

// Artículo y Reto (campos añadidos)
interface Article   { /* ...existentes */ source: ContentSource; authorId?: string; upvotes: number; downvotes: number; createdAt: string; }
interface Challenge { /* ...existentes */ source: ContentSource; authorId?: string; upvotes: number; downvotes: number; forkedFromId?: string; createdAt: string; }

// Curso creado por usuarios u oficial
interface Course {
  id: string;
  source: ContentSource;
  authorId?: string;
  title: string;
  description: string;
  coverUrl?: string;
  level: 'Básico' | 'Intermedio' | 'Avanzado';
  tags: string[];
  lessons: Array<{ order: number; title: string; articleId?: string; challengeId?: string }>;
  ratingAvg: number;           // 0–5
  ratingCount: number;
  enrolledCount: number;
  createdAt: string;
}

// Archivo adjunto
interface Attachment {
  id: string;
  fileName: string;
  mimeType: string;
  sizeBytes: number;           // ≤ 10 MB
  url: string;
}

// Publicación en Comunidad (campos añadidos)
interface ForumPost {
  // ...campos existentes
  type: 'post' | 'question' | 'challenge' | 'course' | 'snippet';
  downvotes: number;
  attachments: Attachment[];
  savedCount: number;
  forkedFromId?: string;
  acceptedReplyId?: string;    // respuesta marcada como solución
  createdAt: string;
}

// Mensajes privados
interface Conversation { id: string; participantIds: [string, string]; lastMessageAt: string; unreadCount: number; }
interface Message { id: string; conversationId: string; senderId: string; body: string; attachments: Attachment[]; createdAt: string; readAt?: string; }

// Postulación a vacante
interface JobApplication { id: string; jobId: string; applicantId: string; cvUrl: string; message: string; status: 'enviada' | 'vista' | 'contactado'; createdAt: string; }

// JobOpportunity (campo añadido)
interface JobOpportunity { /* ...existentes */ posterId: string; createdAt: string; }

// Movimiento de Karma (auditoría)
interface KarmaEvent { id: string; userId: string; amount: number; reason: 'challenge_official' | 'challenge_community' | 'upvote' | 'downvote' | 'accepted_answer' | 'course_completed' | 'gift'; fromUserId?: string; createdAt: string; }
```

#### 5.2 Endpoints nuevos (REST)

| Método | Ruta | Uso |
|---|---|---|
| `POST` | `/api/auth/register`, `/api/auth/login` | Registro e inicio de sesión |
| `GET/PATCH` | `/api/users/:id` | Ver y editar perfil (bio, enlaces, habilidades, openToWork) |
| `POST/DELETE` | `/api/users/:id/follow` | Seguir / dejar de seguir |
| `GET` | `/api/users?sort=karma&skill=&university=` | Ranking y búsqueda de talento |
| `GET` | `/api/articles?source=official\|community&sort=top\|new` | Biblioteca separada y ordenada (igual para `/challenges` y `/courses`) |
| `POST` | `/api/courses`, `/api/courses/:id/enroll`, `/api/courses/:id/rate` | Cursos de creadores |
| `GET` | `/api/feed?sort=top\|new` | Feed de Comunidad |
| `POST` | `/api/posts/:id/vote` (`{ value: 1 \| -1 }`), `/save`, `/fork` | Interacciones estilo GitHub |
| `POST` | `/api/uploads` (multipart) | Subir adjunto, devuelve `Attachment` |
| `GET/POST` | `/api/conversations`, `/api/conversations/:id/messages` | Mensajes privados |
| `POST` | `/api/jobs/:id/apply`; `GET /api/jobs/:id/applications` | Postular con CV y ver postulantes |
| `POST` | `/api/karma/gift` | Otorgar Karma a otro usuario |

#### 5.3 Estado de implementación (rama `uriel_dev`)

RF-09 a RF-18 implementados en `backend/` y en `app/` (idéntico en `app-mobile/`). Detalle de rutas en `backend/README.md`. Decisiones tomadas al implementar:

- **Campos extra "por usuario"** (dependen de quién consulta, no se guardan tal cual): `myVote`, `isSaved`, `isFollowing`, `isEnrolled`, `isCompleted`, `myRating`, `hasApplied`, `applicationsCount`. También `authorName` en artículos, retos y cursos, y `refId` en `ForumPost` (enlaza el anuncio del feed con el reto/curso/artículo publicado). Están en ambos lados: `backend/src/types/models.ts` y `app/lib/models/`.
- **Karma al responder**: responder ya no da Karma por sí solo; da +15 cuando el autor del hilo la marca como solución (RF-14). Publicar sigue dando +10 (§6).
- **Contenido oficial**: admite votos positivos, nunca negativos (§1.1).
- **Funciones privadas** (mensajes, editar perfil, subir archivos, postularse, regalar Karma) exigen sesión real; nunca usan el modo invitado.
- **Vacantes**: `contactUrl` pasa a ser opcional porque el canal principal es "Postularme" dentro de la app.
- **Sin conexión**: Biblioteca y Práctica oficiales, foro y validación siguen funcionando con los datos semilla; lo que necesita servidor (perfiles ajenos, mensajes, cursos, adjuntos) muestra un aviso en vez de quedar en blanco.
- **Android**: el manifiesto principal declara `INTERNET` y `usesCleartextTraffic` (la API corre por `http` en la red local) y las consultas de `url_launcher`.

---

### 6. Flujo Principal de Demostración (*Happy Path Multiplataforma*)

1. **Lectura Histórica:** El usuario ingresa a la **Biblioteca** y lee el artículo de Edsger Dijkstra.
2. **Acción de Enlace:** Presiona el botón táctil / clic **"Pon en práctica su legado"**.
3. **Resolución de Reto:** Es redirigido a la **Zona de Práctica** con el reto precargado:
   - En *Móvil*, el usuario se apoya del `SymbolKeyboard` para escribir llaves y operadores.
   - En *Web*, aprovecha la vista dividida para leer el enunciado y programar a la vez.
4. **Validación y Fallo:** Se ejecuta la validación rápida (< 2s). Ante un fallo en los tests, se activa el botón **"Pedir ayuda en el foro"**.
5. **Colaboración Comunitaria:** Se abre el formulario del **Foro** con el código y título precargados. Al publicar, se otorga **+10 Karma Técnico**.
6. **Ecosistema Laboral:** Desde el perfil o el menú principal, navega al **Tablero de Vacantes** donde el estudiante visualiza ofertas según su nivel técnico.

### 6.1 Flujo de Demostración de la Red Social (v2)

1. **Perfil:** El estudiante abre su perfil, ve su **Karma**, edita su biografía y activa **"Abierto a oportunidades"** subiendo su CV.
2. **Crear contenido:** Publica un reto propio en **Práctica → Comunidad** y lo agrupa en un **curso** con un artículo suyo.
3. **Comunidad:** Su reto aparece en el feed; otros usuarios lo votan, comentan, lo guardan y hacen fork. Al acumular votos sube en el orden **"Top"** y en el ranking de creadores; su Karma aumenta.
4. **Empleo:** Un reclutador busca talento por habilidad y Karma, encuentra su perfil y le envía un **mensaje privado**; el estudiante responde adjuntando su portafolio.
5. **Postulación:** El estudiante se postula a una vacante con un clic; el publicador ve la postulación con el CV adjunto.
