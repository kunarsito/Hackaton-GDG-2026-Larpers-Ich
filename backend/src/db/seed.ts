/**
 * Datos semilla (RNF-03). Los IDs y textos coinciden con el fallback offline
 * de app/lib/services/api_service.dart para que el front se comporte igual
 * con o sin backend.
 *
 *   npm run seed            -> borra todo y vuelve a sembrar
 *   (arranque del servidor) -> siembra sólo si la BD está vacía
 */
import { pathToFileURL } from 'node:url';
import { getDb, transaction } from './database.js';
import type { Article, Challenge, JobOpportunity, User } from '../types/models.js';

const HOUR = 3_600_000;
const ago = (ms: number) => new Date(Date.now() - ms).toISOString();

export const seedUsers: User[] = [
  { id: 'usr-001', name: 'Ada Dev', university: 'Facultad de Ingeniería', karmaPoints: 420, solvedChallenges: [] },
  { id: 'usr-002', name: 'Carlos_UNAM', university: 'UNAM', karmaPoints: 310, solvedChallenges: ['ch-dijkstra-01'] },
  { id: 'usr-003', name: 'Valeria_ITBA', university: 'ITBA', karmaPoints: 275, solvedChallenges: ['ch-hopper-02'] },
  { id: 'usr-004', name: 'Mateo_Tech', university: 'Tec de Monterrey', karmaPoints: 190, solvedChallenges: [] },
  { id: 'usr-005', name: 'GraceDev', university: 'Universidad de Chile', karmaPoints: 860, solvedChallenges: ['ch-dijkstra-01', 'ch-hopper-02', 'ch-ada-03'] },
  { id: 'usr-006', name: 'LinusJunior', university: 'UTN', karmaPoints: 540, solvedChallenges: ['ch-hopper-02', 'ch-fizz-04'] },
];

export const seedChallenges: Challenge[] = [
  {
    id: 'ch-dijkstra-01',
    title: 'Ruta Mínima en una Matriz de Costos',
    difficulty: 'Intermedio',
    category: 'Grafos y Optimización',
    functionName: 'calcularCostoMinimo',
    description:
      'Inspirado en el legado de Dijkstra: Dada una lista de pesos de nodos en secuencia consecutiva (ej. [2, 3, 1, 5]), implementa la función `calcularCostoMinimo(List<int> caminos)` que retorne la suma acumulada más baja evitando pasos con peso mayor a 4.\n\nEjemplo:\nEntrada: [2, 3, 1]\nSalida esperada: 6',
    starterCode: `// Completa la función para calcular el costo óptimo
int calcularCostoMinimo(List<int> caminos) {
  int costoTotal = 0;
  for (int p in caminos) {
    if (p <= 4) {
      costoTotal += p;
    }
  }
  return costoTotal;
}
`,
    testCases: [
      { input: '[2, 3, 1]', expectedOutput: '6', description: 'Camino estándar sin pesos bloqueantes' },
      { input: '[5, 2, 8, 3]', expectedOutput: '5', description: 'Ignora pesos superiores a 4 (Dijkstra evita ramas costosas)' },
    ],
  },
  {
    id: 'ch-hopper-02',
    title: 'Detector y Sanitizador de "Bugs" en Logs',
    difficulty: 'Básico',
    category: 'Strings y Parsing',
    functionName: 'sanitizarLog',
    description:
      'En honor al célebre insecto encontrado en el relé por Grace Hopper: Crea una función `sanitizarLog(String entrada)` que reciba un registro de texto y reemplace todas las apariciones de "BUG" por "CORRECTED", retornando el total de anomalías limpiadas.',
    starterCode: `int sanitizarLog(String entrada) {
  // Retorna cuántos BUGs fueron encontrados y saneados
  final regex = RegExp(r'BUG');
  final matches = regex.allMatches(entrada);
  return matches.length;
}
`,
    testCases: [
      { input: '"ERROR: BUG en relay 70, sub-BUG detectado"', expectedOutput: '2', description: 'Encuentra 2 ocurrencias de bugs en la bitácora' },
      { input: '"SISTEMA OPERACIONAL ESTABLE"', expectedOutput: '0', description: 'Cero bugs encontrados' },
    ],
  },
  {
    id: 'ch-ada-03',
    title: 'Generador de Secuencias de Bernoulli Adaptativo',
    difficulty: 'Avanzado',
    category: 'Matemáticas y Recursión',
    functionName: 'factorBernoulli',
    description:
      'Tal como Ada Lovelace diagramó en su Nota G: Escribe un algoritmo recursivo que calcule el enésimo factor de la serie analítica según la fórmula simplificada f(n) = (n * (n - 1)) ~/ 2 para n >= 2.',
    starterCode: `int factorBernoulli(int n) {
  if (n < 2) return 0;
  return (n * (n - 1)) ~/ 2;
}
`,
    testCases: [
      { input: '4', expectedOutput: '6', description: 'Cálculo para n = 4' },
      { input: '5', expectedOutput: '10', description: 'Cálculo para n = 5' },
    ],
  },
  {
    id: 'ch-fizz-04',
    title: 'FizzBuzz del Laboratorio',
    difficulty: 'Básico',
    category: 'Sintaxis y Condicionales',
    functionName: 'fizzBuzz',
    description:
      'Clásico de entrevistas: implementa `fizzBuzz(int n)` que retorne "Fizz" si n es múltiplo de 3, "Buzz" si es múltiplo de 5, "FizzBuzz" si es múltiplo de ambos y, en otro caso, el número como texto.',
    starterCode: `String fizzBuzz(int n) {
  // Tu código aquí
  return '';
}
`,
    testCases: [
      { input: '3', expectedOutput: 'Fizz', description: 'Múltiplo de 3' },
      { input: '10', expectedOutput: 'Buzz', description: 'Múltiplo de 5' },
      { input: '15', expectedOutput: 'FizzBuzz', description: 'Múltiplo de 3 y 5' },
      { input: '7', expectedOutput: '7', description: 'Ni de 3 ni de 5' },
    ],
  },
  {
    id: 'ch-stack-05',
    title: 'Paréntesis Balanceados con una Pila',
    difficulty: 'Intermedio',
    category: 'Estructuras de Datos',
    functionName: 'estaBalanceado',
    description:
      'Los compiladores (como el A-0 de Hopper) deben verificar que los delimitadores cierren correctamente. Implementa `estaBalanceado(String s)` que retorne true si cada (, [ y { tiene su cierre correspondiente en el orden correcto.\n\nPista: usa una List<String> como pila.',
    starterCode: `bool estaBalanceado(String s) {
  final pila = <String>[];
  // Recorre s y usa la pila para emparejar aperturas y cierres
  return false;
}
`,
    testCases: [
      { input: '"{[()]}"', expectedOutput: 'true', description: 'Anidamiento correcto' },
      { input: '"([)]"', expectedOutput: 'false', description: 'Cierre en orden incorrecto' },
      { input: '"(("', expectedOutput: 'false', description: 'Aperturas sin cerrar' },
      { input: '""', expectedOutput: 'true', description: 'Cadena vacía' },
    ],
  },
];

