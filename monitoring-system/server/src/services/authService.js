import bcrypt from 'bcryptjs';
import crypto from 'node:crypto';
import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { makeTokens } from '../utils/jwt.js';
import { userDict } from '../utils/serialize.js';
import { writeAudit } from './audit.js';

const ROLES = ['user', 'secretary', 'admin'];

export async function registerUser({ name, email, password }, ip) {
  const mail = email.toLowerCase();
  if (await prisma.users.findUnique({ where: { email: mail } })) {
    throw new HttpError(409, 'Email already registered.');
  }
  const user = await prisma.$transaction(async (tx) => {
    const u = await tx.users.create({
      data: { name, email: mail, password_hash: bcrypt.hashSync(password, 12) },
    });
    await writeAudit(tx, {
      userId: u.id, action: 'REGISTER', entityType: 'user', entityId: u.id,
      details: `New user: ${mail}`, ip,
    });
    return u;
  });
  return { status: 201, body: { message: 'Registration successful.', user: userDict(user), ...makeTokens(user) } };
}

export async function createStaffUser({ name, email, password, role }, actorId, ip) {
  if (!ROLES.includes(role)) {
    throw new HttpError(400, 'Invalid role. Must be user, secretary, or admin.');
  }
  const mail = email.toLowerCase();
  if (await prisma.users.findUnique({ where: { email: mail } })) {
    throw new HttpError(409, 'Email already registered.');
  }
  const user = await prisma.$transaction(async (tx) => {
    const u = await tx.users.create({
      data: { name, email: mail, password_hash: bcrypt.hashSync(password, 12), role },
    });
    await writeAudit(tx, {
      userId: actorId, action: 'CREATE_STAFF', entityType: 'user', entityId: u.id,
      details: `${mail} as ${role}`, ip,
    });
    return u;
  });
  return { status: 201, body: { message: `Account created for ${mail}.`, user: userDict(user) } };
}

export async function loginUser({ email, password }, ip) {
  const user = await prisma.users.findUnique({ where: { email: email.toLowerCase() } });
  if (!user || !bcrypt.compareSync(password, user.password_hash)) {
    throw new HttpError(401, 'Invalid email or password.');
  }
  if (!user.is_active) {
    throw new HttpError(403, 'Account is disabled. Contact administrator.');
  }
  await writeAudit(prisma, { userId: user.id, action: 'LOGIN', entityType: 'user', entityId: user.id, ip });
  return { status: 200, body: { message: 'Login successful.', user: userDict(user), ...makeTokens(user) } };
}

export async function userPortalAccess({ email, name }) {
  const mail = (email || '').trim().toLowerCase();
  const nm = (name || '').trim();
  if (!mail) throw new HttpError(400, 'Email is required');

  let user = await prisma.users.findUnique({ where: { email: mail } });
  if (!user) {
    user = await prisma.users.create({
      data: {
        name: nm || mail.split('@')[0],
        email: mail,
        password_hash: bcrypt.hashSync(crypto.randomBytes(24).toString('base64url'), 12),
      },
    });
  }
  if (!user.is_active) throw new HttpError(403, 'Account is disabled');

  const tokens = makeTokens(user);
  return {
    status: 200,
    body: {
      token: tokens.access_token,
      email: user.email,
      user_id: user.id,
      user: userDict(user),
      ...tokens,
    },
  };
}
