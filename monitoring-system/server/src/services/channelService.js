import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { channelDict } from '../utils/serialize.js';

function toRow(data) {
  return {
    name: data.name,
    stream_url: data.stream_url,
    logo_url: data.logo_url ?? '',
    stream_type: data.stream_type ?? 'hls',
    sort_order: data.sort_order ?? 0,
    is_active: data.is_active ?? true,
  };
}

export async function listChannels(activeOnly = true) {
  const where = activeOnly ? { is_active: true } : {};
  const channels = await prisma.channels.findMany({
    where,
    orderBy: [{ sort_order: 'asc' }, { id: 'asc' }],
  });
  return { channels: channels.map(channelDict) };
}

export async function createChannel(data) {
  const channel = await prisma.channels.create({ data: toRow(data) });
  return { status: 201, body: { message: 'Channel added.', channel: channelDict(channel) } };
}

export async function updateChannel(id, data) {
  const existing = await prisma.channels.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Resource not found.');
  const channel = await prisma.channels.update({ where: { id }, data: toRow(data) });
  return { message: 'Channel updated.', channel: channelDict(channel) };
}

export async function deleteChannel(id) {
  const existing = await prisma.channels.findUnique({ where: { id } });
  if (!existing) throw new HttpError(404, 'Resource not found.');
  await prisma.channels.delete({ where: { id } });
  return { message: 'Channel deleted.' };
}
