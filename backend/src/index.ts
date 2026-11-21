import express, { type NextFunction, type Request, type Response } from 'express';
import cors from 'cors';

try {
  process.loadEnvFile(); // lee backend/.env si existe (Node >= 21.7)
} catch {
  /* sin .env: valores por defecto */
}

const { getDb } = await import('./db/database.js');
const { isDatabaseEmpty, seedDatabase } = await import('./db/seed.js');
const { activeEngine, warmUpRunner } = await import('./services/code_validator.service.js');
const { articlesRouter } = await import('./routes/articles.routes.js');
const { challengesRouter } = await import('./routes/challenges.routes.js');
const { communityRouter } = await import('./routes/community.routes.js');
const { jobsRouter } = await import('./routes/jobs.routes.js');
const { userRouter } = await import('./routes/user.routes.js');
const { authRouter } = await import('./routes/auth.routes.js');
const { ensureDemoCredentials } = await import('./services/auth.service.js');
const { HttpError } = await import('./utils/http.js');

getDb();
if (isDatabaseEmpty()) {
  seedDatabase();
  console.log('✔ Base de datos vacía: datos semilla cargados');
}

ensureDemoCredentials(); // cuentas de prueba de los usuarios semilla (idempotente)

const app = express();
app.use(cors()); // indispensable para Flutter Web
app.use(express.json({ limit: '200kb' }));

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', codeRunner: activeEngine(), time: new Date().toISOString() });
});

app.use('/api/auth', authRouter);
app.use('/api/articles', articlesRouter);
app.use('/api/challenges', challengesRouter);
app.use('/api/community', communityRouter);
app.use('/api/jobs', jobsRouter);
app.use('/api/user', userRouter);

app.use('/api', (_req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  if (err instanceof HttpError) {
    res.status(err.status).json({ error: err.message });
    return;
  }
  if (err instanceof SyntaxError && 'body' in err) {
    res.status(400).json({ error: 'JSON inválido en el cuerpo de la petición.' });
    return;
  }
  console.error(err);
  res.status(500).json({ error: 'Error interno del servidor' });
});

const port = Number(process.env.PORT ?? 3000);
app.listen(port, () => {
  console.log(`🚀 API escuchando en http://localhost:${port}/api  (validador: ${activeEngine()})`);
  void warmUpRunner().catch((e) => console.warn('  No se pudo precalentar Dart:', e));
});