export const seedArticles: Article[] = [
  {
    id: 'art-01',
    title: 'Edsger Dijkstra: La Ruta Más Corta y la Belleza de la Simplicidad',
    pioneerName: 'Edsger W. Dijkstra',
    era: '1930 - 2002',
    summary:
      'Pionero indiscutible de las ciencias de la computación. Creador del algoritmo de caminos mínimos y defensor ferviente de la programación estructurada.',
    content:
      'Edsger Wybe Dijkstra diseñó el famoso algoritmo de caminos mínimos en 1956 en apenas 20 minutos mientras tomaba café con su prometida en Ámsterdam. Su meta era demostrar las capacidades de la computadora ARMAC calculando el viaje más corto entre 64 ciudades de los Países Bajos.\n\nDijkstra nos enseñó que la simplicidad es un prerrequisito para la confiabilidad. Su trabajo sobre semáforos, concurrencia y la eliminación del GOTO sentó las bases de la ingeniería de software moderna.',
    relatedChallengeId: 'ch-dijkstra-01',
  },
  {
    id: 'art-02',
    title: 'Grace Hopper: De la Polilla en el Relé al Nacimiento de los Compiladores',
    pioneerName: 'Grace Brewster Murray Hopper',
    era: '1906 - 1992',
    summary:
      'Contraalmirante de la Marina de EE.UU. y pionera del software. Popularizó el término "debugging" y desarrolló el primer compilador de la historia.',
    content:
      'En 1952, Grace Hopper programó el "A-0 System", el primer compilador que traducía especificaciones matemáticas a código máquina. Muchos contemporáneos le dijeron que las computadoras solo sabían hacer aritmética y no procesar lenguaje legible para humanos.\n\nHopper demostró que un lenguaje orientado a los negocios (como COBOL) podía democratizar el desarrollo. Su visión demostró que escribir código no debía reservarse a matemáticos puros, sino que debía ser accesible para todos los problemas de la sociedad.',
    relatedChallengeId: 'ch-hopper-02',
  },
  {
    id: 'art-03',
    title: 'Ada Lovelace: El Telar de Jacquard y el Primer Algoritmo del Mundo',
    pioneerName: 'Ada Lovelace',
    era: '1815 - 1852',
    summary:
      'Considerada la primera programadora de la historia tras anticipar que las máquinas analíticas podían procesar más que solo números.',
    content:
      'Al traducir las notas sobre la Máquina Analítica de Charles Babbage, Ada Lovelace añadió sus legendarias "Notas de la Traductora" (tres veces más extensas que el texto original). En la célebre Nota G, detalló el cálculo de los Números de Bernoulli, estructurado con bucles y bifurcaciones condicionales.\n\nAda concibió la "ciencia poética": intuyó que la máquina podría tejer patrones algebraicos al igual que el telar de Jacquard tejía flores y hojas.',
    relatedChallengeId: 'ch-ada-03',
  },
];

