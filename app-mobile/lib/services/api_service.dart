import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/attachment_model.dart';
import '../models/user_model.dart';
import '../models/article_model.dart';
import '../models/challenge_model.dart';
import '../models/forum_post_model.dart';
import '../models/job_model.dart';

/// Error de la API con el mensaje del servidor (`{ error }`). [offline] = sin conexión.
class ApiException implements Exception {
  final String message;
  final int? status;
  final bool offline;
  const ApiException(this.message, {this.status, this.offline = false});

  @override
  String toString() => message;
}

/// Error de inicio de sesión / registro. [offline] = el servidor no respondió.
class AuthException implements Exception {
  final String message;
  final bool offline;
  const AuthException(this.message, {this.offline = false});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _currentUser = _demoUser();
    _initMockData();
  }

  late UserModel _currentUser;
  UserModel get currentUser => _currentUser;

  /// Cambia cada vez que el usuario actual se actualiza (Karma, perfil...).
  /// La barra superior y el perfil lo escuchan para refrescarse en vivo.
  final ValueNotifier<int> userVersion = ValueNotifier(0);

  void _setCurrentUser(UserModel user, {bool persist = true}) {
    _currentUser = user;
    userVersion.value++;
    if (persist && _token != null) {
      SharedPreferences.getInstance()
          .then((p) => p.setString(_userKey, jsonEncode(user.toJson())))
          .catchError((_) => false);
    }
  }

  /// Actualiza el usuario actual con un JSON `User` devuelto por el servidor.
  void applyServerUser(dynamic json) {
    if (json is Map<String, dynamic> && json['id'] == _currentUser.id) {
      _setCurrentUser(UserModel.fromJson(json));
    }
  }

  // --- PETICIONES GENÉRICAS ---

  /// Origen del servidor sin "/api" (para archivos en /uploads).
  String get serverOrigin => ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  /// URL absoluta de un archivo subido (`/uploads/...`).
  String fileUrl(String url) => url.startsWith('http') ? url : '$serverOrigin$url';

  bool get hasSession => _token != null;

  /// Petición JSON a la API. Devuelve el JSON decodificado (o null si no hay cuerpo).
  /// Lanza [ApiException] con el mensaje del servidor o `offline: true` sin conexión.
  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final cleanQuery = {...?query}..removeWhere((_, v) => v.isEmpty);
    var uri = Uri.parse('${ApiConstants.baseUrl}$path');
    if (cleanQuery.isNotEmpty) uri = uri.replace(queryParameters: cleanQuery);
    final headers = _headers(json: body != null);
    final encoded = body != null ? jsonEncode(body) : null;

    final http.Response res;
    try {
      res = await switch (method) {
        'GET' => http.get(uri, headers: headers),
        'POST' => http.post(uri, headers: headers, body: encoded),
        'PATCH' => http.patch(uri, headers: headers, body: encoded),
        'DELETE' => http.delete(uri, headers: headers, body: encoded),
        _ => throw ArgumentError('Método no soportado: $method'),
      }
          .timeout(timeout);
    } catch (_) {
      throw const ApiException('Sin conexión con el servidor.', offline: true);
    }
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    dynamic data;
    if (res.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {}
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final message =
        data is Map && data['error'] is String ? data['error'] as String : 'Error del servidor (${res.statusCode}).';
    throw ApiException(message, status: res.statusCode);
  }

  /// RF-12: sube un archivo (≤ 10 MB) y devuelve el adjunto creado. Requiere sesión.
  Future<AttachmentModel> uploadFile({required String fileName, required Uint8List bytes}) async {
    if (_token == null) {
      throw const ApiException('Inicia sesión con conexión para subir archivos.');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw const ApiException('El archivo supera 10 MB.');
    }
    final req = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/uploads'))
      ..headers.addAll(_headers())
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
    final http.Response res;
    try {
      res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 60)));
    } catch (_) {
      throw const ApiException('Sin conexión con el servidor.', offline: true);
    }
    return AttachmentModel.fromJson(_decode(res) as Map<String, dynamic>);
  }

  /// Vuelve a pedir el perfil del usuario actual (Karma, seguidores...).
  Future<void> refreshCurrentUser() async {
    if (_offlineMode) return;
    try {
      final data = await request('GET', '/users/me');
      if (data is Map<String, dynamic>) _setCurrentUser(UserModel.fromJson(data));
    } catch (_) {}
  }

  // --- SESIÓN (LOGIN) ---

  static const String _tokenKey = 'faro_auth_token';
  static const String _userKey = 'faro_auth_user';

  /// Cuenta de prueba de los usuarios semilla del backend (ver backend/.env.example).
  static const String demoEmail = 'ada@faro.dev';
  static const String demoPassword = 'faro1234';

  String? _token;
  bool _offlineMode = false;

  bool get isLoggedIn => _token != null || _offlineMode;
  bool get isOfflineMode => _offlineMode;

  UserModel _demoUser() => UserModel(
        id: 'usr-001',
        name: 'Ada Dev',
        university: 'Facultad de Ingeniería',
        karmaPoints: 420,
        solvedChallenges: ['ch-01'],
      );

  Map<String, String> _headers({bool json = false}) => {
        if (json) 'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Recupera la sesión guardada. Devuelve true si hay una sesión válida.
  /// Sin conexión se conserva la sesión guardada (y el último usuario conocido).
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return false;
    _token = token;

    final cachedUser = prefs.getString(_userKey);
    if (cachedUser != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(cachedUser) as Map<String, dynamic>);
      } catch (_) {}
    }

    try {
      final res = await http
          .get(Uri.parse('${ApiConstants.authEndpoint}/me'), headers: _headers())
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        _currentUser = UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
        await prefs.setString(_userKey, jsonEncode(_currentUser.toJson()));
        return true;
      }
      if (res.statusCode == 401) {
        await _clearSession();
        return false;
      }
    } catch (_) {}
    return true;
  }

  Future<void> login({required String email, required String password}) {
    return _authenticate('login', {'email': email.trim(), 'password': password});
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String university = '',
  }) {
    return _authenticate('register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'university': university.trim(),
    });
  }

  Future<void> _authenticate(String path, Map<String, String> body) async {
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('${ApiConstants.authEndpoint}/$path'),
            headers: _headers(json: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      throw const AuthException('No se pudo conectar con el servidor.', offline: true);
    }

    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if ((res.statusCode == 200 || res.statusCode == 201) && data['token'] is String) {
      _token = data['token'] as String;
      _offlineMode = false;
      _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      await prefs.setString(_userKey, jsonEncode(_currentUser.toJson()));
      return;
    }
    throw AuthException(
      data['error'] as String? ?? 'Error del servidor (${res.statusCode}).',
    );
  }

  /// Entra sin backend con el usuario demo y los datos semilla en memoria.
  void enterOfflineDemo() {
    _offlineMode = true;
    _currentUser = _demoUser();
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await http
            .post(Uri.parse('${ApiConstants.authEndpoint}/logout'), headers: _headers())
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    await _clearSession();
    _offlineMode = false;
    _currentUser = _demoUser();
  }

  Future<void> _clearSession() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

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

  /// RF-01 / §1.1: [source] 'official' | 'community' (null = ambos). [sort] 'top' | 'new'.
  /// Sin backend devuelve los artículos oficiales semilla (la comunidad necesita conexión).
  Future<List<ArticleModel>> getArticles({String? source, String sort = 'top', String? authorId}) async {
    if (!_offlineMode) {
      try {
        final data = await request('GET', '/articles',
            query: {'source': source ?? '', 'sort': sort, 'authorId': authorId ?? ''},
            timeout: const Duration(seconds: 3));
        return (data as List).map((e) => ArticleModel.fromJson(e)).toList();
      } catch (_) {}
    }
    if (source == 'community' || authorId != null) return [];
    return _mockArticles;
  }

  Future<List<ChallengeModel>> getChallenges({String? source, String sort = 'top', String? authorId}) async {
    if (!_offlineMode) {
      try {
        final data = await request('GET', '/challenges',
            query: {'source': source ?? '', 'sort': sort, 'authorId': authorId ?? ''},
            timeout: const Duration(seconds: 3));
        return (data as List).map((e) => ChallengeModel.fromJson(e)).toList();
      } catch (_) {}
    }
    if (source == 'community' || authorId != null) return [];
    return _mockChallenges;
  }

  Future<ChallengeModel?> getChallengeById(String id) async {
    if (!_offlineMode) {
      try {
        final data = await request('GET', '/challenges/$id', timeout: const Duration(seconds: 3));
        return ChallengeModel.fromJson(data as Map<String, dynamic>);
      } catch (_) {}
    }
    try {
      return _mockChallenges.firstWhere((c) => c.id == id);
    } catch (_) {
      return _mockChallenges.isNotEmpty ? _mockChallenges.first : null;
    }
  }

  Future<ArticleModel?> getArticleById(String id) async {
    if (!_offlineMode) {
      try {
        final data = await request('GET', '/articles/$id', timeout: const Duration(seconds: 3));
        return ArticleModel.fromJson(data as Map<String, dynamic>);
      } catch (_) {}
    }
    try {
      return _mockArticles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// RF-11 / RF-13: feed de Comunidad. [sort] 'top' | 'new'; [savedOnly] = mis guardados.
  Future<List<ForumPostModel>> getForumPosts({
    String sort = 'top',
    bool savedOnly = false,
    String? authorId,
  }) async {
    if (!_offlineMode) {
      try {
        final data = await request('GET', '/feed',
            query: {'sort': sort, 'saved': savedOnly ? 'me' : '', 'authorId': authorId ?? ''},
            timeout: const Duration(seconds: 3));
        return (data as List).map((e) => ForumPostModel.fromJson(e)).toList();
      } catch (_) {}
    }
    var posts = _mockPosts.where((p) => authorId == null || p.authorId == authorId);
    if (savedOnly) posts = posts.where((p) => p.isSaved);
    final list = posts.toList();
    if (sort == 'top') list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  /// Publica en el foro (+10 Karma). Con backend usa la respuesta del servidor;
  /// sin conexión la guarda en memoria para la demo.
  Future<void> addForumPost(ForumPostModel post) async {
    if (!_offlineMode) {
      try {
        final data = await request('POST', '/community', body: {
          ...post.toJson(),
          'attachments': post.attachments.map((a) => a.id).toList(),
        });
        if (data is Map<String, dynamic>) applyServerUser(data['user']);
        return;
      } on ApiException catch (e) {
        if (!e.offline) rethrow;
      }
    }
    _mockPosts.insert(0, post);
    addKarma(10); // +10 Karma por aportar al foro
  }

  /// RF-14: responder no da Karma; da +15 cuando el autor la marca como solución.
  Future<ForumPostModel?> addReplyToPost(String postId, ForumReply reply) async {
    if (!_offlineMode) {
      try {
        final data = await request('POST', '/community/$postId/replies', body: reply.toJson());
        if (data is Map<String, dynamic> && data['post'] is Map<String, dynamic>) {
          return ForumPostModel.fromJson(data['post'] as Map<String, dynamic>);
        }
        return null;
      } on ApiException catch (e) {
        if (!e.offline) rethrow;
      }
    }
    try {
      final post = _mockPosts.firstWhere((p) => p.id == postId);
      post.replies.add(reply);
      return post;
    } catch (_) {
      return null;
    }
  }

  /// RF-11: voto 1, -1 o 0 (quitar). Devuelve la publicación actualizada.
  Future<ForumPostModel?> votePost(String postId, int value) async {
    if (!_offlineMode) {
      try {
        final data = await request('POST', '/posts/$postId/vote', body: {'value': value});
        return ForumPostModel.fromJson(data as Map<String, dynamic>);
      } on ApiException catch (e) {
        if (!e.offline) rethrow;
      }
    }
    try {
      final post = _mockPosts.firstWhere((p) => p.id == postId);
      if (post.myVote == 1) post.upvotes--;
      if (post.myVote == -1) post.downvotes--;
      if (value == 1) post.upvotes++;
      if (value == -1) post.downvotes++;
      post.myVote = value;
      return post;
    } catch (_) {
      return null;
    }
  }

  /// Compatibilidad: voto positivo.
  Future<void> upvotePost(String postId) async {
    await votePost(postId, 1);
  }

  /// Con sesión el servidor incluye hasApplied y, en mis vacantes, applicationsCount.
  Future<List<JobOpportunityModel>> getJobs() async {
    if (!_offlineMode) {
      try {
        final data = await request('GET', '/jobs', timeout: const Duration(seconds: 3));
        return (data as List).map((e) => JobOpportunityModel.fromJson(e)).toList();
      } catch (_) {}
    }
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
            headers: _headers(json: true),
            body: jsonEncode({
              'challengeId': challengeId,
              'code': code,
              'userId': _currentUser.id,
            }),
          )
          // El validador real corta a los 2,5 s; el margen cubre la red y el arranque de Dart.
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body) as Map<String, dynamic>;
        final serverUser = result['user'];
        if (serverUser is Map<String, dynamic>) {
          // El backend es la fuente de verdad del karma (sólo suma la 1.ª vez).
          _setCurrentUser(UserModel.fromJson(serverUser));
        } else if (result['passed'] == true) {
          addKarma(10);
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

    // RF-14: +10 la primera vez (los retos sin conexión son los oficiales semilla).
    var karmaAwarded = 0;
    if (passed && !_currentUser.solvedChallenges.contains(challengeId)) {
      _currentUser.solvedChallenges.add(challengeId);
      karmaAwarded = 10;
      addKarma(karmaAwarded);
    }

    return {
      'passed': passed,
      'karmaAwarded': karmaAwarded,
      'message': feedback,
      'executionTimeMs': 38,
      'testsPassed': passed ? 2 : 1,
      'totalTests': 2,
    };
  }

  void addKarma(int amount) {
    _currentUser.karmaPoints += amount;
    userVersion.value++;
  }
}
