import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/file_item.dart';

/// Tile thumbnail untuk grid Browse. Gambar diambil lewat `GET /files/:id/thumb`
/// yang butuh auth, jadi header Authorization disisipkan manual ke CachedNetworkImage.
class FileGridTile extends StatelessWidget {
  const FileGridTile({
    super.key,
    required this.file,
    required this.thumbnailUrl,
    required this.authHeaders,
    required this.onTap,
  });

  final FileItem file;
  final String? thumbnailUrl;
  final Map<String, String> authHeaders;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
            if (thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: thumbnailUrl!,
                httpHeaders: authHeaders,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => _FallbackIcon(file: file),
              )
            else
              _FallbackIcon(file: file),
            if (file.isVideo)
              const Positioned(
                right: 6,
                bottom: 6,
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.file});

  final FileItem file;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        file.isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        size: 32,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