interface SeedPost {
  id: string;
  authorId: string;
  title: string;
  body: string;
  codeSnippet: string;
  challengeId: string | null;
  upvotes: number;
  createdAgoMs: number;
  replies: { id: string; authorId: string; body: string; upvotes: number; createdAgoMs: number }[];
}

export const seedPosts: SeedPost[] = [
  {
    id: 'post-01',
    authorId: 'usr-002',
    title: 'Duda de complejidad en el cálculo de Dijkstra con matrices dispersas',
    body: 'Estoy tratando de resolver el reto de Dijkstra pero al añadir más de 1000 nodos la recursión se bloquea. ¿Sería más conveniente usar PriorityQueue en vez de ordenar la lista entera en cada iteración?',
    codeSnippet: `// Mi implementación actual:
int encontrarMinimo(List<int> dist, List<bool> visitado) {
  int min = 999999, minIndex = -1;
  for (int v = 0; v < dist.length; v++) {
    if (!visitado[v] && dist[v] <= min) {
      min = dist[v];
      minIndex = v;
    }
  }
  return minIndex;
}`,
    challengeId: 'ch-dijkstra-01',
    upvotes: 14,
    createdAgoMs: 3 * HOUR,
    replies: [
      {
        id: 'rep-01',
        authorId: 'usr-005',
        body: 'Totalmente. Usar un Binary Heap o PriorityQueue baja la complejidad de O(V^2) a O((V + E) log V). Te recomiendo importarlo de package:collection.',
        upvotes: 6,
        createdAgoMs: 2 * HOUR,
      },
    ],
  },
  {
    id: 'post-02',
    authorId: 'usr-003',
    title: 'Error de compilación al procesar expresiones regulares con comillas simples',
    body: 'En el reto de Grace Hopper el RegExp me da una advertencia al escapar comillas dobles en Dart. Comparto el snippet por si a alguien más le pasó.',
    codeSnippet: `final pattern = RegExp(r'BUG(?=\\s|\\b)');
final result = pattern.allMatches(rawText).length;`,
    challengeId: 'ch-hopper-02',
    upvotes: 8,
    createdAgoMs: 5 * HOUR,
    replies: [
      {
        id: 'rep-02',
        authorId: 'usr-006',
        body: 'Usa raw strings con triple comilla si tienes secuencias complejas multilínea.',
        upvotes: 3,
        createdAgoMs: 4 * HOUR,
      },
    ],
  },
  {
    id: 'post-03',
    authorId: 'usr-004',
    title: '¿Algún consejo para pruebas técnicas en entrevistas de pasantía backend?',
    body: 'Apliqué a una pasantía como desarrollador Node/TypeScript y me pidieron preparar una API con Express y pruebas unitarias. ¿Qué buenas prácticas priorizan los reclutadores universitarios?',
    codeSnippet: `// Estructura básica que estoy preparando:
app.post('/api/validate', (req: Request, res: Response) => {
  const { code } = req.body;
  if (!code) return res.status(400).json({ error: 'Payload vacío' });
  return res.json({ status: 'OK' });
});`,
    challengeId: null,
    upvotes: 21,
    createdAgoMs: 26 * HOUR,
    replies: [],
  },
];

