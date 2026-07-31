import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../services/file_service.dart';
import '../../services/storage_status_service.dart';
import '../../utils/formatters.dart';

/// Upload satu atau banyak foto/video sekaligus ke folder tujuan opsional.
/// Progress yang ditampilkan bersifat agregat (satu request multipart untuk
/// seluruh batch), bukan per-file — lihat catatan di FileService.upload.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final List<PickedMedia> _selected = [];
  final _folderController = TextEditingController();
  bool _uploading = false;
  double? _progress;
  UploadOutcome? _result;
  String? _error;

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    // Buka Galeri / Photo Picker sistem (bukan file manager) — pilih banyak
    // foto & video sekaligus.
    final picked = await ImagePicker().pickMultipleMedia();
    if (picked.isEmpty) return;
    final media = [
      for (final x in picked) PickedMedia(path: x.path, name: x.name, size: await x.length()),
    ];
    if (!mounted) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(media);
      _result = null;
      _error = null;
    });
  }

  void _removeAt(int index) {
    setState(() => _selected.removeAt(index));
  }

  Future<void> _upload() async {
    if (_selected.isEmpty) return;
    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
      _result = null;
    });

    final fileService = context.read<FileService>();
    final path = _folderController.text.trim();
    try {
      final outcome = await fileService.upload(
        files: _selected,
        path: path.isEmpty ? null : path,
        onProgress: (sent, total) {
          if (total > 0 && mounted) setState(() => _progress = sent / total);
        },
      );
      if (!mounted) return;
      setState(() {
        _result = outcome;
        _uploading = false;
        _selected.clear();
      });
      if (mounted) context.read<StorageStatusService>().refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageAvailable = context.watch<StorageStatusService>().isAvailable;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!storageAvailable)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Media penyimpanan server tidak tersedia. Upload dinonaktifkan sementara.'),
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _folderController,
            decoration: const InputDecoration(
              labelText: 'Subfolder tujuan (opsional)',
              hintText: 'mis. 2026/Liburan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: storageAvailable && !_uploading ? _pickFiles : null,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Pilih dari galeri'),
          ),
          const SizedBox(height: 12),
          for (final entry in _selected.asMap().entries)
            ListTile(
              dense: true,
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(entry.value.name, overflow: TextOverflow.ellipsis),
              subtitle: Text(formatBytes(entry.value.size)),
              trailing: _uploading
                  ? null
                  : IconButton(icon: const Icon(Icons.close), onPressed: () => _removeAt(entry.key)),
            ),
          const SizedBox(height: 12),
          if (_uploading) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            const Text('Mengunggah...'),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (storageAvailable && !_uploading && _selected.isNotEmpty) ? _upload : null,
            child: const Text('Upload'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Text('Berhasil: ${_result!.uploaded.length}, Gagal: ${_result!.failed.length}'),
            for (final f in _result!.failed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '- ${f.filename}: ${f.reason}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
