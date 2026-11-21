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
| GET | `/api/articles` · `/:id` · `/:id/challenge` | Biblioteca (RF-01) y reto vinculado (RF-02) |
| GET | `/api/challenges?difficulty=&category=` · `/:id` | Catálogo de retos (RF-03) |
| POST | `/api/challenges/validate` | `{ challengeId, code, userId? }` → `{ passed, message, executionTimeMs, testsPassed, totalTests, results[], karmaAwarded, user }` (RF-04) |
| GET | `/api/community?challengeId=&q=` · `/:id` | Foro (RF-06) |
| POST | `/api/community` | Crea hilo. Con `challengeId` y sin título/cuerpo, los precarga desde el reto (RF-05). +10 karma |
| POST | `/api/community/:id/replies` | Responde. +15 karma |
| POST | `/api/community/:id/upvote` · `/:id/replies/:replyId/upvote` | Voto positivo, +5 karma al autor (RF-07) |
| GET/POST | `/api/jobs?type=&modality=&q=` · `/:id` | Bolsa de trabajo (RF-08) |
| GET | `/api/user` · `/leaderboard` · `/:id` | Perfil actual (sesión; sin sesión, cabecera `x-user-id` o `usr-001`) |
| POST | `/api/user` | `{ name, university? }` crea un perfil invitado |
| POST | `/api/auth/register` | `{ name, email, password, university? }` → `{ token, user }` (contraseña ≥ 8) |
| POST | `/api/auth/login` | `{ email, password }` → `{ token, user }` |
| POST | `/api/auth/logout` | Invalida el token |
| GET | `/api/auth/me` | Usuario de la sesión (401 si no hay o expiró) |

## Login

- Las rutas que identifican al usuario usan `Authorization: Bearer <token>`. Sin token se usa el modo invitado (`x-user-id` / usuario demo), salvo que `REQUIRE_AUTH=true`.
- Contraseñas con scrypt + sal; en la BD sólo se guarda el SHA-256 del token. Las sesiones duran 30 días.
- Cuentas de prueba (se crean solas al arrancar): `ada@faro.dev`, `carlos@faro.dev`, `valeria@faro.dev`, `mateo@faro.dev`, `grace@faro.dev`, `linus@faro.dev`, todas con la contraseña `DEMO_PASSWORD` (por defecto `faro1234`).

## Validador de código

Los retos están en Dart. Si el SDK de Dart está instalado (p. ej. con Flutter), el servidor
ejecuta el código del estudiante contra cada caso de prueba (`input` es un literal Dart y se
compara `resultado.toString()` con `expectedOutput`), con timeout de 2,5 s y sin permitir
`import` (sólo `dart:core`, sin acceso a archivos/red/procesos). Usa directamente
`flutter/bin/cache/dart-sdk/bin/dart.exe`: el wrapper `dart` de Flutter tarda 4–5 s en Windows.

Sin SDK cae a una validación estructural (`CODE_RUNNER=static`) que no ejecuta código.

> ⚠️ El aislamiento es ligero, pensado para demo local. No exponer el servidor a Internet tal cual.
