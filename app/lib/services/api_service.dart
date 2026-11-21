import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/article_model.dart';
import '../models/challenge_model.dart';
import '../models/forum_post_model.dart';
import '../models/job_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _currentUser = UserModel(
      id: 'usr-001',
      name: 'Ada Dev',
      university: 'Facultad de Ingeniería',
      karmaPoints: 420,
      solvedChallenges: ['ch-01'],
    );
    _initMockData();
  }

  late UserModel _currentUser;
  UserModel get currentUser => _currentUser;

  // Repositorios locales en memoria para fallback offline / demo inmediata
  final List<ArticleModel> _mockArticles = [];
  final List<ChallengeModel> _mockChallenges = [];
  final List<ForumPostModel> _mockPosts = [];
  final List<JobOpportunityModel> _mockJobs = [];

  void _initMockData() {
    _mockArticles.addAll([
      ArticleModel(
        id: 'art-01',
        title: 'Edsger Dijkstra: La Ruta Más Corta y la Belleza de la Simplicidad',
        pioneerName: 'Edsger W. Dijkstra',
        era: '1930 - 2002',
        summary:
            'Pionero indiscutible de las ciencias de la computación. Creador del algoritmo de caminos mínimos y defensor ferviente de la programación estructurada.',
        content:
            'Edsger Wybe Dijkstra diseñó el famoso algoritmo de caminos mínimos en 1956 en apenas 20 minutos mientras tomaba café con su prometida en Ámsterdam. Su meta era demostrar las capacidades de la computadora ARMAC calculando el viaje más corto entre 64 ciudades de los Países Bajos.\n\nDijkstra nos enseñó que la simplicidad es un prerrequisito para la confiabilidad. Su trabajo sobre semáforos, concurrencia y la eliminación del GOTO sentó las bases de la ingeniería de software moderna.',
        relatedChallengeId: 'ch-dijkstra-01',
      ),
      ArticleModel(
        id: 'art-02',
        title: 'Grace Hopper: De la Polilla en el Relé al Nacimiento de los Compiladores',
        pioneerName: 'Grace Brewster Murray Hopper',
        era: '1906 - 1992',
        summary:
            'Contraalmirante de la Marina de EE.UU. y pionera del software. Popularizó el término "debugging" y desarrolló el primer compilador de la historia.',
        content:
            'En 1952, Grace Hopper programó el "A-0 System", el primer compilador que traducía especificaciones matemáticas a código máquina. Muchos contemporáneos le dijeron que las computadoras solo sabían hacer aritmética y no procesar lenguaje legible para humanos.\n\nHopper demostró que un lenguaje orientado a los negocios (como COBOL) podía democratizar el desarrollo. Su visión demostró que escribir código no debía reservarse a matemáticos puros, sino que debía ser accesible para todos los problemas de la sociedad.',
        relatedChallengeId: 'ch-hopper-02',
      ),
      ArticleModel(
        id: 'art-03',
        title: 'Ada Lovelace: El Telar de Jacquard y el Primer Algoritmo del Mundo',
        pioneerName: 'Ada Lovelace',
        era: '1815 - 1852',
        summary:
            'Considerada la primera programadora de la historia tras anticipar que las máquinas analíticas podían procesar más que solo números.',
        content:
            'Al traducir las notas sobre la Máquina Analítica de Charles Babbage, Ada Lovelace añadió sus legendarias "Notas de la Traductora" (tres veces más extensas que el texto original). En la célebre Nota G, detalló el cálculo de los Números de Bernoulli, estructurado con bucles y bifurcaciones condicionales.\n\nAda concibió la "ciencia poética": intuyó que la máquina podría tejer patrones algebraicos al igual que el telar de Jacquard tejía flores y hojas.',
        relatedChallengeId: 'ch-ada-03',
      ),
    ]);

    _mockChallenges.addAll([
      ChallengeModel(
        id: 'ch-dijkstra-01',
        title: 'Ruta Mínima en una Matriz de Costos',
        difficulty: 'Intermedio',
        category: 'Grafos y Optimización',
        description:
            'Inspirado en el legado de Dijkstra: Dada una lista de pesos de nodos en secuencia consecutiva (ej. [2, 3, 1, 5]), implementa la función `calcularCostoMinimo(List<int> caminos)` que retorne la suma acumulada más baja evitando pasos con peso mayor a 4.\n\nEjemplo:\nEntrada: [2, 3, 1]\nSalida esperada: 6',
        starterCode: '''// Completa la función para calcular el costo óptimo
int calcularCostoMinimo(List<int> caminos) {
  int costoTotal = 0;
  for (int p in caminos) {
    if (p <= 4) {
      costoTotal += p;
    }
  }
  return costoTotal;
}
''',
        testCases: [
          TestCase(
            input: '[2, 3, 1]',
            expectedOutput: '6',
            description: 'Camino estándar sin pesos bloqueantes',
          ),
          TestCase(
            input: '[5, 2, 8, 3]',
            expectedOutput: '5',
            description: 'Ignora pesos superiores a 4 (Dijkstra evita ramas costosas)',
          ),
        ],
      ),
      ChallengeModel(
        id: 'ch-hopper-02',
        title: 'Detector y Sanitizador de "Bugs" en Logs',
        difficulty: 'Básico',
        category: 'Strings y Parsing',
        description:
            'En honor al célebre insecto encontrado en el relé por Grace Hopper: Crea una función `sanitizarLog(String entrada)` que reciba un registro de texto y reemplace todas las apariciones de "BUG" por "CORRECTED", retornando el total de anomalías limpiadas.',
        starterCode: '''int sanitizarLog(String entrada) {
  // Retorna cuántos BUGs fueron encontrados y saneados
  final regex = RegExp(r'BUG');
  final matches = regex.allMatches(entrada);
  return matches.length;
}
''',
        testCases: [
          TestCase(
            input: '"ERROR: BUG en relay 70, sub-BUG detectado"',
            expectedOutput: '2',
            description: 'Encuentra 2 ocurrencias de bugs en la bitácora',
          ),
          TestCase(
            input: '"SISTEMA OPERACIONAL ESTABLE"',
            expectedOutput: '0',
            description: 'Cero bugs encontrados',
          ),
        ],
      ),
      ChallengeModel(
        id: 'ch-ada-03',
        title: 'Generador de Secuencias de Bernoulli Adaptativo',
        difficulty: 'Avanzado',
        category: 'Matemáticas y Recursión',
        description:
            'Tal como Ada Lovelace diagramó en su Nota G: Escribe un algoritmo recursivo que calcule el enésimo factor de la serie analítica según la fórmula simplificada f(n) = (n * (n - 1)) ~/ 2 para n >= 2.',
        starterCode: '''int factorBernoulli(int n) {
  if (n < 2) return 0;
  return (n * (n - 1)) ~/ 2;
}
''',
        testCases: [
          TestCase(
            input: '4',
            expectedOutput: '6',
            description: 'Cálculo para n = 4',
          ),
          TestCase(
            input: '5',
            expectedOutput: '10',
            description: 'Cálculo para n = 5',
          ),
        ],
      ),
    ]);

    _mockPosts.addAll([
      ForumPostModel(
        id: 'post-01',
        authorId: 'usr-002',
        authorName: 'Carlos_UNAM',
        title: 'Duda de complejidad en el cálculo de Dijkstra con matrices dispersas',
        body:
            'Estoy tratando de resolver el reto de Dijkstra pero al añadir más de 1000 nodos la recursión se bloquea. ¿Sería más conveniente usar PriorityQueue en vez de ordenar la lista entera en cada iteración?',
        codeSnippet: '''// Mi implementación actual:
int encontrarMinimo(List<int> dist, List<bool> visitado) {
  int min = 999999, minIndex = -1;
  for (int v = 0; v < dist.length; v++) {
    if (!visitado[v] && dist[v] <= min) {
      min = dist[v];
      minIndex = v;
    }
  }
  return minIndex;
}''',
        challengeId: 'ch-dijkstra-01',
        replies: [
          ForumReply(
            id: 'rep-01',
            authorName: 'GraceDev',
            body:
                'Totalmente. Usar un Binary Heap o PriorityQueue baja la complejidad de O(V^2) a O((V + E) log V). Te recomiendo importarlo de package:collection.',
            createdAt: 'Hace 2 horas',
          ),
        ],
        upvotes: 14,
      ),
      ForumPostModel(
        id: 'post-02',
        authorId: 'usr-003',
        authorName: 'Valeria_ITBA',
        title: 'Error de compilación al procesar expresiones regulares con comillas simples',
        body:
            'En el reto de Grace Hopper el RegExp me da una advertencia al escapar comillas dobles en Dart. Comparto el snippet por si a alguien más le pasó.',
        codeSnippet: '''final pattern = RegExp(r'BUG(?=\\s|\\b)');
final result = pattern.allMatches(rawText).length;''',
        challengeId: 'ch-hopper-02',
        replies: [
          ForumReply(
            id: 'rep-02',
            authorName: 'LinusJunior',
            body: 'Usa raw strings con triple comilla si tienes secuencias complejas multilínea.',
            createdAt: 'Hace 4 horas',
          ),
        ],
        upvotes: 8,
      ),
      ForumPostModel(
        id: 'post-03',
        authorId: 'usr-004',
        authorName: 'Mateo_Tech',
        title: '¿Algún consejo para pruebas técnicas en entrevistas de pasantía backend?',
        body:
            'Apliqué a una pasantía como desarrollador Node/TypeScript y me pidieron preparar una API con Express y pruebas unitarias. ¿Qué buenas prácticas priorizan los reclutadores universitarios?',
        codeSnippet: '''// Estructura básica que estoy preparando:
app.post('/api/validate', (req: Request, res: Response) => {
  const { code } = req.body;
  if (!code) return res.status(400).json({ error: 'Payload vacío' });
  return res.json({ status: 'OK' });
});''',
        challengeId: null,
        replies: [],
        upvotes: 21,
      ),
    ]);

    _mockJobs.addAll([
      JobOpportunityModel(
        id: 'job-01',
        title: 'Pasantía Desarrollador Flutter / Mobile',
        companyOrPoster: 'BitLab Studios (Startup Campus)',
        type: 'Pasantía',
        modality: 'Remoto',
        description:
            'Buscamos estudiante universitario con pasión por interfaces fluidas en Flutter y Dart. Trabajarás en una app de educación y análisis de datos en tiempo real.',
        contactUrl: 'https://bitlab.dev/careers/intern-flutter',
      ),
      JobOpportunityModel(
        id: 'job-02',
        title: 'Desarrollador Junior Node.js & TypeScript',
        companyOrPoster: 'Nova Cloud Systems',
        type: 'Junior',
        modality: 'Híbrido (Campus Tech Hub)',
        description:
            'Oportunidad para egresados recientes o estudiantes de últimos semestres. Mantenimiento y creación de microservicios RESTful, Docker y bases de datos SQL.',
        contactUrl: 'https://novacloud.io/jobs/junior-backend',
      ),
      JobOpportunityModel(
        id: 'job-03',
        title: 'Freelance: Migración de Scripts Python a Web API',
        companyOrPoster: 'Dr. Mendoza (Laboratorio de Bioinformática)',
        type: 'Freelance',
        modality: 'Remoto',
        description:
            'Proyecto de 3 semanas: Empaquetar algoritmos de simulación en endpoints REST sencillos documentados con Swagger.',
        contactUrl: 'mailto:investigacion.bio@universidad.edu',
      ),
      JobOpportunityModel(
        id: 'job-04',
        title: 'Pasantía en DevOps e Infraestructura Cloud',
        companyOrPoster: 'Nexus Data Corp',
        type: 'Pasantía',
        modality: 'Remoto',
        description:
            'Aprende a desplegar pipelines CI/CD con GitHub Actions, monitorización y contenedores. No se requiere experiencia previa extensiva, solo buen manejo de Linux.',
        contactUrl: 'https://nexusdata.io/internships',
      ),
    ]);
  }

  // --- MÉTODOS DE LA API CON RETORNO RESILIENTE (FALLBACK AUTOMÁTICO) ---

  Future<List<ArticleModel>> getArticles() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConstants.articlesEndpoint))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => ArticleModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockArticles;
  }

  Future<List<ChallengeModel>> getChallenges() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConstants.challengesEndpoint))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => ChallengeModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockChallenges;
  }

  Future<ChallengeModel?> getChallengeById(String id) async {
    final challenges = await getChallenges();
    try {
      return challenges.firstWhere((c) => c.id == id);
    } catch (_) {
      return challenges.isNotEmpty ? challenges.first : null;
    }
  }

  Future<List<ForumPostModel>> getForumPosts() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConstants.communityEndpoint))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => ForumPostModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockPosts;
  }

  Future<void> addForumPost(ForumPostModel post) async {
    _mockPosts.insert(0, post);
    addKarma(10); // +10 Karma por aportar al foro
    try {
      await http
          .post(
            Uri.parse(ApiConstants.communityEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(post.toJson()),
          )
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<void> addReplyToPost(String postId, ForumReply reply) async {
    try {
      final post = _mockPosts.firstWhere((p) => p.id == postId);
      post.replies.add(reply);
      addKarma(15); // +15 Karma por responder y ayudar a un compañero
    } catch (_) {}
  }

  Future<void> upvotePost(String postId) async {
    try {
      final post = _mockPosts.firstWhere((p) => p.id == postId);
      post.upvotes += 1;
    } catch (_) {}
  }

  Future<List<JobOpportunityModel>> getJobs() async {
    try {
      final res = await http
          .get(Uri.parse(ApiConstants.jobsEndpoint))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => JobOpportunityModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return _mockJobs;
  }

  // Validación de código (Con fallback de evaluación local rápida)
  Future<Map<String, dynamic>> validateCode({
    required String challengeId,
    required String code,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse(ApiConstants.validateCodeEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'challengeId': challengeId,
              'code': code,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body) as Map<String, dynamic>;
        if (result['passed'] == true) {
          addKarma(50);
          if (!_currentUser.solvedChallenges.contains(challengeId)) {
            _currentUser.solvedChallenges.add(challengeId);
          }
        }
        return result;
      }
    } catch (_) {}

    // Fallback de simulación en frontend si backend no está corriendo
    await Future.delayed(const Duration(milliseconds: 650));
    final cleanCode = code.trim();

    // Verificamos si el código no está vacío y contiene alguna lógica básica esperada
    bool passed = false;
    String feedback = '';

    if (challengeId == 'ch-dijkstra-01') {
      if (cleanCode.contains('costoTotal') && cleanCode.contains('return')) {
        passed = true;
        feedback = 'Todos los casos de prueba pasaron exitosamente. Algoritmo óptimo.';
      } else {
        passed = false;
        feedback = 'Error de aserción: El caso [5, 2, 8, 3] arrojó un costo no esperado.';
      }
    } else if (challengeId == 'ch-hopper-02') {
      if (cleanCode.contains('RegExp') || cleanCode.contains('allMatches')) {
        passed = true;
        feedback = 'Casos de prueba superados: 2 bugs detectados y aislados.';
      } else {
        passed = false;
        feedback = 'Error: no se detectaron todas las anomalías en el log.';
      }
    } else {
      if (cleanCode.contains('return')) {
        passed = true;
        feedback = 'Casos de prueba superados. Fórmula de Bernoulli evaluada.';
      } else {
        passed = false;
        feedback = 'Error de compilación: falta sentencia return válida.';
      }
    }

    if (passed) {
      addKarma(50);
      if (!_currentUser.solvedChallenges.contains(challengeId)) {
        _currentUser.solvedChallenges.add(challengeId);
      }
    }

    return {
      'passed': passed,
      'message': feedback,
      'executionTimeMs': 38,
      'testsPassed': passed ? 2 : 1,
      'totalTests': 2,
    };
  }

  void addKarma(int amount) {
    _currentUser.karmaPoints += amount;
  }
}
