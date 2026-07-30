// Format error standar sesuai docs/API_SPEC.md:
//   { "error": { "code": "...", "message": "..." } }

export function sendError(res, status, code, message) {
  return res.status(status).json({ error: { code, message } });
}

// Wrapper agar error di handler async tertangkap middleware error terpusat.
export function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}
