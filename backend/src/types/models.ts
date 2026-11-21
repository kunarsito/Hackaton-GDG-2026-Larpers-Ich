/**
 * Contratos de datos compartidos con el cliente Flutter (app/lib/models/).
 * Mantener los nombres de campo EXACTAMENTE iguales a los de los modelos Dart.
 */

export type Difficulty = 'Básico' | 'Intermedio' | 'Avanzado';
export type JobType = 'Pasantía' | 'Junior' | 'Freelance';

export interface User {
  id: string;
  name: string;
  university: string;
  karmaPoints: number;
  solvedChallenges: string[];
}

export interface Article {
  id: string;
  title: string;
  pioneerName: string;
  era: string;
  summary: string;
  content: string;
  relatedChallengeId: string;
}

export interface TestCase {
  /** Literal Dart que se pasa como argumento a la función, p. ej. "[2, 3, 1]" o "\"texto\"". */
  input: string;
  /** Resultado esperado de `resultado.toString()`. */
  expectedOutput: string;
  description: string;
}

export interface Challenge {
  id: string;
  title: string;
  difficulty: Difficulty;
  category: string;
  description: string;
  starterCode: string;
  testCases: TestCase[];
  /** Extra del backend (el front lo ignora): función que el validador invoca. */
  functionName: string;
}

export interface ForumReply {
  id: string;
  authorId?: string;
  authorName: string;
  body: string;
  /** Texto legible ("Hace 2 horas"), tal como lo muestra el front. */
  createdAt: string;
  upvotes?: number;
}

export interface ForumPost {
  id: string;
  authorId: string;
  authorName: string;
  title: string;
  body: string;
  codeSnippet: string;
  challengeId: string | null;
  replies: ForumReply[];
  upvotes: number;
  createdAt?: string;
}

export interface JobOpportunity {
  id: string;
  title: string;
  companyOrPoster: string;
  type: JobType;
  modality: string;
  description: string;
  contactUrl: string;
  requirements?: string[];
  createdAt?: string;
}

export interface TestResult {
  description: string;
  input: string;
  expectedOutput: string;
  actualOutput: string | null;
  passed: boolean;
  error?: string;
}

/** Respuesta de POST /api/challenges/validate (el front lee passed, message, executionTimeMs, testsPassed, totalTests). */
export interface ValidationResult {
  passed: boolean;
  message: string;
  executionTimeMs: number;
  testsPassed: number;
  totalTests: number;
  results: TestResult[];
  engine: 'dart' | 'static';
  karmaAwarded?: number;
  user?: User;
}
