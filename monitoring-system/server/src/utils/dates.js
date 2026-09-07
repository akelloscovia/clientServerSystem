// Formatting helpers that reproduce the exact string shapes the old Python
// `to_dict()` methods produced.

/** `2026-09-07T10:27:40` — naive-UTC ISO, no milliseconds, no trailing Z. */
export function isoNaiveUTC(value) {
  if (!value) return null;
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().slice(0, 19);
}

/** `08:00` from a Prisma TIME value (stored as an epoch-dated Date). */
export function hhmm(value) {
  if (!value) return null;
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().slice(11, 16);
}

/** `2026-09-07` from a Prisma DATE value. */
export function ymd(value) {
  if (!value) return null;
  const d = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().slice(0, 10);
}

/** Parse `"08:00"` / `"08:00:00"` into the epoch-dated Date a TIME column wants. */
export function parseHHMM(text) {
  const m = /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/.exec(String(text).trim());
  if (!m) return null;
  const [, h, min, s] = m;
  const hh = String(h).padStart(2, '0');
  return new Date(`1970-01-01T${hh}:${min}:${s || '00'}Z`);
}

/** Parse `"2026-09-07"` (or a full ISO string) into a UTC-midnight Date. */
export function parseDateOnly(text) {
  const s = String(text).trim();
  const datePart = s.slice(0, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(datePart)) return null;
  const d = new Date(`${datePart}T00:00:00Z`);
  return Number.isNaN(d.getTime()) ? null : d;
}

/** Start-of-day / end-of-day helpers for the `from` / `to` submission filters. */
export function parseIsoDate(text) {
  const d = new Date(String(text).trim());
  return Number.isNaN(d.getTime()) ? null : d;
}
