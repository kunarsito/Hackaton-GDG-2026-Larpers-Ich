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

---

### 2. Alcance Estricto del MVP (Qué SÍ y qué NO construir)

- **Incluido (SÍ):**
  - Módulos 100% sincronizados y responsivos para Móvil y Web.
  - 3 artículos históricos vinculados a retos prácticos.
  - 3 a 5 retos interactivos con validador aislado y timeout estricto (< 2s).
  - Flujo automatizado de "pedir ayuda con código precargado" en comunidad.
  - Sistema de Karma Técnico y tablero de vacantes.
  - Mock data / seedData embebido para garantizar ejecución offline inmediata en demostraciones, respaldado por endpoints REST en el backend.
- **Excluido (NO):**
  - CMS administrativo complejo.
  - Sandbox pesado con soporte para decenas de lenguajes de servidor (acotado a JS/Dart/algoritmos base).
  - Videollamadas o salas de streaming.
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
