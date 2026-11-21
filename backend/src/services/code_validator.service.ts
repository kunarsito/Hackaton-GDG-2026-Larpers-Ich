/**
 * RF-04 Validador de soluciones.
 *
 * Los retos se escriben en Dart (igual que el editor del front). Dos motores:
 *  - "dart":   genera un harness con el código del estudiante + una llamada por
 *              caso de prueba y lo ejecuta con el SDK de Dart local, con timeout
 *              estricto y sin permitir imports (sólo dart:core => sin E/S).
 *  - "static": si no hay SDK, revisión estructural (firma, return, llaves,
 *              valor fijo de plantilla). No ejecuta nada.
 */
import { execFile } from 'node:child_process';
import { existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { delimiter, join } from 'node:path';
import type { Challenge, TestResult, ValidationResult } from '../types/models.js';

const MARKER = '@@FARO@@';
const MAX_CODE_LENGTH = 20_000;
const isWindows = process.platform === 'win32';

type Verdict = Omit<ValidationResult, 'karmaAwarded' | 'user'>;

// ---------------------------------------------------------------------------
// Localización del SDK de Dart
// ---------------------------------------------------------------------------

let dartPathCache: string | null | undefined;

/** Prefiere el binario dentro de dart-sdk/bin: el wrapper de Flutter tarda 4-5 s en Windows. */
export function findDart(): string | null {
  if (dartPathCache !== undefined) return dartPathCache;

  const exe = isWindows ? 'dart.exe' : 'dart';
  const candidates: string[] = [];
  if (process.env.DART_PATH) candidates.push(process.env.DART_PATH);

  for (const dir of (process.env.PATH ?? '').split(delimiter).filter(Boolean)) {
    // flutter/bin -> flutter/bin/cache/dart-sdk/bin/dart(.exe)
    candidates.push(join(dir, 'cache', 'dart-sdk', 'bin', exe));
    // dart-sdk/bin directamente en PATH
    candidates.push(join(dir, exe));
  }

  dartPathCache = candidates.find((p) => existsSync(p)) ?? null;
  return dartPathCache;
}

export function activeEngine(): 'dart' | 'static' {
  const mode = (process.env.CODE_RUNNER ?? 'auto').toLowerCase();
  if (mode === 'static') return 'static';
  if (mode === 'dart' && !findDart()) {
    throw new Error('CODE_RUNNER=dart pero no se encontró el SDK de Dart (define DART_PATH).');
  }
  return findDart() ? 'dart' : 'static';
}

const timeoutMs = () => Number(process.env.CODE_TIMEOUT_MS ?? 2500);

// ---------------------------------------------------------------------------
// Sandbox ligero
// ---------------------------------------------------------------------------

/** Devuelve un mensaje de error si el código no es aceptable para ejecutar. */
function rejectReason(code: string): string | null {
  if (!code.trim()) return 'El código está vacío.';
  if (code.length > MAX_CODE_LENGTH) return `El código supera el máximo de ${MAX_CODE_LENGTH} caracteres.`;
  if (/^\s*(import|export|part|library)\b/m.test(code)) {
    return 'Por seguridad no se permiten directivas import/export/part/library: sólo está disponible dart:core.';
  }
  if (/['"](dart|package):/.test(code)) return 'No se permite referenciar librerías externas (dart:/package:).';
  return null;
}

// ---------------------------------------------------------------------------
// Motor Dart
// ---------------------------------------------------------------------------

function buildHarness(code: string, challenge: Challenge): string {
  // Si el estudiante declaró su propio main(), lo renombramos para no chocar con el harness.
  const userCode = code.replace(/^(\s*(?:void|Future<void>|dynamic)?\s*)main\s*\(/m, '$1__faroUserMain(');
  const calls = challenge.testCases.map((tc) => `    () => ${challenge.functionName}(${tc.input}),`).join('\n');

  return `${userCode}

String __faroFmt(Object? v) => v.toString().replaceAll('\\n', r'\\n');

void main() {
  final __cases = <Object? Function()>[
${calls}
  ];
  for (var i = 0; i < __cases.length; i++) {
    try {
      print('${MARKER}|\$i|OK|\${__faroFmt(__cases[i]())}');
    } catch (e) {
      print('${MARKER}|\$i|ERR|\${__faroFmt(e)}');
    }
  }
}
`;
}

interface RunOutput {
  stdout: string;
  stderr: string;
  timedOut: boolean;
  exitCode: number | null;
}

function runDart(source: string): Promise<RunOutput> {
  const dart = findDart()!;
  const dir = join(tmpdir(), 'faro-runner');
  mkdirSync(dir, { recursive: true });
  const file = join(dir, `run_${Date.now()}_${Math.random().toString(36).slice(2, 8)}.dart`);
  writeFileSync(file, source, 'utf8');

  return new Promise((resolve) => {
    execFile(
      dart,
      [file],
      { timeout: timeoutMs(), killSignal: 'SIGKILL', maxBuffer: 1024 * 1024, cwd: dir, windowsHide: true },
      (err, stdout, stderr) => {
        rmSync(file, { force: true });
        const e = err as (NodeJS.ErrnoException & { killed?: boolean; code?: number | string }) | null;
        resolve({
          stdout: String(stdout),
          stderr: String(stderr),
          timedOut: Boolean(e?.killed),
          exitCode: e ? (typeof e.code === 'number' ? e.code : 1) : 0,
        });
      },
    );
  });
}

/** Limpia los mensajes de compilación: quita la ruta temporal y deja "línea X:Y". */
function cleanCompilerErrors(stderr: string): string {
  const lines = stderr
    .split(/\r?\n/)
    .filter((l) => /Error:/.test(l))
    .map((l) => l.replace(/^.*?run_[\w]+\.dart:(\d+):(\d+):\s*/, 'Línea $1:$2 — '))
    .slice(0, 3);
  return lines.length ? lines.join('\n') : stderr.trim().split(/\r?\n/).slice(0, 3).join('\n');
}

async function validateWithDart(code: string, challenge: Challenge): Promise<Verdict> {
  const started = Date.now();
  const total = challenge.testCases.length;
  const out = await runDart(buildHarness(code, challenge));
  const executionTimeMs = Date.now() - started;

  const base = { executionTimeMs, totalTests: total, engine: 'dart' as const };

  if (out.timedOut) {
    return {
      ...base,
      passed: false,
      testsPassed: 0,
      results: [],
      message: `Tiempo límite excedido (${timeoutMs()} ms). Revisa si hay un bucle infinito o una recursión sin caso base.`,
    };
  }

  const byIndex = new Map<number, { ok: boolean; value: string }>();
  for (const line of out.stdout.split(/\r?\n/)) {
    if (!line.startsWith(MARKER)) continue;
    const [, idx, status, ...rest] = line.split('|');
    byIndex.set(Number(idx), { ok: status === 'OK', value: rest.join('|').trim() });
  }

  if (byIndex.size === 0) {
    return {
      ...base,
      passed: false,
      testsPassed: 0,
      results: [],
      message: `Error de compilación:\n${cleanCompilerErrors(out.stderr || out.stdout)}`,
    };
  }

  const results: TestResult[] = challenge.testCases.map((tc, i) => {
    const r = byIndex.get(i);
    if (!r) return { ...tc, actualOutput: null, passed: false, error: 'Sin resultado' };
    if (!r.ok) return { ...tc, actualOutput: null, passed: false, error: r.value };
    return { ...tc, actualOutput: r.value, passed: r.value === tc.expectedOutput.trim() };
  });

  const testsPassed = results.filter((r) => r.passed).length;
  const firstFail = results.findIndex((r) => !r.passed);

  let message: string;
  if (firstFail === -1) {
    message = `¡Todos los casos de prueba pasaron! (${testsPassed}/${total}) en ${executionTimeMs} ms.`;
  } else {
    const f = results[firstFail];
    const got = f.error ? `lanzó una excepción: ${f.error}` : `obtenido ${f.actualOutput}`;
    message =
      `Falló el caso ${firstFail + 1} de ${total} (${f.description}).\n` +
      `Entrada: ${f.input} → esperado ${f.expectedOutput}, ${got}.`;
  }

  return { ...base, passed: firstFail === -1, testsPassed, results, message };
}

// ---------------------------------------------------------------------------
// Motor estático (fallback sin SDK)
// ---------------------------------------------------------------------------

function isBalanced(code: string): boolean {
  // Ignora strings y comentarios de forma aproximada.
  const stripped = code
    .replace(/\/\/.*$/gm, '')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/r?'(?:\\.|[^'\\])*'|r?"(?:\\.|[^"\\])*"/g, '""');
  const pairs: Record<string, string> = { ')': '(', ']': '[', '}': '{' };
  const stack: string[] = [];
  for (const ch of stripped) {
    if ('([{'.includes(ch)) stack.push(ch);
    else if (ch in pairs && stack.pop() !== pairs[ch]) return false;
  }
  return stack.length === 0;
}

function validateStatically(code: string, challenge: Challenge): Verdict {
  const started = Date.now();
  const total = challenge.testCases.length;
  const fn = challenge.functionName;
  const problems: string[] = [];

  if (!new RegExp(`\\b${fn}\\s*\\(`).test(code)) problems.push(`No se encontró la función \`${fn}\`.`);
  if (!/\breturn\b/.test(code) && !/=>/.test(code)) problems.push('Falta una sentencia return.');
  if (!isBalanced(code)) problems.push('Paréntesis, corchetes o llaves sin cerrar.');

  const returns = code.match(/\breturn\b[^;]*;/g) ?? [];
  const placeholder = /^return\s*(''|""|false|0|null)?\s*;$/;
  if (returns.length > 0 && returns.every((r) => placeholder.test(r.trim()))) {
    problems.push('La función sólo retorna el valor fijo de la plantilla: implementa la lógica.');
  }

  const passed = problems.length === 0;
  return {
    passed,
    engine: 'static',
    executionTimeMs: Date.now() - started,
    totalTests: total,
    testsPassed: passed ? total : 0,
    results: challenge.testCases.map((tc) => ({ ...tc, actualOutput: null, passed })),
    message: passed
      ? `Validación estructural superada (${total}/${total}). Nota: el servidor no tiene SDK de Dart, el código no se ejecutó.`
      : `Error: ${problems.join(' ')}`,
  };
}

// ---------------------------------------------------------------------------
// API pública
// ---------------------------------------------------------------------------

export async function validateSolution(code: string, challenge: Challenge): Promise<Verdict> {
  const reason = rejectReason(code);
  if (reason) {
    return {
      passed: false,
      message: reason,
      executionTimeMs: 0,
      testsPassed: 0,
      totalTests: challenge.testCases.length,
      results: [],
      engine: activeEngine(),
    };
  }
  return activeEngine() === 'dart' ? validateWithDart(code, challenge) : validateStatically(code, challenge);
}

/** Ejecuta un programa trivial para que la primera validación real no pague el arranque en frío. */
export async function warmUpRunner(): Promise<void> {
  if (activeEngine() !== 'dart') return;
  const t = Date.now();
  await runDart('void main() => print("ok");');
  console.log(`  Dart listo en ${Date.now() - t} ms (${findDart()})`);
}
