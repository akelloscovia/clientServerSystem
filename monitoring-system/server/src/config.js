import 'dotenv/config';

/** Runtime configuration, mirrors the old app/config.py. */
export const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '5000', 10),
  corsOrigins: (process.env.CORS_ORIGINS || '*').split(',').map((s) => s.trim()),
  jwtSecret: process.env.JWT_SECRET || 'jwt-dev-secret',
  jwtAccessTtl: parseInt(process.env.JWT_ACCESS_TTL || '3600', 10),
  jwtRefreshTtl: parseInt(process.env.JWT_REFRESH_TTL || '2592000', 10),
};
