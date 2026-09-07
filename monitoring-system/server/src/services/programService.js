import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { programDict } from '../utils/serialize.js';
import { parseHHMM } from '../utils/dates.js';

function toRow(data) {
  return {
    title: data.title,
    description: data.description ?? '',
    day: data.day ?? 'daily',
    start_time: parseHHMM(data.start_time),
    end_time: parseHHMM(data.end_time),
    location: data.location ?? null,
    is_active: data.is_active ?? true,
  };
}

export async function listPrograms(day, activeOnly = true) {
  const where = {};
  if (activeOnly) where.is_active = true;
  if (day) where.day = { in: [day, 'daily'] };
  const programs = await prisma.programs.findMany({ where, orderBy: { start_time: 'asc' } });
  return { programs: programs.map(programDict) };
}

export async function createProgram(data) {
  const program = await prisma.programs.create({ data: toRow(data) });
  return { status: 201, body: { message: 'Program created.', program: programDict(program) } };
}

export async function updateProgram(id, data) {
  const existing = await prisma.programs.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Resource not found.');
  const program = await prisma.programs.update({ where: { id }, data: toRow(data) });
  return { message: 'Program updated.', program: programDict(program) };
}

export async function deleteProgram(id) {
  const existing = await prisma.programs.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Resource not found.');
  await prisma.programs.delete({ where: { id } });
  return { message: 'Program deleted.' };
}
