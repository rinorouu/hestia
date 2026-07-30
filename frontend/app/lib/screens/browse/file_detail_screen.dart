import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../core/api_exception.dart';
import '../../models/file_item.dart';
import '../../services/file_service.dart';
import '../../utils/formatters.dart';

/// Detail + preview satu file, dengan aksi download & hapus.
/// Pop dengan hasil `true` bila file dihapus, supaya BrowseScreen tahu harus refresh.
class FileDetailScreen extends StatefulWidget {
  const FileDetailScreen({super.key, required this.file});

  final FileItem file;

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  late FileItem _file = widget.file;
  bool _loadingDetail = true;
  VideoPlayerController? _videoController;
  bool _deleting = false;
  bool _downloading = false;
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    if (widget.file.isVideo) _initVideo();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await context.read<FileService>().detail(widget.file.id);
      if (!mounted) return;
      setState(() {
        _file = detail;
        _loadingDetail = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDetail = false);
    }
  }

  void _initVideo() {
    final fileService = context.read<FileService>();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(fileService.downloadUrl(widget.file.id)),
      httpHeaders: fileService.authHeaders,
    );
    controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
    _videoController = controller;
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    final fileService = context.read<FileService>();
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      final file = await fileService.download(
        _file,
        onProgress: (sent, total) {
          if (total > 0 && mounted) setState(() => _downloadProgress = sent / total);
        },
      );
      if (!mounted) return;
      setState(() => _downloading = false);
      await _offerOpenOrShare(file);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      _showError(e.message);
    }
  }

  Future<void> _offerOpenOrShare(File file) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Buka'),
              onTap: () {
                Navigator.pop(sheetContext);
                OpenFilex.open(file.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Bagikan / simpan ke perangkat'),
              onTap: () {
                Navigator.pop(sheetContext);
                Share.shareXFiles([XFile(file.path)]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus file?'),
        content: Text('"${_file.filename}" akan dihapus permanen dari HDD.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await context.read<FileService>().deleteFile(_file.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _showError(e.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final fileService = context.read<FileService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_file.filename, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: _downloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            onPressed: _downloading ? null : _download,
          ),
          IconButton(
            icon: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            onPressed: _deleting ? null : _delete,
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(color: Colors.black, child: _buildPreview(fileService)),
          ),
          if (_downloading && _downloadProgress != null) LinearProgressIndicator(value: _downloadProgress),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Ukuran', formatBytes(_file.sizeBytes)),
                _infoRow('Tipe', _file.mimeType),
                _infoRow('Diunggah', formatDateTime(_file.uploadedAt)),
                if (_file.takenAt != null) _infoRow('Tanggal foto', formatDateTime(_file.takenAt!)),
                if (_loadingDetail)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(FileService fileService) {
    if (_file.isVideo) {
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: controller.value.aspectRatio, child: VideoPlayer(controller)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(controller, allowScrubbing: true),
          ),
          IconButton(
            iconSize: 56,
            color: Colors.white,
            icon: Icon(controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
            onPressed: () => setState(() {
              controller.value.isPlaying ? controller.pause() : controller.play();
            }),
          ),
        ],
      );
    }

    return CachedNetworkImage(
      imageUrl: fileService.downloadUrl(_file.id),
      httpHeaders: fileService.authHeaders,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
