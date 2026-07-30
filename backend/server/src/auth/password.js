// Hashing password dengan bcrypt (bcryptjs, pure-JS). Lihat docs/SECURITY.md.
import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 12;

export function hashPassword(plain) {
  return bcrypt.hash(plain, SALT_ROUNDS);
}

export function verifyPassword(plain, hash) {
  return bcrypt.compare(plain, hash);
}
