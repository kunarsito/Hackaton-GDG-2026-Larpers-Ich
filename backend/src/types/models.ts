/**
 * Contratos de datos compartidos con el cliente Flutter (app/lib/models/).
 * Mantener los nombres de campo EXACTAMENTE iguales a los de los modelos Dart
 * (SRS §4.2 y §5.1). Los campos marcados "por usuario" dependen de quién pide
 * (myVote, isSaved, isFollowing...) y no se guardan tal cual en la BD.
 */

export type Difficulty = 'Básico' | 'Intermedio' | 'Avanzado';
export type JobType = 'Pasantía' | 'Junior' | 'Freelance';
export type ContentSource = 'official' | 'community';
export type Role = 'student' | 'creator' | 'recruiter' | 'admin';
export type PostType = 'post' | 'question' | 'challenge' | 'course' | 'snippet' | 'article';

export interface UserLinks {
  github?: string;
  linkedin?: string;
  website?: string;
}

export interface User {
  id: string;
  name: string;
  university: string;
  karmaPoints: number;
  solvedChallenges: string[];
  roles: Role[];
  avatarUrl?: string;
  /** Máx. 300 caracteres (RF-15). */
  bio: string;
  links: UserLinks;
  skills: string[];
  followers: number;
  following: number;
  openToWork: boolean;
  /** PDF subido con /api/uploads. */
  cvUrl?: string;
  /** Por usuario: si quien pide sigue a este perfil. */
  isFollowing?: boolean;
}

export interface Article {
  id: string;
  title: string;
  pioneerName: string;
  era: string;
  summary: string;
  content: string;
  relatedChallengeId: string;
  source: ContentSource;
  authorId?: string;
  authorName?: string;
  upvotes: number;
  downvotes: number;
  createdAt: string;
  /** Por usuario: 1, -1 o 0. */
  myVote?: number;
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
  source: ContentSource;
  authorId?: string;
  authorName?: string;
  upvotes: number;
  downvotes: number;
  forkedFromId?: string;
  createdAt: string;
  myVote?: number;
}

export interface CourseLesson {
  order: number;
  title: string;
  articleId?: string;
  challengeId?: string;
}

export interface Course {
  id: string;
  source: ContentSource;
  authorId?: string;
  authorName?: string;
  title: string;
  description: string;
  coverUrl?: string;
  level: Difficulty;
  tags: string[];
  lessons: CourseLesson[];
  /** 0–5 */
  ratingAvg: number;
  ratingCount: number;
  enrolledCount: number;
  createdAt: string;
  /** Por usuario */
  isEnrolled?: boolean;
  isCompleted?: boolean;
  myRating?: number;
}

export interface Attachment {
  id: string;
  fileName: string;
  mimeType: string;
  /** ≤ 10 MB */
  sizeBytes: number;
  /** Ruta relativa al servidor: /uploads/<archivo> */
  url: string;
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
  type: PostType;
  downvotes: number;
  attachments: Attachment[];
  savedCount: number;
  forkedFromId?: string;
  /** Respuesta marcada como solución (RF-14: +15 Karma). */
  acceptedReplyId?: string;
  /** Id del reto/curso/artículo que anuncia la publicación. */
  refId?: string;
  /** Por usuario */
  myVote?: number;
  isSaved?: boolean;
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
  posterId?: string;
  /** Por usuario */
  hasApplied?: boolean;
  /** Sólo para quien publicó la vacante. */
  applicationsCount?: number;
}

/** Resumen público de un usuario para listas (mensajes, postulantes, ranking). */
export interface UserSummary {
  id: string;
  name: string;
  university: string;
  avatarUrl?: string;
  karmaPoints: number;
}

export interface Conversation {
  id: string;
  participantIds: [string, string];
  lastMessageAt: string;
  unreadCount: number;
  otherUser: UserSummary;
  lastMessage?: string;
}

export interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  body: string;
  attachments: Attachment[];
  createdAt: string;
  readAt?: string;
}

export type ApplicationStatus = 'enviada' | 'vista' | 'contactado';

export interface JobApplication {
  id: string;
  jobId: string;
  applicantId: string;
  cvUrl: string;
  message: string;
  status: ApplicationStatus;
  createdAt: string;
  applicant?: UserSummary;
  jobTitle?: string;
}

export type KarmaReason =
  | 'challenge_official'
  | 'challenge_community'
  | 'post_created'
  | 'upvote'
  | 'downvote'
  | 'accepted_answer'
  | 'course_completed'
  | 'gift';

export interface KarmaEvent {
  id: string;
  userId: string;
  amount: number;
  reason: KarmaReason;
  fromUserId?: string;
  createdAt: string;
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
