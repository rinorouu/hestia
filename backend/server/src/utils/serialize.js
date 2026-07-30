// Bentuk objek file untuk respons API (docs/API_SPEC.md).

// Ringkas — untuk list & hasil upload.
export function toPublicFile(row) {
  return {
    id: row.id,
    filename: row.filename,
    size_bytes: row.size_bytes,
    mime_type: row.mime_type,
    thumb_url: row.thumb_path ? `/api/files/${row.id}/thumb` : null,
    uploaded_at: row.uploaded_at,
  };
}

// Lengkap — untuk detail file.
export function toDetailedFile(row) {
  return {
    ...toPublicFile(row),
    rel_path: row.rel_path,
    checksum: row.checksum,
    taken_at: row.taken_at,
  };
}
