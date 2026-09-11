import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';

let tableReady;

async function ensureTable() {
  if (!tableReady) {
    tableReady = prisma.$executeRawUnsafe(`
      CREATE TABLE IF NOT EXISTS advertisements (
        id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(150) NOT NULL,
        description VARCHAR(500) NOT NULL DEFAULT '',
        image_data LONGTEXT NOT NULL,
        link_url VARCHAR(500) NOT NULL DEFAULT '',
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_by INT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX advertisements_active_idx (is_active),
        CONSTRAINT advertisements_created_by_fk FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
      )
    `).catch((error) => {
      tableReady = undefined;
      throw error;
    });
  }
  await tableReady;
}

function serialize(row) {
  return {
    ...row,
    is_active: Boolean(row.is_active),
    created_at: row.created_at?.toISOString?.() ?? row.created_at,
    updated_at: row.updated_at?.toISOString?.() ?? row.updated_at,
  };
}

export async function listAdvertisements(activeOnly = true) {
  await ensureTable();
  const rows = activeOnly
    ? await prisma.$queryRawUnsafe('SELECT * FROM advertisements WHERE is_active = TRUE ORDER BY id DESC')
    : await prisma.$queryRawUnsafe('SELECT * FROM advertisements ORDER BY id DESC');
  return { advertisements: rows.map(serialize) };
}

export async function createAdvertisement(data, userId) {
  await ensureTable();
  await prisma.$executeRawUnsafe(
    'INSERT INTO advertisements (title, description, image_data, link_url, is_active, created_by) VALUES (?, ?, ?, ?, ?, ?)',
    data.title, data.description, data.image_data, data.link_url, data.is_active, userId,
  );
  const [{ id }] = await prisma.$queryRawUnsafe('SELECT LAST_INSERT_ID() AS id');
  const [row] = await prisma.$queryRawUnsafe('SELECT * FROM advertisements WHERE id = ?', Number(id));
  return { status: 201, body: { message: 'Advertisement created.', advertisement: serialize(row) } };
}

export async function updateAdvertisement(id, data) {
  await ensureTable();
  const existing = await prisma.$queryRawUnsafe('SELECT id FROM advertisements WHERE id = ?', id);
  if (!existing.length) throw new HttpError(404, 'Advertisement not found.');
  await prisma.$executeRawUnsafe(
    'UPDATE advertisements SET title = ?, description = ?, image_data = ?, link_url = ?, is_active = ? WHERE id = ?',
    data.title, data.description, data.image_data, data.link_url, data.is_active, id,
  );
  const [row] = await prisma.$queryRawUnsafe('SELECT * FROM advertisements WHERE id = ?', id);
  return { message: 'Advertisement updated.', advertisement: serialize(row) };
}

export async function deleteAdvertisement(id) {
  await ensureTable();
  const result = await prisma.$executeRawUnsafe('DELETE FROM advertisements WHERE id = ?', id);
  if (!result) throw new HttpError(404, 'Advertisement not found.');
  return { message: 'Advertisement deleted.' };
}