export const seedJobs: JobOpportunity[] = [
  {
    id: 'job-01',
    title: 'Pasantía Desarrollador Flutter / Mobile',
    companyOrPoster: 'BitLab Studios (Startup Campus)',
    type: 'Pasantía',
    modality: 'Remoto',
    description:
      'Buscamos estudiante universitario con pasión por interfaces fluidas en Flutter y Dart. Trabajarás en una app de educación y análisis de datos en tiempo real.',
    requirements: ['Dart / Flutter básico', 'Git', 'Disponibilidad de 20 h/semana'],
    contactUrl: 'https://bitlab.dev/careers/intern-flutter',
  },
  {
    id: 'job-02',
    title: 'Desarrollador Junior Node.js & TypeScript',
    companyOrPoster: 'Nova Cloud Systems',
    type: 'Junior',
    modality: 'Híbrido (Campus Tech Hub)',
    description:
      'Oportunidad para egresados recientes o estudiantes de últimos semestres. Mantenimiento y creación de microservicios RESTful, Docker y bases de datos SQL.',
    requirements: ['Node.js + TypeScript', 'SQL', 'Nociones de Docker'],
    contactUrl: 'https://novacloud.io/jobs/junior-backend',
  },
  {
    id: 'job-03',
    title: 'Freelance: Migración de Scripts Python a Web API',
    companyOrPoster: 'Dr. Mendoza (Laboratorio de Bioinformática)',
    type: 'Freelance',
    modality: 'Remoto',
    description:
      'Proyecto de 3 semanas: Empaquetar algoritmos de simulación en endpoints REST sencillos documentados con Swagger.',
    requirements: ['Python', 'FastAPI o Flask', 'OpenAPI / Swagger'],
    contactUrl: 'mailto:investigacion.bio@universidad.edu',
  },
  {
    id: 'job-04',
    title: 'Pasantía en DevOps e Infraestructura Cloud',
    companyOrPoster: 'Nexus Data Corp',
    type: 'Pasantía',
    modality: 'Remoto',
    description:
      'Aprende a desplegar pipelines CI/CD con GitHub Actions, monitorización y contenedores. No se requiere experiencia previa extensiva, solo buen manejo de Linux.',
    requirements: ['Linux', 'Bash', 'Ganas de aprender CI/CD'],
    contactUrl: 'https://nexusdata.io/internships',
  },
];

export function isDatabaseEmpty(): boolean {
  const row = getDb().prepare('SELECT COUNT(*) AS n FROM challenges').get() as { n: number };
  return row.n === 0;
}

export function seedDatabase({ reset = false }: { reset?: boolean } = {}): void {
  const db = getDb();

  transaction(() => {
    if (reset) {
      for (const t of ['forum_replies', 'forum_posts', 'solved_challenges', 'articles', 'jobs', 'challenges', 'users']) {
        db.exec(`DELETE FROM ${t}`);
      }
    }

    const insUser = db.prepare('INSERT INTO users (id, name, university, karma_points) VALUES (?, ?, ?, ?)');
    for (const u of seedUsers) insUser.run(u.id, u.name, u.university, u.karmaPoints);

    const insCh = db.prepare(
      `INSERT INTO challenges (id, title, difficulty, category, description, starter_code, function_name, test_cases, sort_order)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    );
    seedChallenges.forEach((c, i) =>
      insCh.run(c.id, c.title, c.difficulty, c.category, c.description, c.starterCode, c.functionName, JSON.stringify(c.testCases), i),
    );

    const insSolved = db.prepare('INSERT INTO solved_challenges (user_id, challenge_id) VALUES (?, ?)');
    for (const u of seedUsers) for (const ch of u.solvedChallenges) insSolved.run(u.id, ch);

    const insArt = db.prepare(
      `INSERT INTO articles (id, title, pioneer_name, era, summary, content, related_challenge_id, sort_order)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    );
    seedArticles.forEach((a, i) =>
      insArt.run(a.id, a.title, a.pioneerName, a.era, a.summary, a.content, a.relatedChallengeId, i),
    );

    const nameOf = (id: string) => seedUsers.find((u) => u.id === id)?.name ?? 'Estudiante Dev';
    const insPost = db.prepare(
      `INSERT INTO forum_posts (id, author_id, author_name, title, body, code_snippet, challenge_id, upvotes, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    );
    const insReply = db.prepare(
      `INSERT INTO forum_replies (id, post_id, author_id, author_name, body, upvotes, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    );
    for (const p of seedPosts) {
      insPost.run(p.id, p.authorId, nameOf(p.authorId), p.title, p.body, p.codeSnippet, p.challengeId, p.upvotes, ago(p.createdAgoMs));
      for (const r of p.replies) {
        insReply.run(r.id, p.id, r.authorId, nameOf(r.authorId), r.body, r.upvotes, ago(r.createdAgoMs));
      }
    }

    const insJob = db.prepare(
      `INSERT INTO jobs (id, title, company_or_poster, type, modality, description, requirements, contact_url, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    );
    seedJobs.forEach((j, i) =>
      insJob.run(j.id, j.title, j.companyOrPoster, j.type, j.modality, j.description, JSON.stringify(j.requirements ?? []), j.contactUrl, ago((i + 1) * 24 * HOUR)),
    );
  });
}

// `npm run seed` -> reinicia la base con los datos semilla
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    process.loadEnvFile();
  } catch {
    /* sin .env: valores por defecto */
  }
  seedDatabase({ reset: true });
  console.log('✔ Base de datos reiniciada con datos semilla');
}
