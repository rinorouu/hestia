import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/file_item.dart';
import '../../models/folder_item.dart';
import '../../services/file_service.dart';
import '../../widgets/file_grid_tile.dart';
import '../../widgets/loading_error_view.dart';
import 'file_detail_screen.dart';

/// Jelajahi folder & file milik user (`GET /files`). Root ditampilkan sebagai
/// tab pertama di HomeShell; subfolder di-push sebagai route baru sehingga
/// dapat kembali lewat tombol back bawaan Navigator.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key, this.path = '/'});

  final String path;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  static const _limit = 60;

  final _scrollController = ScrollController();
  final List<FolderItem> _folders = [];
  final List<FileItem> _files = [];
  int _page = 1;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom =
        _scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300;
    if (nearBottom && !_loading && !_loadingMore && _files.length < _total) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    final fileService = context.read<FileService>();
    final nextPage = reset ? 1 : _page + 1;
    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await fileService.browse(path: widget.path, page: nextPage, limit: _limit);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _folders
            ..clear()
            ..addAll(result.folders);
          _files.clear();
        }
        _files.addAll(result.files);
        _page = result.page;
        _total = result.total;
        _loading = false;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.message;
      });
    }
  }

  Future<void> _openFolder(FolderItem folder) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BrowseScreen(path: folder.path)),
    );
  }

  Future<void> _openFile(FileItem file) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => FileDetailScreen(file: file)),
    );
    if (changed == true) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.path == '/' ? 'Jelajah' : widget.path.split('/').where((s) => s.isNotEmpty).last;
    final fileService = context.watch<FileService>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: _buildBody(fileService),
      ),
    );
  }

  Widget _buildBody(FileService fileService) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: () => _load(reset: true));
    if (_folders.isEmpty && _files.isEmpty) {
      return const EmptyView(message: 'Folder ini masih kosong.', icon: Icons.folder_open_outlined);
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (_folders.isNotEmpty)
          SliverList.builder(
            itemCount: _folders.length,
            itemBuilder: (context, index) {
              final folder = _folders[index];
              return ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openFolder(folder),
              );
            },
          ),
        if (_files.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final file = _files[index];
                  return FileGridTile(
                    file: file,
                    thumbnailUrl: fileService.thumbnailUrl(file),
                    authHeaders: fileService.authHeaders,
                    onTap: () => _openFile(file),
                  );
                },
                childCount: _files.length,
              ),
            ),
          ),
        if (_loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
