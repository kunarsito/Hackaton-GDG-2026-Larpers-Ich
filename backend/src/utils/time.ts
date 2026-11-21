/** Convierte un ISO timestamp en texto relativo ("Hace 2 horas"), que es lo que muestra el front. */
export function relativeTime(iso: string, now = Date.now()): string {
  const diff = Math.max(0, now - new Date(iso).getTime());
  const min = Math.floor(diff / 60_000);
  if (min < 1) return 'Ahora';
  if (min < 60) return `Hace ${min} ${min === 1 ? 'minuto' : 'minutos'}`;
  const h = Math.floor(min / 60);
  if (h < 24) return `Hace ${h} ${h === 1 ? 'hora' : 'horas'}`;
  const d = Math.floor(h / 24);
  if (d < 30) return `Hace ${d} ${d === 1 ? 'día' : 'días'}`;
  return new Date(iso).toLocaleDateString('es-MX');
}
