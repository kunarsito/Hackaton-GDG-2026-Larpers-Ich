Actúa como un Arquitecto de Software Principal y Senior Full-Stack / Flutter Tech Lead. A partir de este momento trabajaremos sobre la siguiente definición técnica y de producto, que constituye nuestra fuente única de verdad (Single Source of Truth) para todo el desarrollo del MVP[cite: 2].

### 1. Ideación y Propuesta de Valor del Proyecto
Estamos desarrollando una **Plataforma Integral de Comunidad, Práctica y Cultura para Estudiantes Universitarios de Programación** (disponible en **Móvil Android/iOS y Web**)[cite: 2].
- **Problema:** Los estudiantes universitarios suelen aprender a programar de forma aislada, enfocándose solo en aprobar materias sin conexión con oportunidades laborales tempranas ni con el contexto histórico de los pioneros y fundamentos de la computación[cite: 2].
- **Solución (Ecosistema Vivo Conectado):** A diferencia de plataformas con secciones aisladas, nuestros tres módulos se retroalimentan en un flujo continuo (*Happy Path*)[cite: 2]:
  1. **Biblioteca Digital e Historia (`RF-01`, `RF-02`):** Artículos curados sobre pioneros e hitos de la computación (Grace Hopper, Edsger Dijkstra, Ada Lovelace) con un botón **"Pon en práctica su legado"** que lleva directo a un reto de programación vinculado[cite: 2].
  2. **Zona de Práctica Interactiva (`RF-03`, `RF-04`, `RF-05`):** Editor de código adaptativo con retos por dificultad y validación automática de casos de prueba (< 2s)[cite: 2]. Si el código falla, el estudiante presiona **"Pedir ayuda en el foro"** y se crea un hilo con su código y el enunciado precargados[cite: 2].
  3. **Comunidad y Bolsa de Trabajo Colaborativa (`RF-06`, `RF-07`, `RF-08`):** Foro técnico con bloques de código legibles, sistema de reputación (**"Karma Técnico"** al resolver retos o ayudar en hilos) y un tablero colaborativo de vacantes junior, pasantías y proyectos freelance[cite: 2].

### 2. Alcance Estricto del MVP (Qué SÍ y qué NO construir)
- **Incluido (SÍ):** 3 artículos históricos vinculados, 3 a 5 retos interactivos con validador acotado, flujo automático de "pedir ayuda con código", foro con Karma Técnico, tablero de vacantes y datos semilla (`seedData`) precargados para que la demo funcione al 100% desde el inicio[cite: 2].
- **Excluido (NO):** CMS editorial complejo, ejecución en contenedores Docker pesados para 15 lenguajes, chat de voz/video en tiempo real, pasarelas de pago o autenticación SSO universitaria[cite: 2].

### 3. Arquitectura Técnica y Stack Multiplataforma (Monorepo)
El proyecto sigue una arquitectura **Monorepo** (`app/`, `backend/`, `docs/`) preparada para desarrollo paralelo en ramas `feature/` bajo *Trunk-Based Development*[cite: 2, 3]:
- **Cliente Multiplataforma (`app/`):** **Flutter (Material 3) + Dart** compilable para **Android, iOS y Web** con diseño responsivo (`LayoutBuilder`)[cite: 2]:
  - *Móvil (`< 600 px`):* `NavigationBar` inferior y widget `SymbolKeyboard` (`{ }`, `( )`, `;`, `=`, `return`) encima del teclado táctil en la Zona de Práctica[cite: 2].
  - *Web / Desktop (`>= 600 px`):* `NavigationRail` lateral y vista dividida (enunciado a la izquierda, editor a la derecha) en la Zona de Práctica[cite: 2].
  - *Conexión API:* `api_constants.dart` detectando `kIsWeb` (`http://localhost:3000/api` en Web y `http://10.0.2.2:3000/api` en emulador Android).
- **Backend (`backend/`):** **Node.js + Express + TypeScript** (o Python + FastAPI) con **CORS habilitado** (indispensable para Flutter Web), validación acotada con *timeouts* estrictos (< 2s), y persistencia ligera en **SQLite** o capa de servicio con `seedData`[cite: 2].
- **Documentación (`docs/`):** Especificación SRS y guion de demo[cite: 2, 3].

### 4. Contratos de Datos (Entidades Principales)
Mantén exactamente estas estructuras entre los modelos de Dart (`app/lib/models/`) y el Backend (`backend/src/types/`)[cite: 2]:
- `User`: `{ id, name, university, karmaPoints, solvedChallenges: string[] }`[cite: 2]
- `Article`: `{ id, title, pioneerName, era, summary, content, relatedChallengeId }`[cite: 2]
- `Challenge`: `{ id, title, difficulty, category, description, starterCode, testCases: any[] }`[cite: 2]
- `ForumPost`: `{ id, authorId, title, body, codeSnippet, challengeId?, replies: any[], upvotes }`[cite: 2]
- `JobOpportunity`: `{ id, title, companyOrPoster, type: 'Pasantía' | 'Junior' | 'Freelance', modality, description, contactUrl }`[cite: 2]

### 5. Reglas de Colaboración e Instrucción Inicial
- Revisa el árbol actual de carpetas y archivos en el workspace antes de escribir código.
- Prioriza construir primero la **ruta vertical completa (Happy Path)**: *Leer artículo de Dijkstra $\rightarrow$ Clic en "Pon en práctica su legado" $\rightarrow$ Ejecutar/fallar reto $\rightarrow$ Clic en "Pedir ayuda en el foro" con código precargado*[cite: 2, 3].
- Confírmame que has asimilado todo este contexto técnico y dime qué archivo o módulo empezaremos a implementar primero.