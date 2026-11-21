# RutaJunior

**Comunidad, práctica y empleo para estudiantes universitarios de programación.**
Proyecto del **Hackatón GDG 2026** — equipo *Larpers Ich*.

RutaJunior lleva al estudiante por una ruta continua:

**aprende** (historia de los pioneros) → **practica** (retos con validación automática) →
**pide o da ayuda** (foro con código) → **gana reputación** (Karma Técnico) →
**consigue empleo** (vacantes, CV y contacto con reclutadores).

Una sola base de código **Flutter** para **Android y Web**, con una API **Node.js + Express + TypeScript** y **SQLite**.

---

## Contenido

- [Funcionalidades](#funcionalidades)
- [Tecnologías](#tecnologías)
- [Requisitos](#requisitos)
- [Inicio rápido](#inicio-rápido)
- [1. Backend (API + base de datos)](#1-backend-api--base-de-datos)
- [2. Versión web](#2-versión-web)
- [3. Versión móvil (Android)](#3-versión-móvil-android)
- [Cuentas de prueba](#cuentas-de-prueba)
- [Configuración (`backend/.env`)](#configuración-backendenv)
- [Pruebas](#pruebas)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Problemas comunes](#problemas-comunes)
- [Documentación](#documentación)

---

## Funcionalidades

| Módulo | Qué puedes hacer |
|---|---|
| **Biblioteca** | Leer artículos sobre pioneros (Dijkstra, Grace Hopper, Ada Lovelace) y saltar a su reto con **"Pon en práctica su legado"**. Publicar artículos propios. |
| **Práctica** | Resolver retos en Dart con pruebas automáticas; en móvil, con un **teclado de símbolos** sobre el teclado táctil. Crear retos propios. |
| **Comunidad** | Feed con código y adjuntos, votos, guardados, *fork* y respuestas marcadas como solución. Si un reto falla, **"Pedir ayuda en el foro"** crea la pregunta con tu código precargado. |
| **Cursos** | Crear cursos con artículos y retos, inscribirse, calificar y gestionar **"Mis cursos"**. Un curso sólo se completa al resolver todas sus prácticas. |
| **Empleos** | Vacantes de pasantía, junior y freelance; **postularse con CV**; publicar vacantes y **buscar talento**. |
| **Perfil y mensajes** | Perfil con bio, habilidades y **Karma Técnico**, seguidores, mensajes privados y rankings. |

---

## Tecnologías

- **Frontend:** Flutter 3 (Material 3) + Dart 3 — Android y Web.
- **Backend:** Node.js 22.13+ · Express · TypeScript · `multer` (adjuntos).
- **Base de datos:** SQLite nativo de Node (`node:sqlite`), sin instalar nada extra.
- **Validador de retos:** Dart SDK en un subproceso con tiempo límite (o validación estática si no hay SDK).
- **Seguridad:** contraseñas con `scrypt` + sal y sesión con token.

---

## Requisitos

| Herramienta | Versión | Para qué |
|---|---|---|
| [Git](https://git-scm.com/) | cualquiera | Clonar el repositorio |
| [Node.js](https://nodejs.org/) | **22.13 o superior** | Backend (usa `node:sqlite`) |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | **3.x** (Dart 3) | Web y Android |
| Navegador **Chrome** o **Edge** | reciente | Versión web |
| [Android Studio](https://developer.android.com/studio) | reciente | Android (SDK, emulador y `adb`) |

Comprueba tu instalación:

```bash
node --version      # v22.13 o superior
flutter --version   # Flutter 3.x
flutter doctor      # todo en verde para Chrome/Edge y Android
```

> En Windows, si `flutter doctor` pide licencias de Android: `flutter doctor --android-licenses`.

---

## Inicio rápido

```bash
git clone https://github.com/kunarsito/Hackaton-GDG-2026-Larpers-Ich.git
cd Hackaton-GDG-2026-Larpers-Ich

# Terminal 1 — backend
cd backend
npm install
npm run dev            # http://localhost:3000/api

# Terminal 2 — web
cd app
flutter pub get
flutter run -d chrome  # o: flutter run -d edge
```

Entra con la cuenta demo **`ada@faro.dev` / `faro1234`** (o pulsa *"Entrar con cuenta demo"*).

---

## 1. Backend (API + base de datos)

```bash
cd backend
npm install
npm run dev
```

- La API queda en **http://localhost:3000/api**.
- Compruébalo abriendo **http://localhost:3000/api/health** → debe responder un JSON con `"status":"ok"`.
- La primera vez crea la base de datos `backend/data/faro.db` con datos de ejemplo
  (artículos, retos, cursos, vacantes y usuarios).
- Para reiniciar la base con los datos de ejemplo: `npm run seed`.

> **Deja esta terminal abierta** mientras usas la app: web y móvil la necesitan para guardar datos.

---

## 2. Versión web

Con el backend corriendo, en otra terminal:

```bash
cd app
flutter pub get
flutter run -d chrome        # o -d edge
```

La app detecta sola el backend en `localhost` (puertos **3000, 3001 o 3002**).

**Compilar la web para publicarla** (genera `app/build/web`):

```bash
flutter build web --release --dart-define=API_BASE_URL=https://TU-SERVIDOR/api
```

Sube el contenido de `app/build/web` a cualquier hosting estático (Firebase Hosting, Netlify, GitHub Pages…).

> La interfaz se adapta al ancho: en pantallas **< 600 px** usa la versión móvil (barra inferior y teclado de
> símbolos); en pantallas más anchas, la de escritorio (barra lateral, vista dividida y **Ctrl/Cmd + Enter**
> para ejecutar las pruebas).

---

## 3. Versión móvil (Android)

Primero arranca el [backend](#1-backend-api--base-de-datos). Luego elige **una** de estas opciones:

### Opción A — Emulador de Android (lo más sencillo)

1. En Android Studio: **Device Manager → Create device** y arráncalo.
2. Ejecuta:
   ```bash
   cd app
   flutter pub get
   flutter run
   ```
   El emulador llega a tu PC por `10.0.2.2`, así que **no hay que configurar nada**.

### Opción B — Teléfono por cable USB

1. En el teléfono: **Ajustes → Acerca del teléfono →** toca 7 veces **Número de compilación**;
   luego **Opciones de desarrollador → Depuración USB**.
2. Conecta el cable y acepta el aviso de depuración en el teléfono.
3. Redirige el puerto del teléfono hacia tu PC y ejecuta:
   ```bash
   adb devices                      # debe aparecer tu teléfono como "device"
   adb reverse tcp:3000 tcp:3000
   cd app
   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
   ```
   > Repite `adb reverse` cada vez que desconectes el cable.

### Opción C — Teléfono por Wi‑Fi (misma red que la PC)

1. Averigua la IP local de tu PC:
   - Windows: `ipconfig` → *Dirección IPv4* del adaptador Wi‑Fi.
   - macOS / Linux: `ipconfig getifaddr en0` o `hostname -I`.
2. Permite conexiones entrantes al puerto 3000 en el firewall (Windows, PowerShell como administrador):
   ```powershell
   New-NetFirewallRule -DisplayName "RutaJunior API 3000" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -Profile Private
   ```
3. Desde el navegador del teléfono abre `http://TU_IP:3000/api/health` — debe mostrar un JSON.
4. Ejecuta o compila con esa IP:
   ```bash
   cd app
   flutter run --dart-define=API_BASE_URL=http://TU_IP:3000/api
   ```

> Si cambias de red, la IP cambia: vuelve a ejecutar o compilar con la IP nueva.
> En redes públicas o de eventos que aíslan los dispositivos, usa el hotspot del teléfono.

### Generar un APK para instalar en otros teléfonos

```bash
cd app
flutter build apk --release --dart-define=API_BASE_URL=http://TU_IP:3000/api
```

El archivo queda en `app/build/app/outputs/flutter-apk/app-release.apk`. Para repartirlo por la misma red:

```bash
python -m http.server 8080 --directory build/app/outputs/flutter-apk
```

Desde el teléfono abre `http://TU_IP:8080/app-release.apk`, descárgalo e instálalo
(acepta *"Permitir desde esta fuente"*).

> **Xiaomi / Redmi / POCO:** si la instalación desde Android Studio falla con `INSTALL_FAILED_USER_RESTRICTED`,
> activa **Instalar vía USB** en Opciones de desarrollador, o instala el APK descargado desde el navegador.

### ¿Y en Android Studio?

1. **File → Open** → carpeta `app`.
2. **Settings → Languages & Frameworks → Flutter** → ruta de tu Flutter SDK.
3. **Run → Edit Configurations… → Additional run args**:
   `--dart-define=API_BASE_URL=http://localhost:3000/api` (cable) o `http://TU_IP:3000/api` (Wi‑Fi).
4. Elige tu dispositivo y pulsa **Run ▶**.

### iPhone

La carpeta `ios/` aún no está configurada. Los usuarios de iPhone pueden usar la **versión web** desde Safari.

---

## Cuentas de prueba

Contraseña de todas: **`faro1234`**

| Correo | Perfil |
|---|---|
| `ada@faro.dev` | Estudiante (cuenta demo) |
| `carlos@faro.dev`, `valeria@faro.dev`, `mateo@faro.dev`, `linus@faro.dev` | Estudiantes |
| `grace@faro.dev` | Creadora de cursos y retos |
| `laura@faro.dev` | Reclutadora (publica vacantes y busca talento) |

También puedes **registrarte** con tu propio correo.

**Sin backend:** el login ofrece *"Continuar sin conexión (modo demo)"* con datos de ejemplo en memoria
(lo que publiques así **no se guarda**).

---

## Configuración (`backend/.env`)

Es opcional. Copia la plantilla y ajusta lo que necesites:

```bash
cd backend
cp .env.example .env        # Windows PowerShell: Copy-Item .env.example .env
```

| Variable | Por defecto | Descripción |
|---|---|---|
| `PORT` | `3000` | Puerto de la API |
| `DB_PATH` | `./data/faro.db` | Archivo SQLite (`:memory:` para no guardar nada) |
| `CODE_RUNNER` | `auto` | `dart` (ejecuta los retos de verdad), `static` o `auto` |
| `DART_PATH` | — | Ruta a `dart`/`dart.exe` si no está en el PATH (p. ej. `<flutter>/bin/cache/dart-sdk/bin/dart.exe`) |
| `CODE_TIMEOUT_MS` | `2500` | Tiempo máximo por ejecución de un reto |
| `REQUIRE_AUTH` | `false` | `true` exige iniciar sesión (recomendado si el servidor es público) |
| `DEMO_PASSWORD` | `faro1234` | Contraseña de las cuentas de prueba |
| `UPLOADS_DIR` | `./uploads` | Carpeta de archivos subidos |

> Para que los retos se **ejecuten de verdad**, la API debe mostrar `"codeRunner":"dart"` en `/api/health`.
> Si muestra `"static"`, define `DART_PATH`.

---

## Pruebas

```bash
# Frontend
cd app
flutter analyze
flutter test

# Backend
cd backend
npx tsc --noEmit
```

Incluyen pruebas de desbordes de interfaz en pantallas de 320–360 px con el teclado abierto, del flujo
completo de la demo sin backend y de la pantalla de cursos.

---

## Estructura del repositorio

```
.
├── app/              # App Flutter (Android + Web)
│   ├── lib/
│   │   ├── screens/  # Pantallas (biblioteca, práctica, comunidad, cursos, empleos, perfil…)
│   │   ├── widgets/  # Componentes reutilizables (SymbolKeyboard, CodeBlockView…)
│   │   ├── services/ # ApiService: conexión con la API y modo sin conexión
│   │   └── models/   # Contratos de datos (sincronizados con el backend)
│   └── test/         # Pruebas automáticas
├── app-mobile/       # Copia de app/ (mantener sincronizada)
├── backend/          # API REST
│   └── src/
│       ├── routes/   # Endpoints /api/...
│       ├── services/ # Autenticación, Karma, validador de código
│       ├── db/       # Esquema SQLite y datos de ejemplo
│       └── types/    # Contratos de datos (TypeScript)
└── docs/             # SRS y documento de funcionalidades
```

---

## Problemas comunes

| Síntoma | Solución |
|---|---|
| La app entra en *"modo demo sin conexión"* | El backend no está corriendo o la URL es incorrecta. Comprueba `/api/health` desde el mismo dispositivo. |
| El teléfono no abre `http://TU_IP:3000/api/health` | Misma red Wi‑Fi, regla del firewall para el puerto 3000 y red marcada como *Privada*. |
| `npm install` o el backend fallan al arrancar | Necesitas **Node.js 22.13+** (`node --version`). |
| Error de puerto en uso | Cambia `PORT` en `backend/.env` y usa ese puerto en `API_BASE_URL`. La web prueba sola 3000–3002. |
| `flutter` no se reconoce | Añade `<flutter>/bin` al PATH o usa la ruta completa al ejecutable. |
| Los retos "aprueban" sin ejecutarse | `/api/health` muestra `"codeRunner":"static"`: define `DART_PATH` en `backend/.env`. |
| `App no instalada` al instalar el APK | Desinstala la versión anterior de RutaJunior y vuelve a instalar. |

---

## Documentación

- [`docs/SRS.md`](docs/SRS.md) — Especificación de requisitos (RF-01 a RF-18, contratos de datos y endpoints).
- [`docs/FUNCIONALIDADES.md`](docs/FUNCIONALIDADES.md) — Funcionalidades por pantalla, consideraciones y viabilidad.
- [`backend/README.md`](backend/README.md) — Referencia completa de la API.

---

Hecho con 💚 para el **Hackatón GDG 2026** por el equipo **Larpers Ich**.
