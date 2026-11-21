# Backend — API REST del MVP

Node.js (>= 22.13) + Express + TypeScript + SQLite nativo de Node (`node:sqlite`, sin compilar nada).

```bash
cd backend
npm install
npm run dev      # http://localhost:3000/api  (recarga en caliente)
npm run seed     # reinicia la BD con los datos semilla
```

Opcional: `cp .env.example .env` para cambiar puerto, ruta de la BD o motor del validador.
La primera vez que arranca con la BD vacía siembra los datos solo (`data/faro.db`).

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/health` | Estado y motor del validador (`dart` / `static`) |
| GET | `/api/articles?source=official\|community&sort=top\|new&authorId=` · `/:id` · `/:id/challenge` | Biblioteca oficial y de comunidad (RF-01, RF-02, SRS §1.1) |
| POST | `/api/articles` · `/:id/vote` | Publicar artículo de comunidad (RF-10) · votar `{ value: 1\|-1\|0 }` |
| GET | `/api/challenges?source=&sort=&difficulty=&category=&authorId=` · `/:id` | Retos oficiales y de comunidad (RF-03) |
| POST | `/api/challenges` · `/:id/vote` | Crear reto `{ title, difficulty, category, description, starterCode, testCases[], forkedFromId? }` (RF-10) · votar |
| POST | `/api/challenges/validate` | `{ challengeId, code }` → `{ passed, message, executionTimeMs, testsPassed, totalTests, results[], karmaAwarded, user }` (RF-04). +10 oficial / +5 comunidad |
| GET | `/api/feed` (= `/api/community`) `?sort=top\|new&saved=me&authorId=&type=&challengeId=&q=` · `/:id` | Feed de Comunidad (RF-11, RF-13) |
| POST | `/api/community` | Crea publicación con `attachments` (ids de `/api/uploads`, máx. 4). Con `challengeId` precarga desde el reto (RF-05). +10 Karma |
| POST | `/api/posts/:id/vote` · `/save` · `/fork` | Votar (+2/−1 al autor), guardar (estrella), fork de snippet |
| POST | `/api/posts/:id/replies` · `/replies/:replyId/accept` · `/replies/:replyId/upvote` | Responder · marcar solución (sólo el autor, +15) · votar respuesta |
| GET/POST | `/api/courses?source=&sort=&authorId=&enrolled=me` · `/:id` | Cursos (RF-09). Top = mejor rating |
| POST | `/api/courses/:id/enroll` · `/complete` · `/rate` | Inscribirse · completar (exige todas las prácticas resueltas; +20 al creador) · calificar 1–5 |
| PATCH/DELETE | `/api/courses/:id` | Editar / eliminar un curso propio (autor o `admin`, con sesión; los oficiales no se tocan) |
| GET | `/api/users?sort=karma&role=creator\|recruiter&skill=&university=&q=&openToWork=true` | Ranking y búsqueda de talento (RF-13, RF-17) |
| GET/PATCH | `/api/users/me` · GET `/api/users/:id` | Perfil (RF-15). PATCH 🔒: `name, university, bio (≤300), links, skills, openToWork, cvUrl, avatarUrl` |
| POST/DELETE | `/api/users/:id/follow` · GET `/:id/followers` · `/:id/following` | Seguir |
| POST | `/api/uploads` 🔒 | Multipart, campo `file`, ≤ 10 MB, lista blanca de extensiones → `Attachment`. Se sirven en `/uploads/...` |
| GET/POST | `/api/conversations` 🔒 · `/unread` · `/:id/messages?after=` | Mensajes privados 1 a 1 (RF-16), polling |
| GET/POST | `/api/jobs?type=&modality=&q=&posterId=` · `/:id` | Bolsa de trabajo (RF-08). Publicar da el rol `recruiter` |
| POST | `/api/jobs/:id/apply` 🔒 | `{ message?, cvUrl? }` usa el CV del perfil y envía mensaje al publicador (RF-17) |
| GET/PATCH | `/api/jobs/:id/applications` 🔒 · `/applications/mine` 🔒 | Postulantes (sólo quien publicó) · mis postulaciones |
| GET/POST | `/api/karma/gift` 🔒 · GET `/api/karma/events` 🔒 | Regalar Karma (máx. 5/día, del saldo propio) · historial |
| GET | `/api/user` · `/leaderboard` · `/:id` | Compatibilidad: perfil actual (sesión; sin sesión, `x-user-id` o `usr-001`) |
| POST | `/api/user` | `{ name, university? }` crea un perfil invitado |

🔒 = exige sesión real (`Authorization: Bearer`), nunca cae al modo invitado.
| POST | `/api/auth/register` | `{ name, email, password, university? }` → `{ token, user }` (contraseña ≥ 8) |
| POST | `/api/auth/login` | `{ email, password }` → `{ token, user }` |
| POST | `/api/auth/logout` | Invalida el token |
| GET | `/api/auth/me` | Usuario de la sesión (401 si no hay o expiró) |

## Login

- Las rutas que identifican al usuario usan `Authorization: Bearer <token>`. Sin token se usa el modo invitado (`x-user-id` / usuario demo), salvo que `REQUIRE_AUTH=true`.
- Contraseñas con scrypt + sal; en la BD sólo se guarda el SHA-256 del token. Las sesiones duran 30 días.
- Cuentas de prueba (se crean solas al arrancar): `ada@faro.dev`, `carlos@faro.dev`, `valeria@faro.dev`, `mateo@faro.dev`, `grace@faro.dev` (creadora: tiene un curso y un reto de comunidad), `linus@faro.dev` y `laura@faro.dev` (reclutadora: publicó las vacantes semilla y ve sus postulantes), todas con la contraseña `DEMO_PASSWORD` (por defecto `faro1234`).

## Red social (SRS v2)

- **Migración automática**: al arrancar, `database.ts` agrega las columnas nuevas (bio, source, votos, adjuntos…) a una BD existente sin borrar datos, y `ensureSocialSeed()` completa perfiles, cursos y el reto de comunidad de la demo.
- **Karma (RF-14)**: +10 reto oficial · +5 reto de comunidad · +10 publicar · +2 por upvote / −1 por downvote recibido · +15 respuesta marcada como solución · +20 al creador por curso completado · regalos de hasta 5 al día. Cada movimiento queda en `karma_events`.
- **Archivos (RF-12)**: se guardan en `UPLOADS_DIR` (por defecto `./uploads`, ignorado por git). Sólo imágenes, PDF, ZIP y archivos de texto/código; lo que no es imagen ni PDF se sirve como descarga.

## Validador de código

Los retos están en Dart. Si el SDK de Dart está instalado (p. ej. con Flutter), el servidor
ejecuta el código del estudiante contra cada caso de prueba (`input` es un literal Dart y se
compara `resultado.toString()` con `expectedOutput`), con timeout de 2,5 s y sin permitir
`import` (sólo `dart:core`, sin acceso a archivos/red/procesos). Usa directamente
`flutter/bin/cache/dart-sdk/bin/dart.exe`: el wrapper `dart` de Flutter tarda 4–5 s en Windows.

Sin SDK cae a una validación estructural (`CODE_RUNNER=static`) que no ejecuta código.

> ⚠️ El aislamiento es ligero, pensado para demo local. No exponer el servidor a Internet tal cual.
