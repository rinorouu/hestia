// Validasi input sederhana untuk auth.

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MIN_PASSWORD = 8;

// Memvalidasi payload register/login. Mengembalikan { valid, message, value }.
export function validateCredentials({ email, password, requirePassword = true }) {
  if (typeof email !== 'string' || !EMAIL_RE.test(email.trim())) {
    return { valid: false, message: 'Email tidak valid.' };
  }
  if (requirePassword) {
    if (typeof password !== 'string' || password.length < MIN_PASSWORD) {
      return { valid: false, message: `Password minimal ${MIN_PASSWORD} karakter.` };
    }
  }
  return { valid: true, value: { email: email.trim().toLowerCase(), password } };
}
